import Foundation
import SwiftData

@Model
final class MilleBornesGame: ObservableObject, Identifiable, Codable {
    var id: UUID = UUID()
    var dateCreated: Date = Date.now
    var lastModified: Date = Date.now
    var team1Players: [PlayerRef] = []
    var team2Players: [PlayerRef] = []
    var hands: [MilleBornesHand] = []
    /// Index into `seatingOrder` of whoever dealt the first hand.
    var startingDealerIndex: Int = 0

    init(team1Players: [PlayerRef] = [], team2Players: [PlayerRef] = [], startingDealerIndex: Int = 0) {
        self.id = UUID()
        self.dateCreated = .now
        self.lastModified = .now
        self.team1Players = team1Players
        self.team2Players = team2Players
        self.hands = []
        self.startingDealerIndex = startingDealerIndex
    }

    // SwiftData's @Model macro doesn't synthesize Codable when stored properties include
    // complex Codable types (like [MilleBornesHand]). Manual implementation is required
    // to support export/import without a separate DTO layer.
    enum CodingKeys: CodingKey {
        case id, dateCreated, lastModified, team1Players, team2Players, hands, startingDealerIndex
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self,              forKey: .id)
        dateCreated  = try c.decode(Date.self,              forKey: .dateCreated)
        lastModified = try c.decode(Date.self,              forKey: .lastModified)
        team1Players = try c.decode([PlayerRef].self,       forKey: .team1Players)
        team2Players = try c.decode([PlayerRef].self,       forKey: .team2Players)
        hands        = try c.decode([MilleBornesHand].self, forKey: .hands)
        startingDealerIndex = try c.decode(Int.self,        forKey: .startingDealerIndex)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,           forKey: .id)
        try c.encode(dateCreated,  forKey: .dateCreated)
        try c.encode(lastModified, forKey: .lastModified)
        try c.encode(team1Players, forKey: .team1Players)
        try c.encode(team2Players, forKey: .team2Players)
        try c.encode(hands,        forKey: .hands)
        try c.encode(startingDealerIndex, forKey: .startingDealerIndex)
    }

    var isFinished: Bool {
        cumulativeScore(team: 1) >= 5000 || cumulativeScore(team: 2) >= 5000
    }

    var winningTeam: Int? {
        guard isFinished else { return nil }
        let s1 = cumulativeScore(team: 1)
        let s2 = cumulativeScore(team: 2)
        if s1 > s2 { return 1 }
        if s2 > s1 { return 2 }
        return nil
    }

    func cumulativeScore(team: Int) -> Int {
        hands.reduce(0) { $0 + (team == 1 ? $1.team1Score(isTwoPlayerGame: isTwoPlayerGame)
                                           : $1.team2Score(isTwoPlayerGame: isTwoPlayerGame)) }
    }

    func addHand(_ hand: MilleBornesHand) {
        hands.append(hand)
        lastModified = .now
    }

    func replaceHand(_ hand: MilleBornesHand) {
        guard let index = hands.firstIndex(where: { $0.id == hand.id }) else { return }
        hands[index] = hand
        lastModified = .now
    }

    /// Players in seating order. The teams alternate, so partners sit opposite each other:
    /// Team 1, Team 2, Team 1, Team 2.
    var seatingOrder: [PlayerRef] {
        Self.seatingOrder(team1: team1Players, team2: team2Players)
    }

    static func seatingOrder<T>(team1: [T], team2: [T]) -> [T] {
        (0..<max(team1.count, team2.count)).flatMap { seat in
            [team1, team2].compactMap { $0.indices.contains(seat) ? $0[seat] : nil }
        }
    }

    /// Whoever deals the current hand; the deal passes one seat to the left after every hand.
    var currentDealer: PlayerRef? {
        let seats = seatingOrder
        guard !seats.isEmpty else { return nil }
        return seats[(startingDealerIndex + hands.count) % seats.count]
    }

    // <= 1 (not == 1) so a game with no players yet (during creation) defaults to 2-player rules.
    var isTwoPlayerGame: Bool { team1Players.count <= 1 }

    var team1Label: String {
        team1Players.isEmpty ? "Team 1" : team1Players.map(\.cachedName).joined(separator: " & ")
    }

    var team2Label: String {
        team2Players.isEmpty ? "Team 2" : team2Players.map(\.cachedName).joined(separator: " & ")
    }
}

extension MilleBornesGame: Hashable {
    static func == (lhs: MilleBornesGame, rhs: MilleBornesGame) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
}

extension MilleBornesGame {
    static var mock: MilleBornesGame {
        let game = MilleBornesGame(
            team1Players: [.preview("Nathan"), .preview("Caty")],
            team2Players: [.preview("Sharon"), .preview("Larisa")]
        )
        var h1 = MilleBornesHand()
        h1.team1.cards100 = 6; h1.team1.cards50 = 2  // 700 miles → tripCompleted auto
        h1.team1.rightOfWay.played = true
        h1.team1.punctureProof = MilleBornesSafetyState(played: true, coupFourre: true)
        h1.team2.cards100 = 3; h1.team2.cards50 = 2
        h1.team2.drivingAce.played = true
        var h2 = MilleBornesHand()
        h2.team1.cards100 = 4; h2.team1.cards50 = 1
        h2.team1.extraTank.played = true
        h2.team2.cards100 = 5; h2.team2.cards200 = 1  // 700 miles → tripCompleted auto
        h2.team2.rightOfWay.played = true
        h2.team2.punctureProof = MilleBornesSafetyState(played: true, coupFourre: true)
        h2.team2.drivingAce = MilleBornesSafetyState(played: true, coupFourre: true)
        game.hands = [h1, h2]
        return game
    }
}
