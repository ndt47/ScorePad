import SwiftUI

struct MilleBornesListCell: View {
    @State var game: MilleBornesGame
    @Environment(\.selected) var selected

    init(game: MilleBornesGame) {
        self.game = game
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(game.team1Label)
                        if game.winningTeam == 1 { WinnerBadge(showLabel: false) }
                    }
                    HStack(spacing: 4) {
                        Text(game.team2Label)
                        if game.winningTeam == 2 { WinnerBadge(showLabel: false) }
                    }
                }
                .fontWeight(.light)
                .font(.subheadline)
                .lineLimit(1)
                .allowsTightening(true)

                Spacer()

                VStack(alignment: .trailing) {
                    Text(game.cumulativeScore(team: 1).formatted(.number.grouping(.never)))
                    Text(game.cumulativeScore(team: 2).formatted(.number.grouping(.never)))
                }
                .fontDesign(.monospaced)
            }

            HStack(alignment: .firstTextBaseline) {
                Text("Last played").bold()
                Text(game.lastModified.formatted(date: .abbreviated, time: .shortened))
            }
            .font(.caption)
            .foregroundColor(selected ? .white : .gray)
        }
    }
}

struct MilleBornesListCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            MilleBornesListCell(game: .mock)
                .padding()
            Divider()
            MilleBornesListCell(game: .mock)
                .selected(true)
                .padding()
                .background(Color.accentColor)
        }
    }
}
