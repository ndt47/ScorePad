import SwiftUI

struct WinnerBadge: View {
    var showLabel: Bool = true

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "trophy.fill")
            if showLabel {
                Text("Winner")
                    .font(.caption)
            }
        }
        .foregroundColor(.orange)
    }
}

#Preview {
    VStack(spacing: 12) {
        WinnerBadge()
        WinnerBadge(showLabel: false)
    }
    .padding()
}
