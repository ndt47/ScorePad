import Foundation

struct Phase10Hand: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date = Date.now
    var playerResults: [Phase10PlayerResult]

    init(playerCount: Int) {
        playerResults = Array(repeating: Phase10PlayerResult(), count: playerCount)
    }
}

struct Phase10PlayerResult: Codable, Equatable {
    var score: Int = 0
    var completedPhase: Bool = false

    init(score: Int = 0, completedPhase: Bool = false) {
        self.score = score
        self.completedPhase = completedPhase
    }
}
