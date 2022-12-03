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

struct Player {
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

class Rubber: ObservableObject, Identifiable {
    let id: UUID = UUID()
    let dateCreated = Date()
    var lastModified = Date()
    var players: [Player] = []
    let startingDealer: Position
    @Published var history: [AuctionResult] = []

    init(players: [Player] = [], dealer: Position = .north, history: [AuctionResult] = []) {
        self.players = players
        self.startingDealer = dealer
        self.history = history
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
    
    func addContract(_ contract: Contract) {
        var contract = contract
        contract.vulnerable = isVulnerable(contract.declarer.team)
        history.append(.contract(contract.auction, contract))
        lastModified = Date()
    }
    
    func addMissDeal(_ dealer: Position) {
        history.append(.missDeal(dealer))
        lastModified = Date()
    }
    
    func addPassHand(_ auction: Auction) {
        history.append(.pass(auction))
        lastModified = Date()
    }
    
    var games: [Game] {
        guard !history.isEmpty else { return []}
        var result: [Game] = [.none(0...)]
        var gameIndex = 0
        var start = 0
        var we = 0
        var they = 0
        for (index, hand) in history.enumerated() {
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
                if start < history.endIndex {
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
        print("\(result)")
        return result
    }

    var scores: [Score] {
        let games = games
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
