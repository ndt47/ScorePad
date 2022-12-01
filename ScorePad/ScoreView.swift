//
//  ScoreView.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/30/22.
//

import SwiftUI

extension Score: View {
    var body: some View {
        HStack {
            Text("\(value.formatted(.number.grouping(.never)))")
                .frame(minWidth: 40, alignment: .trailing)
                .fontDesign(.monospaced)
                .bold()
            Spacer()
            if let contract = contract {
                HStack {
                    Text("\(contract.level)")
                    contract.suit
                        .padding(EdgeInsets(top: 0, leading: -6, bottom: 0, trailing: -2))
                    Text("\(contract.result.formatted(.number.sign(strategy: .always())))")
                        .foregroundColor(.gray)
                        .fontDesign(.monospaced)
                }
            } else if case .rubber = self {
                Text("RUBBER")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, minHeight: 24)
    }
}

extension Suit: View {
    var body: some View {
        switch self {
        case .clubs:
            return Image(systemName: "suit.club.fill")
                .resizable()
                .frame(width: 12, height: 12, alignment: .center)
                .foregroundColor(.black)
                .eraseToAnyView()
        case .diamonds:
            return Image(systemName: "suit.diamond.fill")
                .resizable()
                .frame(width: 12, height: 12, alignment: .center)
                .foregroundColor(.red)
                .eraseToAnyView()
        case .hearts:
            return Image(systemName: "suit.heart.fill")
                .resizable()
                .frame(width: 12, height: 12, alignment: .center)
                .foregroundColor(.red)
                .eraseToAnyView()
        case .spades:
            return Image(systemName: "suit.spade.fill")
                .resizable()
                .frame(width: 12, height: 12, alignment: .center)
                .foregroundColor(.black)
                .eraseToAnyView()
        case .notrump:
            return Text("NT")
                .foregroundColor(.black)
                .fontDesign(.rounded)
                .font(.caption)
                .bold()
                .eraseToAnyView()
        }
    }
}

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

struct Score_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Score.bid(40, Contract(level: 2, suit: .clubs, declarer: .west, doubled: false, redoubled: false, tricksTaken: 10))
            Score.bid(120, Contract(level: 4, suit: .hearts, declarer: .east, doubled: false, redoubled: false, tricksTaken: 10))
            Score.under(100, Contract(level: 4, suit: .spades, declarer: .east, doubled: false, redoubled: false, tricksTaken: 8))
            Score.over(20, Contract(level: 3, suit: .diamonds, declarer: .east, doubled: false, redoubled: false, tricksTaken: 10))
            Score.bid(100, Contract(level: 3, suit: .notrump, declarer: .east, doubled: false, redoubled: false, tricksTaken: 9))
            Score.slam(500, Contract(level: 6, suit: .notrump, declarer: .east, doubled: false, redoubled: false, tricksTaken: 12))
            Score.honors(100, .we, Contract(level: 6, suit: .notrump, declarer: .east, doubled: false, redoubled: false, tricksTaken: 12))
            Score.rubber(750, .we)
            Score.under(1500, Contract(level: 4, suit: .hearts, declarer: .south, doubled: true, redoubled: false, tricksTaken: 6))

        }
    }
}
