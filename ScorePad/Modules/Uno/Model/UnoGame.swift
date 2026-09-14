import Foundation
import SwiftData

@Model
final class UnoGame: ObservableObject, Identifiable {
    var id: UUID = UUID()
    var dateCreated: Date = Date.now
    var lastModified: Date = Date.now
    var players: [PlayerRef] = []
    var edition: UnoEdition = UnoEdition.classic
    var scoring: UnoScoring = UnoScoring.winnerCollects
    var targetScore: Int = 500
    var startingDealerIndex: Int = 0
    var hands: [UnoHand] = []

    init(players: [PlayerRef],
         edition: UnoEdition = .classic,
         scoring: UnoScoring = .winnerCollects,
         targetScore: Int = 500,
         startingDealerIndex: Int = 0) {
        self.id = UUID()
        self.dateCreated = .now
        self.lastModified = .now
        self.players = players
        self.edition = edition
        self.scoring = scoring
        self.targetScore = targetScore
        self.startingDealerIndex = startingDealerIndex
        self.hands = []
    }

    static let defaultTargetScore = 500

    var currentDealerIndex: Int {
        guard !players.isEmpty else { return 0 }
        return (startingDealerIndex + hands.count) % players.count
    }

    /// What `player` scored in `hand`: the whole hand's value if they went out (winner
    /// collects), or the points left in their own hand (points against).
    func score(for player: Int, in hand: UnoHand) -> Int {
        switch scoring {
        case .winnerCollects: return hand.wentOutIndex == player ? hand.handValue : 0
        case .pointsAgainst: return hand.pointsLeft(for: player)
        }
    }

    func cumulativeScore(for player: Int) -> Int {
        hands.reduce(0) { $0 + score(for: player, in: $1) }
    }

    /// The game ends as soon as anyone reaches the target.
    var isFinished: Bool {
        players.indices.contains { cumulativeScore(for: $0) >= targetScore }
    }

    /// Once the game is over: the players with the highest total (winner collects) or the
    /// lowest (points against). More than one when they tie.
    var winnerIndices: [Int] {
        guard isFinished else { return [] }
        let totals = players.indices.map { cumulativeScore(for: $0) }
        guard let best = scoring == .winnerCollects ? totals.max() : totals.min() else { return [] }
        return players.indices.filter { totals[$0] == best }
    }

    func isWinner(_ player: Int) -> Bool {
        winnerIndices.contains(player)
    }

    func addHand(_ hand: UnoHand) {
        hands.append(hand)
        lastModified = .now
    }

    func replaceHand(_ hand: UnoHand) {
        guard let index = hands.firstIndex(where: { $0.id == hand.id }) else { return }
        hands[index] = hand
        lastModified = .now
    }
}

extension UnoGame: Hashable {
    static func == (lhs: UnoGame, rhs: UnoGame) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { id.hash(into: &hasher) }
}

extension UnoGame {
    /// A Flip game four hands in, for previews.
    static var mock: UnoGame {
        let game = UnoGame(players: [.preview("Alice"), .preview("Bob"), .preview("Cara"), .preview("Dan")],
                           edition: .flip)
        let hands: [(out: Int, side: UnoSide, left: [Int])] = [
            (2, .light, [22, 41, 0, 18]),
            (0, .dark, [0, 96, 60, 142]),
            (3, .dark, [75, 30, 124, 0]),
            (0, .light, [0, 38, 57, 12]),
        ]
        game.hands = hands.map {
            var hand = UnoHand(playerCount: 4, wentOutIndex: $0.out, side: $0.side)
            hand.pointsLeft = $0.left
            return hand
        }
        return game
    }
}
