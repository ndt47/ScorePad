import Foundation

/// Which Uno deck a game is played with. Each edition has its own card values.
enum UnoEdition: String, Codable, CaseIterable, Identifiable {
    case classic
    case flip

    var id: String { rawValue }

    var name: String {
        switch self {
        case .classic: return String(localized: "Uno")
        case .flip: return String(localized: "Uno Flip")
        }
    }

    /// Whether a hand can end on either side of the deck (Flip), which changes card values.
    var hasSides: Bool { self == .flip }

    /// Every card that can be left in a hand, with its point value. Flip cards are counted by
    /// the side that was face up when the hand ended; `side` is ignored for Classic.
    func cards(side: UnoSide) -> [UnoCard] {
        switch (self, side) {
        case (.classic, _):
            return UnoCard.numbers(0...9) + [
                UnoCard(id: "skip", name: "Skip", symbol: "⊘", points: 20, color: .red),
                UnoCard(id: "reverse", name: "Reverse", symbol: "⇄", points: 20, color: .yellow),
                UnoCard(id: "draw2", name: "Draw Two", symbol: "+2", points: 20, color: .green),
                UnoCard(id: "shuffle", name: "Wild Shuffle Hands", symbol: "W⇆", points: 40, color: .wild),
                UnoCard(id: "custom", name: "Wild Customizable", symbol: "W✎", points: 40, color: .wild),
                UnoCard(id: "wild", name: "Wild", symbol: "W", points: 50, color: .wild),
                UnoCard(id: "wild4", name: "Wild Draw Four", symbol: "+4", points: 50, color: .wild),
            ]
        case (.flip, .light):
            return UnoCard.numbers(1...9) + [
                UnoCard(id: "draw1", name: "Draw One", symbol: "+1", points: 10, color: .blue),
                UnoCard(id: "skip", name: "Skip", symbol: "⊘", points: 20, color: .red),
                UnoCard(id: "reverse", name: "Reverse", symbol: "⇄", points: 20, color: .yellow),
                UnoCard(id: "flip", name: "Flip", symbol: "⟲", points: 20, color: .green),
                UnoCard(id: "wild", name: "Wild", symbol: "W", points: 40, color: .wild),
                UnoCard(id: "wild2", name: "Wild Draw Two", symbol: "+2", points: 50, color: .wild),
            ]
        case (.flip, .dark):
            return UnoCard.numbers(1...9) + [
                UnoCard(id: "draw5", name: "Draw Five", symbol: "+5", points: 20, color: .pink),
                UnoCard(id: "reverse", name: "Reverse", symbol: "⇄", points: 20, color: .teal),
                UnoCard(id: "flip", name: "Flip", symbol: "⟲", points: 20, color: .orange),
                UnoCard(id: "skipAll", name: "Skip Everyone", symbol: "⊘⊘", points: 30, color: .purple),
                UnoCard(id: "wild", name: "Wild", symbol: "W", points: 40, color: .wild),
                UnoCard(id: "wildColor", name: "Wild Draw Color", symbol: "+C", points: 60, color: .wild),
            ]
        }
    }
}

/// The face of a Flip deck that was up when a hand ended.
enum UnoSide: String, Codable, CaseIterable {
    case light
    case dark

    var name: String {
        switch self {
        case .light: return String(localized: "Light")
        case .dark: return String(localized: "Dark")
        }
    }
}

/// The two official ways to score Uno.
enum UnoScoring: String, Codable, CaseIterable, Identifiable {
    /// Whoever goes out scores the cards left in every other hand; highest total wins.
    case winnerCollects
    /// Everyone scores the cards left in their own hand; lowest total wins.
    case pointsAgainst

    var id: String { rawValue }

    var name: String {
        switch self {
        case .winnerCollects: return String(localized: "Winner collects")
        case .pointsAgainst: return String(localized: "Points against")
        }
    }

    var summary: String {
        switch self {
        case .winnerCollects:
            return String(localized: "Whoever goes out scores the cards left in everyone else's hand. Highest total wins.")
        case .pointsAgainst:
            return String(localized: "Everyone scores the cards left in their own hand. Lowest total wins.")
        }
    }
}

/// One kind of card and what it's worth when left in a hand.
struct UnoCard: Identifiable, Hashable {
    enum Color: Hashable {
        case number, red, yellow, green, blue, wild
        case pink, teal, orange, purple  // Flip dark side
    }

    let id: String
    let name: String
    /// Short label for a Card Pad key or a tray chip.
    let symbol: String
    let points: Int
    let color: Color

    var isNumber: Bool { color == .number }

    static func numbers(_ values: ClosedRange<Int>) -> [UnoCard] {
        values.map { UnoCard(id: "n\($0)", name: "\($0)", symbol: "\($0)", points: $0, color: .number) }
    }
}
