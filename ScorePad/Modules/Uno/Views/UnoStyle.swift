import SwiftUI

/// Colours shared by the Uno screens.
enum UnoStyle {
    /// The four Uno colours first, then the Phase 10 extended palette, for up to 10 players.
    static let playerColors: [Color] = [
        .red, .yellow, .green, .blue, .orange, .purple, .pink, .teal, .brown, .indigo
    ]

    static func playerColor(for index: Int) -> Color {
        playerColors[index % playerColors.count]
    }

    /// Text on a player-coloured fill; yellow needs dark text to stay readable.
    static func textColor(onPlayer index: Int) -> Color {
        playerColor(for: index) == .yellow ? .black : .white
    }

    /// Card face colours, matching the printed decks.
    static func color(for card: UnoCard.Color) -> Color {
        switch card {
        case .number: return Color.secondary.opacity(0.15)
        case .red: return Color(red: 0.84, green: 0.15, blue: 0.0)
        case .yellow: return Color(red: 0.93, green: 0.83, blue: 0.03)
        case .green: return Color(red: 0.22, green: 0.59, blue: 0.07)
        case .blue: return Color(red: 0.04, green: 0.34, blue: 0.75)
        case .wild: return Color(white: 0.1)
        case .pink: return Color(red: 0.89, green: 0.22, blue: 0.56)
        case .teal: return Color(red: 0.07, green: 0.65, blue: 0.63)
        case .orange: return Color(red: 0.94, green: 0.50, blue: 0.11)
        case .purple: return Color(red: 0.48, green: 0.25, blue: 0.71)
        }
    }

    static func textColor(on card: UnoCard.Color) -> Color {
        switch card {
        case .number: return .primary
        case .yellow: return .black
        default: return .white
        }
    }

    /// The four-colour ring drawn around wild cards.
    static var wildRing: [Color] {
        [color(for: .red), color(for: .yellow), color(for: .green), color(for: .blue), color(for: .red)]
    }
}

/// A small marker for the side a Flip hand ended on.
struct UnoSideMarker: View {
    let side: UnoSide

    var body: some View {
        Image(systemName: side == .light ? "sun.max.fill" : "moon.fill")
            .font(.caption2)
            .foregroundStyle(side == .light ? Color.orange : Color.purple)
            .accessibilityLabel(side == .light ? "Ended on the light side" : "Ended on the dark side")
    }
}

/// Lays out children left to right, wrapping onto new rows as needed.
struct UnoFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: subviews, width: proposal.width ?? .infinity)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(for: subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(for subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let widthWithItem = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if widthWithItem > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
