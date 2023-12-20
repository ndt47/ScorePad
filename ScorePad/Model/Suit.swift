//
//  Suit.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/20/23.
//

import Foundation

enum Suit: Int, CaseIterable, Comparable, Strideable, Codable {
    typealias Stride = RawValue
    
    case clubs = 0
    case diamonds
    case hearts
    case spades
    case notrump
    
    static func < (lhs: Suit, rhs: Suit) -> Bool {
        switch rhs {
        case .clubs: return false
        case .diamonds:
            switch lhs {
            case .clubs: return true
            default: return false
            }
        case .hearts:
            switch lhs {
            case .clubs, .diamonds: return true
            default: return false
            }
        case .spades:
            switch lhs {
            case .clubs, .diamonds, .hearts: return true
            default: return false
            }
        case .notrump:
            switch lhs {
            case .clubs, .diamonds, .hearts, .spades: return true
            default: return false
            }
        }
    }
    
    var next: Suit? {
        Suit(rawValue: self.rawValue + 1)
    }
    
    func distance(to other: Suit) -> Int {
        other.rawValue - self.rawValue
    }
    
    func advanced(by n: Int) -> Suit {
        let inc = (n % Suit.notrump.rawValue)
        return Suit(rawValue: self.rawValue + inc) ?? .clubs.advanced(by: inc - 1)
    }
}
