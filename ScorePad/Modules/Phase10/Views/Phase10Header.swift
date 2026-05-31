import SwiftUI

struct Phase10Header: View {
    @EnvironmentObject var game: Phase10Game
    @Environment(\.phase10PlayerColumnWidth) var columnWidth

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

            // Phase label / description (always visible, fixed 2-row height) or winner badge
            if game.hasFinished(index) && game.isFinished {
                if isWinner {
                    WinnerBadge()
                } else {
                    Text("Done")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                // Invisible spacer keeps height consistent with the 2-row phase display
                Text("").font(.caption2)
            } else {
                let parts = Phase10Game.phaseDescriptionParts(for: phase)
                VStack(alignment: .center, spacing: 0) {
                    Text("Phase \(phase): \(parts.line1)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                    Text(parts.line2 ?? "")
                        .font(.caption2)
                        .foregroundColor(parts.line2 == nil ? .clear : color)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 6)
            }

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
