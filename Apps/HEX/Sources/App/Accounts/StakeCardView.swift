// StakeCardView.swift
// Copyright (c) 2021 Joe Blau

import BigInt
import ComposableArchitecture
import HEXREST
import SwiftUI
import SwiftUIVisualEffects

struct StakeCardView: View {
    let price: Double
    let accountData: AccountData

    private let MAGNETIC_STRIPE_HEIGHT = CGFloat(32)
    private let MAGNETIC_STRIPE_PADDING = CGFloat(24)
    @State private var cardRotation = 0.0
    @State private var showBack = false

    var body: some View {
        ZStack {
            switch showBack {
            case true: back
            case false: front
            }
        }
        .onTapGesture {
            flipCard()
        }
        .rotation3DEffect(.degrees(cardRotation), axis: (x: 0, y: 1, z: 0))
    }

    var front: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: accountData.account.chain.gradient),
                                     startPoint: .bottomLeading,
                                     endPoint: .topTrailing))
                .blurEffect()
                .blurEffectStyle(.systemMaterial)
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    frontTotal(title: "Daily Payout",
                               hearts: accountData.total.interestSevenDayHearts,
                               alignment: .leading)
                    Spacer()
                    front(address: accountData.account.address)
                }
                Spacer()
                HStack(alignment: .bottom) {
                    frontTotal(title: "Total Balance",
                               hearts: accountData.total.balanceHearts,
                               alignment: .leading)
                    Spacer()
                    frontTotal(title: "Total Shares",
                               shares: accountData.total.stakeShares,
                               alignment: .trailing)
                }
            }
            .font(.body.monospacedDigit())
            .padding()
        }
        .frame(maxWidth: .infinity, idealHeight: (UIScreen.main.bounds.width) / 1.586)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    var back: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: accountData.account.chain.gradient),
                                     startPoint: .bottomLeading,
                                     endPoint: .topTrailing))
                .blurEffect()
                .blurEffectStyle(.systemMaterial)
            Rectangle()
                .foregroundColor(.black)
                .frame(height: MAGNETIC_STRIPE_HEIGHT)
                .offset(y: MAGNETIC_STRIPE_PADDING)

            VStack(alignment: .leading) {
                DataHeaderView()
                DataRowHexView(title: "ʟɪᴏ̨ᴜɪᴅ", units: accountData.balanceHearts, price: price)
                DataRowHexView(title: "sᴛᴀᴋᴇᴅ", units: accountData.total.stakedHearts, price: price)
                DataRowHexView(title: "ɪɴᴛᴇʀᴇsᴛ", units: accountData.total.interestHearts, price: price)

                if !accountData.total.bigPayDayHearts.isZero {
                    DataRowHexView(title: "ʙɪɢ ᴘᴀʏ ᴅᴀʏ", units: accountData.total.bigPayDayHearts, price: price)
                }

                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Spacer()
                        Text(accountData.account.name)
                        description(text: accountData.account.chain.description)
                    }
                    Spacer()
                    Image(accountData.account.chain.description).resizable()
                        .scaledToFit()
                        .frame(height: 32)
                        .vibrancyEffect()
                        .vibrancyEffectStyle(.fill)
                }
            }
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            .padding(.top, MAGNETIC_STRIPE_HEIGHT + MAGNETIC_STRIPE_PADDING / 2)
            .padding()
        }
        .frame(maxWidth: .infinity, idealHeight: (UIScreen.main.bounds.width) / 1.586)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    func frontTotal(title: String, hearts: BigUInt, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment) {
            Text(hearts.hexAt(price: price).currencyString)
            description(text: title)
        }
    }

    func frontTotal(title: String, shares: BigUInt, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment) {
            Text(shares.number.shareString).foregroundColor(.primary)
            description(text: title)
        }
    }

    func front(address: String) -> some View {
        Text("\(address.prefix(6).description)...\(address.suffix(4).description)")
            .font(.subheadline.monospaced())
            .padding(8)
            .background(Color(.displayP3, white: 1.0, opacity: 0.2))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    func description(text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .vibrancyEffect()
            .vibrancyEffectStyle(.fill)
    }

    func flipCard() {
        let duration = 0.3
        withAnimation(.easeInOut(duration: duration)) {
            cardRotation += 180
        }
        withAnimation(.easeInOut(duration: 0.001).delay(duration / 2)) {
            showBack.toggle()
        }
    }
}

#if DEBUG
//    struct StakeCardView_Previews: PreviewProvider {
//        static var previews: some View {
//            ForEach(ColorScheme.allCases, id: \.self) {
//                StakeCardView(account: Account(name: "Test", address: "0x1234567890", chain: .ethereum))
//                    .previewLayout(PreviewLayout.sizeThatFits)
//                    .padding()
//                    .preferredColorScheme($0)
//            }
//        }
//    }
#endif
