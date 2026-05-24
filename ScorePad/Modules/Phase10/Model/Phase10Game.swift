import Foundation
import SwiftData
import SwiftUI

@Model
final class Phase10Game: ObservableObject, Identifiable {
    var id: UUID = UUID()
    var dateCreated: Date = Date.now
    var lastModified: Date = Date.now
    var players: [String] = []
    var hands: [Phase10Hand] = []

    init(players: [String]) {
        self.id = UUID()
        self.dateCreated = .now
        self.lastModified = .now
        self.players = players
        self.hands = []
    }

    // Layout constants shared across score sheet views
    static let labelColumnWidth: CGFloat = 56
    static let playerColumnWidth: CGFloat = 110

    // The 10 phases with emoji icons and descriptions
    static let phases: [(icon: String, description: String)] = [
        ("🃏🃏", "2 sets of 3"),
        ("🃏🏃", "1 set of 3 + 1 run of 4"),
        ("🃏🏃", "1 set of 4 + 1 run of 4"),
        ("🏃", "1 run of 7"),
        ("🏃", "1 run of 8"),
        ("🏃", "1 run of 9"),
        ("🃏🃏", "2 sets of 4"),
        ("🎨", "7 cards of one color"),
        ("🃏🃏", "1 set of 5 + 1 set of 2"),
        ("🃏🃏", "1 set of 4 + 1 set of 3"),
    ]

    // Cycles through the 4 Phase 10 card colors, then extended palette for 5–8 players
    static let playerColors: [Color] = [
        .red, .yellow, .green, .blue, .orange, .purple, .pink, .teal
    ]

    static func phaseDescription(for phase: Int) -> String {
        guard phase >= 1, phase <= 10 else { return "" }
        return phases[phase - 1].description
    }

    static func phaseIcon(for phase: Int) -> String {
        guard phase >= 1, phase <= 10 else { return "" }
        return phases[phase - 1].icon
    }

    static func playerColor(for index: Int) -> Color {
        playerColors[index % playerColors.count]
    }

    // 1 + count of completed phases across all prior hands; capped at 10
    func currentPhase(for playerIndex: Int) -> Int {
        let completed = hands.filter { $0.playerResults[playerIndex].completedPhase }.count
        return min(completed + 1, 10)
    }

    // Phase the player was on when they played the hand at handIndex
    func phase(for playerIndex: Int, atHandIndex handIndex: Int) -> Int {
        let completed = hands.prefix(handIndex).filter { $0.playerResults[playerIndex].completedPhase }.count
        return min(completed + 1, 10)
    }

    func cumulativeScore(for playerIndex: Int) -> Int {
        hands.reduce(0) { $0 + $1.playerResults[playerIndex].score }
    }

    func hasFinished(_ playerIndex: Int) -> Bool {
        hands.filter { $0.playerResults[playerIndex].completedPhase }.count >= 10
    }

    var isFinished: Bool {
        players.indices.contains { hasFinished($0) }
    }

    // Among players who completed phase 10, the one with the lowest cumulative score wins
    var winnerIndex: Int? {
        guard isFinished else { return nil }
        let finishers = players.indices.filter { hasFinished($0) }
        return finishers.min(by: { cumulativeScore(for: $0) < cumulativeScore(for: $1) })
    }

    func addHand(_ hand: Phase10Hand) {
        hands.append(hand)
        lastModified = .now
    }

    func replaceHand(_ hand: Phase10Hand) {
        guard let index = hands.firstIndex(where: { $0.id == hand.id }) else { return }
        hands[index] = hand
        lastModified = .now
    }
}

extension Phase10Game: Hashable {
    static func == (lhs: Phase10Game, rhs: Phase10Game) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { id.hash(into: &hasher) }
}

extension Phase10Game {
    static var mock: Phase10Game {
        let game = Phase10Game(players: ["Alice", "Bob", "Charlie"])
        var h1 = Phase10Hand(playerCount: 3)
        h1.playerResults[0] = Phase10PlayerResult(score: 35, completedPhase: true)
        h1.playerResults[1] = Phase10PlayerResult(score: 25, completedPhase: true)
        h1.playerResults[2] = Phase10PlayerResult(score: 0,  completedPhase: true)
        var h2 = Phase10Hand(playerCount: 3)
        h2.playerResults[0] = Phase10PlayerResult(score: 0,  completedPhase: true)
        h2.playerResults[1] = Phase10PlayerResult(score: 15, completedPhase: false)
        h2.playerResults[2] = Phase10PlayerResult(score: 15, completedPhase: true)
        game.hands = [h1, h2]
        return game
    }
}
