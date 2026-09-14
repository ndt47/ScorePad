import SwiftUI

struct Phase10ListCell: View {
    @State var game: Phase10Game
    @Environment(\.selected) var selected

    init(game: Phase10Game) {
        self.game = game
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(game.players.map(\.cachedName).joined(separator: ", "))
                    .fontWeight(.light)
                    .font(.subheadline)
                    .lineLimit(1)
                    .allowsTightening(true)
                Spacer()
            }

            // Up to 4 players shown; excess collapsed to "+N more"
            let displayed = game.players.prefix(4)
            VStack(alignment: .leading, spacing: 3) {
                ForEach(displayed.indices, id: \.self) { i in
                    HStack(spacing: 6) {
                        PlayerMarker(color: Phase10Game.playerColor(for: i), isWinner: game.winnerIndex == i)
                        Text(game.players[i].cachedName)
                            .font(.caption).fontWeight(.medium)
                            .lineLimit(1)
                        let phase = game.currentPhase(for: i)
                        Text("Ph \(phase)")
                            .font(.caption2).fontWeight(.semibold)
                            .foregroundColor(Phase10Game.playerColor(for: i))
                        Spacer()
                        Text(game.cumulativeScore(for: i).formatted(.number.grouping(.never)))
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .foregroundColor(selected ? .white : .secondary)
                    }
                }
                if game.players.count > 4 {
                    Text("+\(game.players.count - 4) more")
                        .font(.caption2)
                        .foregroundColor(selected ? .white : .secondary)
                }
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

struct Phase10ListCell_Previews: PreviewProvider {
    // Bob completes all ten phases; the others don't.
    static var finished: Phase10Game {
        let game = Phase10Game.mock
        game.hands = (0..<10).map { _ in
            var hand = Phase10Hand(playerCount: 3)
            hand.playerResults[1] = Phase10PlayerResult(score: 5, completedPhase: true)
            hand.playerResults[0] = Phase10PlayerResult(score: 20, completedPhase: false)
            hand.playerResults[2] = Phase10PlayerResult(score: 15, completedPhase: false)
            return hand
        }
        return game
    }

    static var previews: some View {
        VStack(spacing: 0) {
            Phase10ListCell(game: .mock)
                .padding()
            Divider()
            Phase10ListCell(game: finished)
                .padding()
            Divider()
            Phase10ListCell(game: finished)
                .selected(true)
                .padding()
                .background(Color.accentColor)
        }
        .modelContainer(for: Phase10Game.self, inMemory: true)
    }
}
