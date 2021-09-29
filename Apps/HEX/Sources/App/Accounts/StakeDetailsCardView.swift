// StakeDetailsCardView.swift
// Copyright (c) 2021 Joe Blau

import HEXREST
import SwiftUI

struct StakeDetailsCardView: View {
    let hexPrice: HEXPrice
    let stake: Stake
    let account: Account

    var body: some View {
        GroupBox {
            HStack {
                ZStack {
                    PercentageRingView(
                        ringWidth: 8, percent: stake.percentComplete * 100,
                        backgroundColor: account.chain.gradient.first?.opacity(0.15) ?? .clear,
                        foregroundColors: [account.chain.gradient.first ?? .clear, account.chain.gradient.last ?? .clear]
                    )
                    .frame(width: 56, height: 56)
                    Text(NSNumber(value: stake.percentComplete).percentageString)
                        .font(.caption.monospacedDigit())
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(stake.stakedHearts
                        .hexAt(price: hexPrice.hexUsd)
                        .currencyStringSuffix).foregroundColor(.primary)
                    Text(stake.stakedHearts.hex.hexString).foregroundColor(.secondary)
                }
            }
            .font(.body.monospacedDigit())
        } label: {
            Label("Staked \(stake.stakedDays) Days", systemImage: "calendar")
            EmptyView()
        }
        .padding([.horizontal], 20)
        .padding([.vertical], 10)
        .groupBoxStyle(StakeGroupBoxStyle(color: .primary, destination: StakeDetailsView(hexPrice: hexPrice,
                                                                                         stake: stake,
                                                                                         account: account)))
    }
}

// struct StakeDetailsCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        StakeDetailsCardView()
//    }
// }
