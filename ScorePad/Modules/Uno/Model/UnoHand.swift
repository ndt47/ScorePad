import Foundation

/// One hand: who went out, the side a Flip hand ended on, and the points left in each hand.
/// Scores are derived from this by `UnoGame`, never stored.
struct UnoHand: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date = Date.now
    var wentOutIndex: Int
    /// Meaningful only for Flip games.
    var side: UnoSide = .light
    /// One entry per player, in seat order. Whoever went out holds no cards; their entry is
    /// ignored and `normalized()` sets it to 0.
    var pointsLeft: [Int]

    init(playerCount: Int, wentOutIndex: Int = 0, side: UnoSide = .light) {
        self.wentOutIndex = wentOutIndex
        self.side = side
        self.pointsLeft = Array(repeating: 0, count: playerCount)
    }

    /// Points left in everyone else's hand: what the player who went out collects.
    var handValue: Int {
        pointsLeft.indices.reduce(0) { $0 + pointsLeft(for: $1) }
    }

    /// Points left in `player`'s hand; always 0 for whoever went out.
    func pointsLeft(for player: Int) -> Int {
        guard player != wentOutIndex, pointsLeft.indices.contains(player) else { return 0 }
        return pointsLeft[player]
    }

    /// The hand with the went-out player's entry zeroed, as stored.
    func normalized() -> UnoHand {
        var hand = self
        if hand.pointsLeft.indices.contains(wentOutIndex) { hand.pointsLeft[wentOutIndex] = 0 }
        return hand
    }
}
