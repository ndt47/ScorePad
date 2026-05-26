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
            Text(game.players[index].name)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(1)
                .allowsTightening(true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 6)
                .opacity(isEliminated ? 0.35 : 1)

            // Phase label / description (tap to toggle) or winner badge
            if game.hasFinished(index) && game.isFinished {
                if isWinner {
                    WinnerBadge()
                } else {
                    Text("Done")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingDescriptions.toggle()
                    }
                } label: {
                    if showingDescriptions {
                        Text(Phase10Game.phaseDescription(for: phase))
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(color)
                    } else {
                        Text("Phase \(phase)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(color)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 6)
                .animation(.easeInOut(duration: 0.2), value: showingDescriptions)
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
