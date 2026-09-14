import SwiftUI

struct UnoListCell: View {
    @State var game: UnoGame
    @Environment(\.selected) var selected

    init(game: UnoGame) {
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
                if game.edition == .flip {
                    Text("Flip")
                        .font(.caption2.bold())
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().strokeBorder(selected ? Color.white : Color.purple))
                        .foregroundStyle(selected ? Color.white : Color.purple)
                }
                Spacer()
                if game.isFinished {
                    WinnerBadge(showLabel: false)
                }
            }

            // Up to 4 players shown; the rest collapse to "+N more"
            VStack(alignment: .leading, spacing: 3) {
                ForEach(game.players.indices.prefix(4), id: \.self) { i in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(UnoStyle.playerColor(for: i))
                            .frame(width: 8, height: 8)
                        Text(game.players[i].cachedName)
                            .font(.caption).fontWeight(.medium)
                            .lineLimit(1)
                        Spacer()
                        Text(game.cumulativeScore(for: i).formatted(.number.grouping(.never)))
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundColor(selected ? .white : .secondary)
                        if game.isWinner(i) {
                            Image(systemName: "trophy.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
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

#Preview {
    VStack(spacing: 0) {
        UnoListCell(game: .mock)
            .padding()
        Divider()
        UnoListCell(game: .mock)
            .selected(true)
            .padding()
            .background(Color.accentColor)
    }
}
