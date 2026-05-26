import Foundation
import SwiftData

@Model
final class MilleBornesGame: ObservableObject, Identifiable, Codable {
    var id: UUID = UUID()
    var dateCreated: Date = Date.now
    var lastModified: Date = Date.now
    var hands: [MilleBornesHand] = []

    // Stored as [String] for schema compatibility (original column names preserved).
    var team1Players: [String] = []
    var team2Players: [String] = []
    // Stores [PlayerRef] as JSON-encoded Data. nil until migration task links names to profiles.
    var team1PlayerRefsData: Data? = nil
    var team2PlayerRefsData: Data? = nil

    // Unified [PlayerRef] API. Uses ref data (with profile IDs) when available;
    // falls back to string names wrapped in PlayerRef for pre-migration records.
    var team1PlayerRefs: [PlayerRef] {
        get {
            if let data = team1PlayerRefsData,
               let refs = try? JSONDecoder().decode([PlayerRef].self, from: data) { return refs }
            return team1Players.map { PlayerRef(name: $0) }
        }
        set {
            team1Players = newValue.map(\.name)
            team1PlayerRefsData = try? JSONEncoder().encode(newValue)
        }
    }

    var team2PlayerRefs: [PlayerRef] {
        get {
            if let data = team2PlayerRefsData,
               let refs = try? JSONDecoder().decode([PlayerRef].self, from: data) { return refs }
            return team2Players.map { PlayerRef(name: $0) }
        }
        set {
            team2Players = newValue.map(\.name)
            team2PlayerRefsData = try? JSONEncoder().encode(newValue)
        }
    }

    init(team1Players: [PlayerRef] = [], team2Players: [PlayerRef] = []) {
        self.id = UUID()
        self.dateCreated = .now
        self.lastModified = .now
        self.team1Players = team1Players.map(\.name)
        self.team1PlayerRefsData = try? JSONEncoder().encode(team1Players)
        self.team2Players = team2Players.map(\.name)
        self.team2PlayerRefsData = try? JSONEncoder().encode(team2Players)
        self.hands = []
    }

    // SwiftData's @Model macro doesn't synthesize Codable when stored properties include
    // complex Codable types (like [MilleBornesHand]). Manual implementation is required
    // to support export/import without a separate DTO layer.
    enum CodingKeys: CodingKey {
        case id, dateCreated, lastModified, team1Players, team2Players, hands
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self,              forKey: .id)
        dateCreated  = try c.decode(Date.self,              forKey: .dateCreated)
        lastModified = try c.decode(Date.self,              forKey: .lastModified)
        // PlayerRef.init(from:) handles both old bare-string and new keyed formats.
        let t1 = try c.decode([PlayerRef].self,             forKey: .team1Players)
        let t2 = try c.decode([PlayerRef].self,             forKey: .team2Players)
        team1Players = t1.map(\.name)
        team2Players = t2.map(\.name)
        team1PlayerRefsData = try? JSONEncoder().encode(t1)
        team2PlayerRefsData = try? JSONEncoder().encode(t2)
        hands        = try c.decode([MilleBornesHand].self, forKey: .hands)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,           forKey: .id)
        try c.encode(dateCreated,  forKey: .dateCreated)
        try c.encode(lastModified, forKey: .lastModified)
        try c.encode(team1PlayerRefs, forKey: .team1Players)
        try c.encode(team2PlayerRefs, forKey: .team2Players)
        try c.encode(hands,        forKey: .hands)
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

    // <= 1 (not == 1) so a game with no players yet (during creation) defaults to 2-player rules.
    var isTwoPlayerGame: Bool { team1Players.count <= 1 }

    var team1Label: String {
        team1Players.isEmpty ? "Team 1" : team1Players.joined(separator: " & ")
    }

    var team2Label: String {
        team2Players.isEmpty ? "Team 2" : team2Players.joined(separator: " & ")
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
            team1Players: [PlayerRef(name: "Nathan"), PlayerRef(name: "Caty")],
            team2Players: [PlayerRef(name: "Sharon"), PlayerRef(name: "Larisa")]
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
