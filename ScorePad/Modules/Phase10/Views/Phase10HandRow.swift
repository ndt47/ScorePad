import SwiftUI

typealias PresentPhase10Hand = (Phase10Hand) -> Void

private struct PresentPhase10HandKey: EnvironmentKey {
    static let defaultValue: PresentPhase10Hand = { _ in }
}

private struct Phase10PlayerColumnWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = Phase10Game.playerColumnWidth
}

extension EnvironmentValues {
    var presentPhase10Hand: PresentPhase10Hand {
        get { self[PresentPhase10HandKey.self] }
        set { self[PresentPhase10HandKey.self] = newValue }
    }
    var phase10PlayerColumnWidth: CGFloat {
        get { self[Phase10PlayerColumnWidthKey.self] }
        set { self[Phase10PlayerColumnWidthKey.self] = newValue }
    }
}

// MARK: - Hand Row

struct Phase10HandRow: View {
    var hand: Phase10Hand
    var handIndex: Int
    @EnvironmentObject var game: Phase10Game
    @Environment(\.presentPhase10Hand) var present
    @Environment(\.phase10PlayerColumnWidth) var columnWidth

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("\(handIndex + 1)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: Phase10Game.labelColumnWidth)

            ForEach(hand.playerResults.indices, id: \.self) { i in
                Divider()
                playerCell(playerIndex: i, result: hand.playerResults[i])
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { present(hand) }
    }

    @ViewBuilder
    private func playerCell(playerIndex: Int, result: Phase10PlayerResult) -> some View {
        let color = Phase10Game.playerColor(for: playerIndex)
        let phaseAtHand = game.phase(for: playerIndex, atHandIndex: handIndex)

        VStack(spacing: 4) {
            Text(result.score == 0 ? "—" : "+\(result.score)")
                .font(.subheadline)
                .fontDesign(.monospaced)
                .foregroundColor(result.score == 0 ? .secondary : .primary)

            // Always reserve space for the badge so every cell has the same height
            Text("Ph \(phaseAtHand)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(result.completedPhase ? color : Color.clear))
                .opacity(result.completedPhase ? 1 : 0)
        }
        .frame(width: columnWidth)
    }
}

struct Phase10HandRow_Previews: PreviewProvider {
    static var previews: some View {
        Phase10HandRow(hand: Phase10Game.mock.hands[0], handIndex: 0)
            .environmentObject(Phase10Game.mock)
    }
}
