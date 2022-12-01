//
//  Call.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/28/22.
//

import Foundation

enum Suit: Comparable {
    case clubs
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
}

struct Call {
    enum Call {
        case pass
        case bid(Int, Suit)
        case double
        case redouble
    }

    var position: Position
    var call: Self.Call

    var suit: Suit? {
        switch self.call {
        case let .bid(_, suit):
            return suit
        default:
            return nil
        }
    }
    var level: Int? {
        switch self.call {
        case let .bid(level, _):
            return level
        default:
            return nil
        }
    }
    var isPass: Bool {
        if case .pass = self.call { return true }
        return false
    }
    
    func followsSuit(of other: Self) -> Bool {
        guard let suit = self.suit, let otherSuit = other.suit else { return false }
        return suit == otherSuit
    }
}

extension Collection where Element == Call {
    func excludingPasses() -> [Call] {
        self.filter {
            if case .pass = $0.call {
                return false
            }
            return true
        }
    }
    
    func lastBid() -> Element? {
        for item in self.enumerated().reversed() {
            if case .bid = item.element.call {
                return item.element
            }
        }
        return nil
    }

    func allPasses() -> Bool {
        let passCount = reduce(0) { count, call in
            call.isPass ? count + 1 : count
        }
        return passCount == count
    }
}
