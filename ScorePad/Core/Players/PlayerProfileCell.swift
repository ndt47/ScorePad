import SwiftUI

/// Fixed-height row cell for a PersonProfile. Uses spacers to keep consistent
/// height regardless of whether aliases are present.
struct PlayerProfileCell: View {
    let profile: PersonProfile
    static let rowHeight: CGFloat = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Spacer(minLength: 0)
            Text(profile.name)
            Text(profile.aliases.joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .frame(height: Self.rowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
