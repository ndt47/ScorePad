//
//  Score.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/28/22.
//

import Foundation

protocol ScoreProviding {
    var scores: [Score] { get }
}

protocol PointsCalculating {
    var points: (we: Points, they: Points) { get }
    func points(for team: Team) -> Points
}

enum Score: Identifiable {
    var id: UUID { .init() }
    
    // under the line
    case bid(Int, Contract)
    // over the line
    case over(Int, Contract)
    case insult(Int, Contract)
    case under(Int, Contract)
    case slam(Int, Contract)
    case honors(Int, Team, Contract)
    case rubber(Int, Team)
}

extension Score {
    var value: Int {
        switch self {
        case let .bid(v, _), let .over(v, _), let .insult(v, _), let .under(v, _), let .slam(v, _), let .honors(v, _, _), let .rubber(v, _):
            return v
        }
    }
    
    var contract: Contract? {
        switch self {
        case let .bid(_, c), let .over(_, c), let .insult(_, c), let .under(_, c), let .slam(_, c), let .honors(_, _, c):
            return c
        case .rubber:
            return nil
        }
    }
    
    var team: Team {
        switch self {
        case let .bid(_, c), let .over(_, c), let .insult(_, c), let .under(_, c), let .slam(_, c):
            return c.declarer.team
        case let .honors(_, t, _), let .rubber(_, t):
            return t
        }
    }
    
    var label: String {
        switch self {
        case let .bid(_, contract):
            return contract.doublingLabel.trimmingCharacters(in: .whitespaces)
        case let .over(_, contract):
            return "OVER\(contract.doublingLabel)"
        case .insult:
            return "INSULT"
        case let .under(_, contract):
            return "UNDER\(contract.doublingLabel)"
        case .slam:
            return "SLAM"
        case .honors:
            return "HONORS"
        case .rubber:
            return "RUBBER"
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
        guard result > 0, result <= 7 else { return 0 }
        switch self {
        case .clubs, .diamonds: return result * 20
        case .hearts, .spades: return result * 30
        case .notrump: return  over ? 30 * result : 40 + 30 * (result - 1)
        }
    }
}

extension Contract: ScoreProviding {
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
            let undertrickCount = 0 - result
            let undertrickScore: Int
            if redoubled {
                if vulnerable {
                    undertrickScore = 400 + max(0, undertrickCount - 1) * 600
                } else {
                    let subsequent = undertrickCount - 1
                    undertrickScore = 200 + min(subsequent, 2) * 400 + max(0, subsequent - 2) * 600
                }
            } else if doubled {
                if vulnerable {
                    undertrickScore = 200 + max(0, undertrickCount - 1) * 300
                } else {
                    let subsequent = undertrickCount - 1
                    undertrickScore = 100 + min(subsequent, 2) * 200 + max(0, subsequent - 2) * 300
                }
            } else {
                undertrickScore = undertrickCount * (vulnerable ? 100 : 50)
            }
            scores.append(.under(undertrickScore, self))
        } else {
            // Bid (result == 0 is making bid)
            let multiplier = redoubled ? 4 : doubled ? 2 : 1
            scores.append(.bid(suit.points(for: level) * multiplier, self))

            // Insult bonus for making a doubled or redoubled contract
            if redoubled {
                scores.append(.insult(100, self))
            } else if doubled {
                scores.append(.insult(50, self))
            }

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
        case .declarer100, .declarer150:
            scores.append(.honors(honors.points, declarer.team, self))
        case .defender100, .defender150:
            scores.append(.honors(honors.points, declarer.team.opponent, self))
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
        case let .over(value, _), let .insult(value, _):
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
    
    var total: Int {
        above + below
    }
}

extension Array: ScoreProviding, PointsCalculating where Element: ScoreProviding {
    var scores: [Score] {
        reduce([]) { partialResult, element in
            partialResult + element.scores
        }
    }

    var points: (we: Points, they: Points) {
        reduce((Points(), Points())) { partial, element in
            let points = element.scores.points
            return (we: partial.we + points.we,
                    they: partial.they + points.they)
        }
    }
    
    func points(for team: Team) -> Points {
        reduce(Points()) { partial, element in
            partial + element.scores.points(for: team)
        }
    }
}

extension Array where Element == Score {
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
           case let .bid(_, contract), let .over(_, contract), let .insult(_, contract), let .slam(_, contract):
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
            case let .bid(_, contract), let .over(_, contract), let .insult(_, contract), let .slam(_, contract):
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
        filter {
            if case .under = $0 {
                return $0.team.opponent == team
            }
            return $0.team == team }
    }
    
    func underTheLine() -> [Score] {
        filter { $0.scoresUnderTheLine }
    }
    
    func overTheLine() -> [Score] {
        filter { $0.scoresOverTheLine }
    }
}

