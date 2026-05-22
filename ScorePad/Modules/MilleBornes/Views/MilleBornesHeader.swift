import SwiftUI

struct MilleBornesHeader: View {
    @EnvironmentObject var game: MilleBornesGame

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            MilleBornesTeamHeaderView(players: game.team1Players,
                                     fallback: "Team 1",
                                     score: game.cumulativeScore(team: 1),
                                     isWinner: game.winningTeam == 1)
            MilleBornesTeamHeaderView(players: game.team2Players,
                                     fallback: "Team 2",
                                     score: game.cumulativeScore(team: 2),
                                     isWinner: game.winningTeam == 2)
        }
    }
}

struct MilleBornesTeamHeaderView: View {
    var players: [String]
    var fallback: String
    var score: Int
    var isWinner: Bool

    private var displayNames: [String] { players.isEmpty ? [fallback] : players }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(displayNames, id: \.self) { name in
                    Text(name)
                        .font(.title3)
                        .fontWeight(.heavy)
                        .allowsTightening(true)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(score.formatted(.number.grouping(.never)))
                    .font(.title3)
                    .fontDesign(.monospaced)
                    .foregroundColor(.gray)
                if isWinner {
                    WinnerBadge()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
    }
}

struct MilleBornesHeader_Previews: PreviewProvider {
    static var winnerGame: MilleBornesGame {
        let g = MilleBornesGame.mock
        var h = MilleBornesHand()
        h.team1.cards100 = 8; h.team1.cards200 = 1  // 1000 miles → tripCompleted auto
        h.team1.rightOfWay    = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team1.punctureProof = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team1.drivingAce = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team1.extraTank = MilleBornesSafetyState(played: true, coupFourre: true)  // allFourSafeties auto
        g.hands.append(h)
        return g
    }

    static var previews: some View {
        VStack {
            MilleBornesHeader()
                .environmentObject(MilleBornesGame.mock)
                .previewDisplayName("In Progress (4-player)")
            Divider()
            MilleBornesHeader()
                .environmentObject(winnerGame)
                .previewDisplayName("Winner (4-player)")
        }
    }
}
