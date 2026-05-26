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
                Text(game.playerRefs.map(\.name).joined(separator: ", "))
                    .fontWeight(.light)
                    .font(.subheadline)
                    .lineLimit(1)
                    .allowsTightening(true)
                Spacer()
                if game.winnerIndex != nil {
                    WinnerBadge(showLabel: false)
                }
            }

            // Up to 4 players shown; excess collapsed to "+N more"
            let displayed = game.playerRefs.prefix(4)
            VStack(alignment: .leading, spacing: 3) {
                ForEach(displayed.indices, id: \.self) { i in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Phase10Game.playerColor(for: i))
                            .frame(width: 8, height: 8)
                        Text(game.playerRefs[i].name)
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
                        if game.winnerIndex == i {
                            Image(systemName: "trophy.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                if game.playerRefs.count > 4 {
                    Text("+\(game.playerRefs.count - 4) more")
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
    static var previews: some View {
        VStack(spacing: 0) {
            Phase10ListCell(game: .mock)
                .padding()
            Divider()
            Phase10ListCell(game: .mock)
                .selected(true)
                .padding()
                .background(Color.accentColor)
        }
        .modelContainer(for: Phase10Game.self, inMemory: true)
    }
}
