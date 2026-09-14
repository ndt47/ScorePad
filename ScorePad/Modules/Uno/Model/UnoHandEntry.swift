import Foundation

/// A hand as it is being entered: who went out, the side a Flip hand ended on, and each
/// player's points as typed or counted with the Card Pad. The hand-entry sheet is a thin view
/// over this, so every rule about what can be saved is testable here.
struct UnoHandEntry: Equatable {
    /// Cards counted with the Card Pad, and the side they were counted on.
    struct Count: Equatable {
        let side: UnoSide
        let cards: [UnoCard]
        var points: Int { cards.reduce(0) { $0 + $1.points } }
    }

    let edition: UnoEdition
    let playerNames: [String]
    var wentOut: Int?
    var side: UnoSide = .light
    /// Points left per player; nil until entered, so a forgotten row can't save as 0.
    private(set) var points: [Int?]
    private(set) var counts: [Int: Count] = [:]

    init(edition: UnoEdition, playerNames: [String]) {
        self.edition = edition
        self.playerNames = playerNames
        self.points = Array(repeating: nil, count: playerNames.count)
    }

    /// Starts from a saved hand, for editing.
    init(editing hand: UnoHand, edition: UnoEdition, playerNames: [String]) {
        self.init(edition: edition, playerNames: playerNames)
        wentOut = hand.wentOutIndex
        side = hand.side
        points = playerNames.indices.map { $0 == hand.wentOutIndex ? nil : hand.pointsLeft(for: $0) }
    }

    /// Everyone except whoever went out.
    var opponents: [Int] {
        playerNames.indices.filter { $0 != wentOut }
    }

    func points(for player: Int) -> Int? {
        points.indices.contains(player) ? points[player] : nil
    }

    /// Points left in every opponent's hand, counting blanks as 0.
    var total: Int {
        opponents.reduce(0) { $0 + (points(for: $1) ?? 0) }
    }

    /// The side a count should use: Classic has only one.
    var countingSide: UnoSide {
        edition.hasSides ? side : .light
    }

    /// A count made on the other side no longer matches: Flip cards are worth different
    /// points on each face.
    func isStale(_ player: Int) -> Bool {
        guard edition.hasSides, let count = counts[player] else { return false }
        return count.side != side
    }

    /// Cards to reopen the Card Pad with: the earlier count, if it was made on the current side.
    func cardsToRecount(for player: Int) -> [UnoCard] {
        guard let count = counts[player], count.side == countingSide else { return [] }
        return count.cards
    }

    /// Why the hand can't be saved yet, or nil.
    var problem: String? {
        guard wentOut != nil else { return String(localized: "Choose who went out.") }
        for player in opponents {
            let name = playerNames[player]
            guard let value = points(for: player) else {
                return String(localized: "Enter the points left in \(name)’s hand.")
            }
            if isStale(player), let counted = counts[player]?.side {
                return String(localized: "Count \(name)’s cards again: they were counted on the \(counted.name.lowercased()) side.")
            }
            if edition == .flip && value == 0 {
                return String(localized: "\(name) can’t have 0 points: Uno Flip has no zero cards.")
            }
        }
        return nil
    }

    /// A typed value replaces any Card Pad count, since the number no longer comes from it.
    mutating func setTyped(_ value: Int?, for player: Int) {
        guard points.indices.contains(player), value != points[player] else { return }
        points[player] = value
        counts[player] = nil
    }

    mutating func setCounted(_ cards: [UnoCard], for player: Int) {
        guard points.indices.contains(player) else { return }
        let count = Count(side: countingSide, cards: cards)
        counts[player] = count
        points[player] = count.points
    }

    /// The hand to save, updating `existing` when editing; nil while there is a `problem`.
    func makeHand(updating existing: UnoHand? = nil) -> UnoHand? {
        guard problem == nil, let wentOut else { return nil }
        var hand = existing ?? UnoHand(playerCount: playerNames.count)
        hand.wentOutIndex = wentOut
        hand.side = countingSide
        hand.pointsLeft = points.map { $0 ?? 0 }
        return hand.normalized()
    }
}
