import SwiftUI

struct MilleBornesHeader: View {
    @EnvironmentObject var game: MilleBornesGame

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            MilleBornesTeamHeaderView(label: game.team1Label,
                                     score: game.cumulativeScore(team: 1),
                                     isWinner: game.winningTeam == 1)
            MilleBornesTeamHeaderView(label: game.team2Label,
                                     score: game.cumulativeScore(team: 2),
                                     isWinner: game.winningTeam == 2)
        }
    }
}

struct MilleBornesTeamHeaderView: View {
    var label: String
    var score: Int
    var isWinner: Bool

    var body: some View {
        VStack(alignment: .center) {
            HStack {
                VStack(alignment: .trailing) {
                    HStack {
                        Spacer()
                        Text(label)
                            .font(.title2)
                            .fontWeight(.heavy)
                            .allowsTightening(true)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    HStack {
                        Spacer()
                        Text(score.formatted(.number.grouping(.never)))
                            .font(.title3)
                            .fontDesign(.monospaced)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(alignment: .leading) {
                    if isWinner {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.orange)
                            Text("Winner")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct MilleBornesHeader_Previews: PreviewProvider {
    static var winnerGame: MilleBornesGame {
        let g = MilleBornesGame.mock
        var h = MilleBornesHand()
        h.team1.cards100 = 8; h.team1.cards200 = 1  // 1000 miles → tripCompleted auto
        h.team1.rightOfWay    = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team1.punctureProof = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team1.drivingAce.played = true
        h.team1.extraTank.played  = true  // allFourSafeties auto
        g.hands.append(h)
        return g
    }

    static var previews: some View {
        VStack {
            MilleBornesHeader()
                .environmentObject(MilleBornesGame.mock)
                .previewDisplayName("In Progress")
            Divider()
            MilleBornesHeader()
                .environmentObject(winnerGame)
                .previewDisplayName("Winner")
        }
    }
}
