import SwiftUI

struct Phase10Header: View {
    @EnvironmentObject var game: Phase10Game
    @Environment(\.phase10PlayerColumnWidth) var columnWidth
    @State private var showingDescriptions = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .center, spacing: 3) {
                Rectangle()
                    .fill(Color.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
                Text("Hand")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .frame(width: Phase10Game.labelColumnWidth, alignment: .top)

            ForEach(game.players.indices, id: \.self) { i in
                Divider()
                playerColumn(for: i)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { showingDescriptions.toggle() }
        .accessibilityAction(named: showingDescriptions ? "Show Phase Numbers" : "Show Phase Descriptions") {
            showingDescriptions.toggle()
        }
    }

    @ViewBuilder
    private func playerColumn(for index: Int) -> some View {
        let color = Phase10Game.playerColor(for: index)
        let phase = game.currentPhase(for: index)
        let score = game.cumulativeScore(for: index)
        let isWinner = game.winnerIndex == index
        let isEliminated = game.hasFinished(index) && game.isFinished && !isWinner

        VStack(alignment: .center, spacing: 3) {
            // Color accent bar
            Rectangle()
                .fill(color)
                .frame(maxWidth: .infinity)
                .frame(height: 4)

            // Player name
            Text(game.players[index].cachedName)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(1)
                .allowsTightening(true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 6)
                .opacity(isEliminated ? 0.35 : 1)

            // Dealer badge — always reserves space so all columns stay the same height
            Text("D")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Capsule().fill(color))
                .opacity(index == game.currentDealerIndex && !game.isFinished ? 1 : 0)

            // Phase number, or its description when the header is tapped, or the result once
            // the game is over. Every state is drawn over the same hidden two-line placeholder,
            // so toggling or finishing never changes the header's height.
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    Text(verbatim: " ")
                    Text(verbatim: " ")
                }
                .hidden()

                if game.hasFinished(index) && game.isFinished {
                    if isWinner {
                        WinnerBadge()
                    } else {
                        Text("Done")
                            .foregroundColor(.secondary)
                    }
                } else {
                    let parts = Phase10Game.phaseDescriptionParts(for: phase)
                    Text("Phase \(phase)")
                        .foregroundColor(color)
                        .opacity(showingDescriptions ? 0 : 1)
                    VStack(spacing: 0) {
                        Text(parts.line1)
                        if let line2 = parts.line2 {
                            Text(line2)
                        }
                    }
                    .foregroundColor(color)
                    .opacity(showingDescriptions ? 1 : 0)
                }
            }
            .font(.caption)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 6)
            .animation(.easeInOut(duration: 0.2), value: showingDescriptions)

            // Cumulative score
            Text(score.formatted(.number.grouping(.never)))
                .font(.subheadline)
                .fontDesign(.monospaced)
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
        }
        .frame(width: columnWidth, alignment: .top)
    }
}

struct Phase10Header_Previews: PreviewProvider {
    static var previews: some View {
        Phase10Header()
            .environmentObject(Phase10Game.mock)
    }
}
