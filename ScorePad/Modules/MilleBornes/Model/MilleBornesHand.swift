import Foundation

struct MilleBornesHand: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date = Date()
    var team1: MilleBornesTeamScore = MilleBornesTeamScore()
    var team2: MilleBornesTeamScore = MilleBornesTeamScore()

    func team1ShutOut(isTwoPlayerGame: Bool) -> Bool {
        team1.tripCompleted(isTwoPlayerGame: isTwoPlayerGame) && team2.totalMiles == 0
    }
    func team2ShutOut(isTwoPlayerGame: Bool) -> Bool {
        team2.tripCompleted(isTwoPlayerGame: isTwoPlayerGame) && team1.totalMiles == 0
    }

    func team1Score(isTwoPlayerGame: Bool) -> Int {
        team1.handScore(isTwoPlayerGame: isTwoPlayerGame) + (team1ShutOut(isTwoPlayerGame: isTwoPlayerGame) ? 500 : 0)
    }
    func team2Score(isTwoPlayerGame: Bool) -> Int {
        team2.handScore(isTwoPlayerGame: isTwoPlayerGame) + (team2ShutOut(isTwoPlayerGame: isTwoPlayerGame) ? 500 : 0)
    }
}
