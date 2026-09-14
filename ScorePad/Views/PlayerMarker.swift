import SwiftUI

/// A player's colour marker in lists: a dot, or a trophy in the same colour once they've won,
/// so the winner is marked beside their own name rather than by a separate badge.
struct PlayerMarker: View {
    let color: Color
    var isWinner = false

    var body: some View {
        if isWinner {
            Image(systemName: "trophy.fill")
                .font(.caption2)
                .foregroundStyle(color)
                .frame(width: 12)
                .accessibilityLabel("Winner")
        } else {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .frame(width: 12)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 6) {
        HStack { PlayerMarker(color: .red, isWinner: true); Text("Alice") }
        HStack { PlayerMarker(color: .yellow); Text("Bob") }
        HStack { PlayerMarker(color: .green); Text("Cara") }
    }
    .padding()
}
