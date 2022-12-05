//
//  Rubber.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/28/22.
//

import Foundation

enum Team {
    case we // north and south
    case they // east and west
    
    var opponent: Team {
        switch self {
        case .we: return .they
        case .they: return .we
        }
    }
    
    var positions: [Position] {
        switch self {
        case .we:
            return [.north, .south]
        case .they:
            return [.east, .west]
        }
    }
}

extension Team {
    var label: String {
        switch self {
        case .we:
            return "We"
        case .they:
            return "They"
        }
    }
}

struct Player: Codable {
    var name: String
    var position: Position
}

enum Game: Identifiable {
    var id: UUID { .init() }
    
    case none(PartialRangeFrom<Int>)
    case partial(PartialRangeFrom<Int>)
    case complete(Team, ClosedRange<Int>)
    case rubber(Team, ClosedRange<Int>)
}

extension Array where Element == Game {
    var vulnerableTeams: Set<Team> {
        guard let last = self.last else { return .init() }
        if case .rubber = last { return .init() }
        
        return Set(compactMap { game in
            if case let .complete(team, _) = game {
                return team
            }
            return nil
        })
    }
}

class Rubber: ObservableObject, Identifiable, Codable {
    let id: UUID
    let dateCreated: Date
    var lastModified: Date
    var players: [Player]
    let startingDealer: Position
    @Published var history: [AuctionResult]
    
    init(players: [Player] = [], dealer: Position = .north, history: [AuctionResult] = []) {
        self.id = UUID()
        self.dateCreated = .now
        self.lastModified = .now
        self.players = players
        self.startingDealer = dealer
        self.history = history
    }
    
    enum CodingKeys: CodingKey {
        case id
        case dateCreated
        case lastModified
        case players
        case startingDealer
        case history
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
        players = try container.decode(Array<Player>.self, forKey: .players)
        startingDealer = try container.decode(Position.self, forKey: .startingDealer)
        history = try container.decode(Array<AuctionResult>.self, forKey: .history)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(dateCreated, forKey: .dateCreated)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(players, forKey: .players)
        try container.encode(startingDealer, forKey: .startingDealer)
        try container.encode(history, forKey: .history)
    }
    
    var currentDealer: Position {
        guard let lastResult = history.last else  {
            return startingDealer
        }
        return lastResult.dealer.next
    }
    
    var isFinished: Bool {
        guard let last = self.games.last else { return false }
        if case .rubber = last { return true }
        return false
    }
    
    func isVulnerable(_ team: Team) -> Bool {
        games.vulnerableTeams.contains(team)
    }
    
    func player(at position: Position) -> String? {
        players.first(where: { $0.position == position})?.name
    }
    
    func addAuctionResult(_ result: AuctionResult) {
        history.append(result)
        lastModified = .now
    }
    
    func replaceContract(_ doomed: Contract, with result: AuctionResult) {
        guard let index = history.firstIndex(where: {
            guard case let .contract(_, contract) = $0 else { return false }
            return contract.id == doomed.id
        }) else { return }
        
        history.replaceSubrange(index...index, with: [result])
        _adjustContracts(from: index)
    }
    
    private func _adjustContracts(from index: Int) {
        guard index < history.endIndex else { return }
        
        var madeChanges = false
        let replacements = history.suffix(from: index).enumerated().map { index, result in
            guard case let .contract(a, c) = result else { return result }
        
            let games = history.prefix(upTo: index).games
            let isVulnerable = games.vulnerableTeams.contains(c.declarer.team)
            
            guard isVulnerable != c.vulnerable else { return result }
            var newContract = c
            newContract.vulnerable = isVulnerable
            madeChanges = true
            return .contract(a, newContract)
        }
        
        
        if madeChanges {
            let replaceRange = index..<history.endIndex
            history.replaceSubrange(replaceRange, with: replacements)
        }
    }
}

extension Collection where Element == AuctionResult, Index == Int {
    var games: [Game] {
        guard !self.isEmpty else { return []}
        var result: [Game] = [.none(0...)]
        var gameIndex = 0
        var start = 0
        var we = 0
        var they = 0
        for (index, hand) in self.enumerated() {
            guard case let .contract(_, contract) = hand else { continue }
            guard case let .bid(value, contract) = contract.scores.first(where: { $0.scoresUnderTheLine }) else { continue }
            if case .we = contract.declarer.team {
                we += value
            } else {
                they += value
            }
            if we >= 100 || they >= 100 {
                let game: Game = .complete(we >= 100 ? .we : .they, start...index)
                result[gameIndex] = game
                we = 0
                they = 0
                gameIndex += 1
                start = index + 1
                // Add the indicator that we have nothing on to the following game
                if start < self.endIndex {
                    result.append(.none(start...))
                }

            } else if we > 0 || they > 0 {
                let game: Game = .partial(start...)
                result[gameIndex] = game
            }
        }
        // Determine if a rubber has been achieved
        if result.count >= 2 {
            var we = 0
            var they = 0
            for (index, game) in result.enumerated() {
                if case let .complete(team, range) = game {
                    switch team {
                    case .we:
                        we += 1
                    case .they:
                        they += 1
                    }
                    if we == 2 || they == 2 {
                        result[index] = .rubber(team, range)
                        break
                    }
                }
            }
        }
        return result
    }
}

extension Rubber {
    
    var games: [Game] {
        history.games
    }

    var scores: [Score] {
        let games = history.games
        var scores = history.scores
        if case let .rubber(team, _) = games.last {
            scores.append(.rubber(games.count == 2 ? 700 : 500, team))
        }
        return scores
    }
    
    func scores(for team: Team) -> [Score] {
        scores.filter { $0.team == team }
    }
        
    func scoresForGame(_ game: Game) -> [Score] {
        switch game {
        case let .complete(_, range), let .rubber(_, range):
            return Array(history[range]).scores
        case let .partial(range), let .none(range):
            return Array(history[range]).scores
        }
    }
    
    func points(for team: Team) -> Points {
        scores.points(for: team)
    }
}

extension Rubber: Hashable {
    static func == (lhs: Rubber, rhs: Rubber) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
}

extension Rubber {
    static var mock: Rubber {
        Rubber(
            players: [
                Player(name: "Caty", position: .west),
                Player(name: "Nathan", position: .south),
                Player(name: "Sharon", position: .east),
                Player(name: "Larisa", position: .north)
            ],
            history: [
                .missDeal(.north),
                .contract(Auction(), Contract(level: 3, suit: .hearts, declarer: .north, tricksTaken: 11)), // made
                .contract(Auction(),Contract(level: 2, suit: .hearts, declarer: .west, tricksTaken: 9)), // made
                .contract(Auction(),Contract(level: 2, suit: .spades, declarer: .east, tricksTaken: 7)), // under
                .pass(Auction()),
                .contract(Auction(),Contract(level: 3, suit: .hearts, declarer: .south, tricksTaken: 8)), // under
                .contract(Auction(),Contract(level: 3, suit: .clubs, declarer: .west, tricksTaken: 8)), // under
                .contract(Auction(),Contract(level: 2, suit: .hearts, declarer: .west, tricksTaken: 6)), // under
                .pass(Auction()),
                .contract(Auction(),Contract(level: 2, suit: .hearts, declarer: .east, tricksTaken: 9)), // made, game
                .contract(Auction(),Contract(level: 2, suit: .notrump, declarer: .east, tricksTaken: 8, vulnerable: true)), // made
                .contract(Auction(),Contract(level: 3, suit: .spades, declarer: .north, tricksTaken: 9)), // made
//                .contract(Auction(),Contract(level: 1, suit: .notrump, declarer: .east, tricksTaken: 9, vulnerable: true)), // made, game
            ]
        )
    }
}

