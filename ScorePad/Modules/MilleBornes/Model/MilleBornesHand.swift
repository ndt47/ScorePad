import Foundation

struct MilleBornesHand: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date = Date()
    var team1: MilleBornesTeamScore = MilleBornesTeamScore()
    var team2: MilleBornesTeamScore = MilleBornesTeamScore()

    var extensionCalled: Bool { team1.usedExtension || team2.usedExtension }

    // Shut-out lives here because it requires both teams' data: the winning team
    // must have completed their trip AND the losing team must have zero miles.
    func team1ShutOut(isTwoPlayerGame: Bool) -> Bool {
        team1.tripCompleted(isTwoPlayerGame: isTwoPlayerGame, extensionCalled: extensionCalled) && team2.totalMiles == 0
    }
    func team2ShutOut(isTwoPlayerGame: Bool) -> Bool {
        team2.tripCompleted(isTwoPlayerGame: isTwoPlayerGame, extensionCalled: extensionCalled) && team1.totalMiles == 0
    }

    // Total score for the hand including the shut-out bonus. Callers use this
    // rather than reaching into the team score directly.
    func team1Score(isTwoPlayerGame: Bool) -> Int {
        team1.handScore(isTwoPlayerGame: isTwoPlayerGame, extensionCalled: extensionCalled) + (team1ShutOut(isTwoPlayerGame: isTwoPlayerGame) ? 500 : 0)
    }
    func team2Score(isTwoPlayerGame: Bool) -> Int {
        team2.handScore(isTwoPlayerGame: isTwoPlayerGame, extensionCalled: extensionCalled) + (team2ShutOut(isTwoPlayerGame: isTwoPlayerGame) ? 500 : 0)
    }
}
