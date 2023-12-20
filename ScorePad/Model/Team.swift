//
//  Team.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/20/23.
//

import Foundation

enum Team: CaseIterable, Codable {
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

