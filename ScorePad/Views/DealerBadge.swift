import SwiftUI

/// Marks the player dealing the current hand: the same orange star in every game.
struct DealerBadge: View {
    var body: some View {
        Image(systemName: "star.fill")
            .font(.caption)
            .foregroundStyle(.orange)
            .accessibilityLabel("Dealer")
    }
}

#Preview {
    HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text("Alice")
        DealerBadge()
    }
    .padding()
}
