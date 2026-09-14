import Foundation

/// One hand: who went out, the side a Flip hand ended on, and the points left in each hand.
/// Scores are derived from this by `UnoGame`, never stored.
struct UnoHand: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date = Date.now
    var wentOutIndex: Int
    /// Meaningful only for Flip games.
    var side: UnoSide = .light
    /// One entry per player, in seat order. The player who went out holds no cards, so 0.
    var pointsLeft: [Int]

    init(playerCount: Int, wentOutIndex: Int = 0, side: UnoSide = .light) {
        self.wentOutIndex = wentOutIndex
        self.side = side
        self.pointsLeft = Array(repeating: 0, count: playerCount)
    }

    /// Total points left in every hand: what the winner collects.
    var handValue: Int { pointsLeft.reduce(0, +) }

    func pointsLeft(for player: Int) -> Int {
        pointsLeft.indices.contains(player) ? pointsLeft[player] : 0
    }
}
