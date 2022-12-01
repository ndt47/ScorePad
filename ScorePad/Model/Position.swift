//
//  Position.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/28/22.
//

import Foundation

enum Position: Int, Comparable {
    case north = 0
    case east = 1
    case south = 2
    case west = 3
    
    var previous: Position {
        switch self {
        case .north: return .west
        case .east: return .north
        case .south: return .east
        case .west: return .south
        }
    }
    
    var next: Position {
        switch self {
        case .north: return .east
        case .east: return .south
        case .south: return .west
        case .west: return .north
        }
    }
    
    var team: Team {
        switch self {
        case .north, .south: return .we
        case .east, .west: return .they
        }
    }
    
    var dummy: Position {
        switch self {
        case .north: return .south
        case .east: return .west
        case .south: return .north
        case .west: return .east
        }
    }
    
    static func < (lhs: Position, rhs: Position) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Position {
    var label: String {
        switch self {
        case .north:
            return "North"
        case .east:
            return "East"
        case .south:
            return "South"
        case .west:
            return "West"
        }
    }

}
