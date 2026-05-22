import SwiftUI

struct WinnerBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "trophy.fill")
            Text("Winner")
                .font(.caption)
        }
        .foregroundColor(.orange)
    }
}

#Preview {
    WinnerBadge()
        .padding()
}
