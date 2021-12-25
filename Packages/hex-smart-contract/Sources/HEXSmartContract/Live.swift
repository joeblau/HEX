// Live.swift
// Copyright (c) 2021 Joe Blau

import BigInt
import Combine
import ComposableArchitecture
import EVMChain
import Foundation
import IdentifiedCollections
import UIKit
import web3

public extension HEXSmartContractManager {
    static let live: HEXSmartContractManager = { () -> HEXSmartContractManager in
        var manager = HEXSmartContractManager()

        manager.create = { id in
            Effect.run { subscriber in
                let delegate = HEXSmartContractManagerDelegate(subscriber)

                let clients = Chain.allCases.reduce(into: [Chain: EthereumClient]()) { dict, chain in
                    dict[chain.id] = EthereumClient(url: chain.url)
                }

                dependencies[id] = Dependencies(delegate: delegate,
                                                clients: clients,
                                                subscriber: subscriber)
                return AnyCancellable {
                    dependencies[id] = nil
                }
            }
        }

        manager.destroy = { id in
            .fireAndForget {
                dependencies[id]?.subscriber.send(completion: .finished)
                dependencies[id] = nil
            }
        }

        manager.getStakes = { id, address, chain in
            let accountDataKey = address + chain.description

            dependencies[id]?.stakesCache[accountDataKey] = IdentifiedArrayOf<StakeLists_Parameter.Response>()
            return manager.getStakeCount(id: id, address: EthereumAddress(address), chain: chain).receive(on: DispatchQueue.main).eraseToEffect()
        }

        manager.getStakeCount = { id, address, chain in
            guard let client = dependencies[id]?.clients[chain] else { return .none }

            return .fireAndForget {
                let stakes = StakeCount_Parameter(stakeAddress: address)
                stakes.call(withClient: client,
                            responseType: StakeCount_Parameter.Response.self) { error, response in
                    switch error {
                    case let .some(err):
                        print(err)
                    case .none:
                        switch response?.stakeCount {
                        case let .some(count):
                            DispatchQueue.main.async {
                                manager.getStakeList(id, address, chain, count)
                            }
                        case .none:
                            print("no stakes")
                        }
                    }
                }
            }
        }

        manager.getStakeList = { id, address, chain, stakeCount in
            guard let client = dependencies[id]?.clients[chain] else { return }

            (0 ..< stakeCount).forEach { stakeIndex in
                let getStake = StakeLists_Parameter(stakeAddress: address,
                                                    stakeIndex: stakeIndex)
                getStake.call(withClient: client,
                              responseType: StakeLists_Parameter.Response.self) { error, response in
                    switch error {
                    case let .some(error):
                        print(error)
                    case .none:
                        switch response {
                        case let .some(stake):
                            DispatchQueue.main.async {
                                manager.updateStakeCache(id, address, chain, stake, stakeCount)
                            }
                        case .none:
                            print("no stake")
                        }
                    }
                }
            }
        }

        manager.updateStakeCache = { id, address, chain, stake, stakeCount in
            let accountDataKey = address.value + chain.description

            dependencies[id]?.stakesCache[accountDataKey]?.updateOrAppend(stake)
            switch dependencies[id]?.stakesCache[accountDataKey] {
            case let .some(stakes) where stakes.count == Int(stakeCount):
                DispatchQueue.main.async {
                    dependencies[id]?.subscriber.send(Action.stakeList(Array(stakes), address, chain))
                }
            default:
                return
            }
        }

        manager.getDailyDataRange = { id, chain, begin, end in
            guard let client = dependencies[id]?.clients[chain] else { return .none }

            return .fireAndForget {
                let dailyDataRange = DailyDataRange_Parameter(beginDay: BigUInt(begin), endDay: BigUInt(end))
                dailyDataRange.call(withClient: client,
                                    responseType: DailyDataRange_Parameter.Response.self) { error, response in
                    switch error {
                    case let .some(err):
                        print(err)
                    case .none:
                        switch response?.list {
                        case let .some(list):
                            DispatchQueue.main.async {
                                dependencies[id]?.subscriber.send(.dailyData(list, chain))
                            }
                        case .none:
                            print("no stakes")
                        }
                    }
                }
            }
        }

        manager.getCurrentDay = { id, chain in
            guard let client = dependencies[id]?.clients[chain] else { return .none }

            return .fireAndForget {
                let currentDay = CurrentDay()
                currentDay.call(withClient: client,
                                responseType: CurrentDay.Response.self) { error, response in
                    switch error {
                    case let .some(err):
                        print(err)
                    case .none:
                        switch response?.day {
                        case let .some(day):
                            DispatchQueue.main.async {
                                dependencies[id]?.subscriber.send(.currentDay(day, chain))
                            }
                        case .none:
                            print("no stakes")
                        }
                    }
                }
            }
        }

        manager.getGlobalInfo = { id, chain in
            guard let client = dependencies[id]?.clients[chain] else { return .none }

            return .fireAndForget {
                let globalInfo = GlobalInfo()
                globalInfo.call(withClient: client,
                                responseType: GlobalInfo.Response.self) { error, response in
                    switch error {
                    case let .some(error):
                        print(error)
                    case .none:
                        switch response {
                        case let .some(globalInfo):
                            DispatchQueue.main.async {
                                dependencies[id]?.subscriber.send(.globalInfo(globalInfo, chain))
                            }
                        case .none:
                            print("no global info")
                        }
                    }
                }
            }
        }

        manager.getBalance = { id, address, chain in
            guard let client = dependencies[id]?.clients[chain] else { return .none }
            let ethereumAddress = EthereumAddress(address)
            return .fireAndForget {
                let erc20 = ERC20(client: client)
                erc20.balanceOf(tokenContract: EthereumAddress("0x2b591e99afe9f32eaa6214f7b7629768c40eeb39"),
                                address: ethereumAddress) { error, balance in
                    switch error {
                    case let .some(error):
                        print(error)
                    case .none:
                        switch balance {
                        case let .some(balance):
                            DispatchQueue.main.async {
                                dependencies[id]?.subscriber.send(.balance(balance, ethereumAddress, chain))
                            }
                        case .none:
                            print("no balance")
                        }
                    }
                }
            }
        }
        return manager
    }()
}

// MARK: - Dependencies

private struct Dependencies {
    let delegate: HEXSmartContractManagerDelegate
    let clients: [Chain: EthereumClient]
    let subscriber: Effect<HEXSmartContractManager.Action, Never>.Subscriber
    var stakesCache = [String: IdentifiedArrayOf<StakeLists_Parameter.Response>]()
}

private var dependencies: [AnyHashable: Dependencies] = [:]

// MARK: - Delegate

private class HEXSmartContractManagerDelegate: NSObject {
    let subscriber: Effect<HEXSmartContractManager.Action, Never>.Subscriber

    init(_ subscriber: Effect<HEXSmartContractManager.Action, Never>.Subscriber) {
        self.subscriber = subscriber
    }
}
