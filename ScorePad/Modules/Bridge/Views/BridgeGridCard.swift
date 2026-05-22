import SwiftUI

struct BridgeGridCard: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "suit.spade.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.tint)
            }
            VStack(spacing: 4) {
                Text("Bridge")
                    .font(.headline)
                Text("Rubber Bridge")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.separator, lineWidth: 0.5)
        }
    }
}
