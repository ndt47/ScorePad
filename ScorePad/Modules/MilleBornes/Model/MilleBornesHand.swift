import Foundation

struct MilleBornesHand: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date = Date()
    var team1: MilleBornesTeamScore = MilleBornesTeamScore()
    var team2: MilleBornesTeamScore = MilleBornesTeamScore()
}
