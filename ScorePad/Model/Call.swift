//
//  Call.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/28/22.
//

import Foundation

struct Call: Identifiable, Codable {
    enum Call: Codable {
        case pending
        case pass
        case bid(Bid)
        case double
        case redouble
    }

    var id: UUID = UUID()
    var date: Date = Date()
    var position: Position
    var call: Self.Call

    var suit: Suit? {
        switch self.call {
        case let .bid(b):
            return b.suit
        default:
            return nil
        }
    }
    var level: Int? {
        switch self.call {
        case let .bid(b):
            return b.level
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
