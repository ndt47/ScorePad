//
//  Score.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/28/22.
//

import Foundation

enum Score: Identifiable {
    var id: UUID { .init() }
    
    // under the line
    case bid(Int, Contract)
    // over the line
    case over(Int, Contract)
    case under(Int, Contract)
    case slam(Int, Contract)
    case honors(Int, Team, Contract)
    case rubber(Int, Team)
}

extension Score {
    var value: Int {
        switch self {
        case let .bid(v, _), let .over(v, _), let .under(v, _), let .slam(v, _), let .honors(v, _, _), let .rubber(v, _):
            return v
        }
    }
    
    var contract: Contract? {
        switch self {
        case let .bid(_, c), let .over(_, c), let .under(_, c), let .slam(_, c), let .honors(_, _, c):
            return c
        case .rubber:
            return nil
        }
    }
    
    var team: Team {
        switch self {
        case let .bid(_, c), let .over(_, c), let .under(_, c), let .slam(_, c):
            return c.declarer.team
        case let .honors(_, t, _), let .rubber(_, t):
            return t
        }
    }
    
    var scoresUnderTheLine: Bool {
        guard case .bid = self else { return false }
        return true
    }
    
    var scoresOverTheLine: Bool {
        !scoresUnderTheLine
    }

}

extension Suit {
    func points(for result: Int, over: Bool = false) -> Int {
        guard result > 0, result < 7 else { return 0 }
        switch self {
        case .clubs, .diamonds: return result * 20
        case .hearts, .spades: return result * 30
        case .notrump: return  over ? 30 * result : 40 + 30 * (result - 1)
        }
    }
}

extension Contract {
    var overtrickValue: Int {
        if redoubled {
            return vulnerable ? 400 : 200
        } else if doubled {
            return vulnerable ? 200 : 100
        } else {
            return suit.points(for: 1, over: true)
        }
    }

    var scores: [Score] {
        var scores = [Score]()

        if result < 0 {
            // Undertricks
            var undertrickScore = 0
            var undertrickCount = 0 - result
            var undertrickValue = vulnerable ? 100 : 50
            if redoubled {
                undertrickScore = vulnerable ? 400 : 200
                undertrickValue = vulnerable ? 600 : 400
                undertrickCount -= 1
            } else if doubled {
                undertrickScore = vulnerable ? 200 : 100
                undertrickValue = vulnerable ? 300 : 200
                undertrickCount -= 1
            }
            if undertrickCount > 0 {
                undertrickScore += undertrickValue * undertrickCount
            }
            scores.append(.under(undertrickScore, self))
        } else {
            // Bid (result == 0 is making bid)
            let multiplier = redoubled ? 4 : doubled ? 2 : 1
            scores.append(.bid(suit.points(for: level) * multiplier, self))
            
            // Overtricks (result > 0 is overtricks)
            if result > 0 {
                scores.append(.over(result * overtrickValue, self))
            }
            
            // Slam bonus
            if level == 6 {
                scores.append(.slam(vulnerable ? 750 : 500, self))
            }
            if level == 7 {
                scores.append(.slam(vulnerable ? 1500 : 1000, self))
            }
        }
        // Honors (not required to make the bid)
        switch (honors) {
        case let .declarer(value):
            scores.append(.honors(value, declarer.team, self))
        case let .defender(value):
            scores.append(.honors(value, declarer.team.opponent, self))
        default: break
        }
        return scores
    }
}

struct Points {
    var above: Int = 0
    var below: Int = 0
    
    static func + (lhs: Points, rhs: Points) -> Points {
        .init(above: lhs.above + rhs.above,
              below: lhs.below + rhs.below)
    }
    
    mutating func addScore(_ score: Score) {
        switch score {
        case let .bid(value, _):
            below += value
        case let .over(value, _):
            above += value
        case let .under(value, _):
            above += value
        case let .honors(value, _, _):
            above += value
        case let .slam(value, _):
            above += value
        case let .rubber(value, _):
            above += value
        }
    }
}

protocol PointsCalculating {
    var points: (we: Points, they: Points) { get }
    func points(for team: Team) -> Points
}


extension Collection where Element == Contract {
    var scores: [Score] {
        reduce([]) { partialResult, contract in
            partialResult + contract.scores
        }
    }
    
    var points: (we: Points, they: Points) {
        reduce((Points(), Points())) { partial, contract in
            let points = contract.scores.points
            return (we: partial.we + points.we,
                    they: partial.they + points.they)
        }
    }
    
    func points(for team: Team) -> Points {
        reduce(Points()) { partial, contract in
            partial + contract.scores.points(for: team)
        }
    }
}

extension Collection where Element == Score {
    var points: (we: Points, they: Points) {
       reduce((Points(), Points())) { partial, score in
           var points = partial
           let addScoreForTeam: (Score, Team) -> Void = { score, team in
               switch team {
               case .we:
                   points.we.addScore(score)
               case .they:
                   points.they.addScore(score)
               }
           }
           switch score {
           case let .bid(_, contract), let .over(_, contract), let .slam(_, contract):
               addScoreForTeam(score, contract.declarer.team)
           case let .under(_, contract):
               addScoreForTeam(score, contract.declarer.team.opponent)
           case let .honors(_, team, _), let .rubber(_, team):
               addScoreForTeam(score, team)
           }
           return points
        }
    }
    
    func points(for team: Team) -> Points {
        reduce(Points()) { partial, score in
            var points = partial
            let addScoreForTeam: (Score, Team) -> Void = { score, t in
                if t == team {
                    points.addScore(score)
                }
            }
            switch score {
            case let .bid(_, contract), let .over(_, contract), let .slam(_, contract):
                addScoreForTeam(score, contract.declarer.team)
            case let .under(_, contract):
                addScoreForTeam(score, contract.declarer.team.opponent)
            case let .honors(_, team, _), let .rubber(_, team):
                addScoreForTeam(score, team)
            }
            return points
        }
    }
    
    func forTeam(_ team: Team) -> [Score] {
        filter { $0.team == team }
    }
    
    func underTheLine() -> [Score] {
        filter { $0.scoresUnderTheLine }
    }
    
    func overTheLine() -> [Score] {
        filter { $0.scoresOverTheLine }
    }
}

