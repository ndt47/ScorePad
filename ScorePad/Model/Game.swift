//
//  Game.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/20/23.
//

import Foundation

enum Game: Identifiable, Codable {
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

