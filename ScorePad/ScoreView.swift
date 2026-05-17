//
//  ScoreView.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/30/22.
//

import SwiftUI

extension Score: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            if let contract = self.contract {
                ContractView(contract: contract)
                    .fixedSize()
            }
            Spacer()
                .allowsHitTesting(true)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text("0000")
                .fontDesign(.monospaced)
                .bold()
                .hidden()
                .overlay(alignment: .trailing) {
                    Text("\(value.formatted(.number.grouping(.never)))")
                        .fontDesign(.monospaced)
                        .bold()
                }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, minHeight: 18)
    }
}

struct ContractView: View {
    @EnvironmentObject var rubber: Rubber
    var contract: Contract
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            BidView(.bid(Bid(contract.level, contract.suit)))
            Result(contract.result)
        }
    }
}

extension Suit: View {
    var body: some View {
        switch self {
        case .clubs:
            return Image(systemName: "suit.club.fill")
                .font(.caption)
                .foregroundColor(.primary)
                .eraseToAnyView()
        case .diamonds:
            return Image(systemName: "suit.diamond.fill")
                .font(.caption)
                .foregroundColor(.red)
                .eraseToAnyView()
        case .hearts:
            return Image(systemName: "suit.heart.fill")
                .font(.caption)
                .foregroundColor(.red)
                .eraseToAnyView()
        case .spades:
            return Image(systemName: "suit.spade.fill")
                .font(.caption)
                .foregroundColor(.primary)
                .eraseToAnyView()
        case .notrump:
            return Text("NT")
                .foregroundColor(.primary)
                .fontDesign(.rounded)
                .font(.caption)
                .fontWeight(.bold)
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
            // Bid: small (2♣), game (4♥), max (7NT redoubled = 880)
            Score.bid(40,  Contract(level: 2, suit: .clubs,   declarer: .west,  tricksTaken: 8))
            Score.bid(120, Contract(level: 4, suit: .hearts,  declarer: .east,  tricksTaken: 10))
            Score.bid(880, Contract(level: 7, suit: .notrump, declarer: .north, tricksTaken: 13))

            // Overtricks: simple (♦ +1 = 20), doubled vul (+3 = 600), max (1♣ rdbl vul +6 = 2400)
            Score.over(20,   Contract(level: 3, suit: .diamonds, declarer: .east,  tricksTaken: 10))
            Score.over(600,  Contract(level: 2, suit: .hearts,   declarer: .south, tricksTaken: 11, vulnerable: true))
            Score.over(2400, Contract(level: 1, suit: .clubs,    declarer: .north, tricksTaken: 13, vulnerable: true))

            // Insult: doubled (50), redoubled (100)
            Score.insult(50,  Contract(level: 4, suit: .spades, declarer: .south, tricksTaken: 10))
            Score.insult(100, Contract(level: 4, suit: .hearts, declarer: .south, tricksTaken: 10))

            // Undertricks: undoubled (-1 = 50), doubled vul (-3 = 800), max (rdbl vul -13 = 7600)
            Score.under(50,   Contract(level: 4, suit: .spades,  declarer: .east, tricksTaken: 9))
            Score.under(800,  Contract(level: 4, suit: .hearts,  declarer: .south, tricksTaken: 7, vulnerable: true))
            Score.under(7600, Contract(level: 7, suit: .notrump, declarer: .east,  tricksTaken: 0, vulnerable: true))

            // Slam: small non-vul (500), small vul (750), grand non-vul (1000), grand vul (1500)
            Score.slam(500,  Contract(level: 6, suit: .notrump, declarer: .east,  tricksTaken: 12))
            Score.slam(750,  Contract(level: 6, suit: .spades,  declarer: .north, tricksTaken: 12, vulnerable: true))
            Score.slam(1000, Contract(level: 7, suit: .hearts,  declarer: .south, tricksTaken: 13))
            Score.slam(1500, Contract(level: 7, suit: .notrump, declarer: .west,  tricksTaken: 13, vulnerable: true))

            // Honors: 4 honors (100), all 5 (150)
            Score.honors(100, .we,   Contract(level: 4, suit: .spades, declarer: .north, tricksTaken: 10))
            Score.honors(150, .they, Contract(level: 6, suit: .hearts, declarer: .south, tricksTaken: 12))

            // Rubber: 3-game (500), 2-game (700)
            Score.rubber(500, .we)
            Score.rubber(700, .they)
        }
    }
}
