import Foundation

struct MilleBornesHand: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date = Date()
    var team1: MilleBornesTeamScore = MilleBornesTeamScore()
    var team2: MilleBornesTeamScore = MilleBornesTeamScore()

    // Shut out: trip completer wins while opponent drove 0 miles
    var team1ShutOut: Bool { team1.tripCompleted && team2.totalMiles == 0 }
    var team2ShutOut: Bool { team2.tripCompleted && team1.totalMiles == 0 }

    var team1Score: Int { team1.handScore + (team1ShutOut ? 500 : 0) }
    var team2Score: Int { team2.handScore + (team2ShutOut ? 500 : 0) }
}
