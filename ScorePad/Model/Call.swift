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

        // Coding keys mirror the synthesized format (case name → nested keyed container).
        private enum TopKey: String, CodingKey {
            case pending, pass, bid, double, redouble
        }
        // Associated-value keys used by the synthesized encoder: "_0", "_1", …
        private enum AssocKey: String, CodingKey {
            case v0 = "_0", v1 = "_1"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: TopKey.self)
            if c.contains(.pending) {
                self = .pending
            } else if c.contains(.pass) {
                self = .pass
            } else if c.contains(.bid) {
                let assoc = try c.nestedContainer(keyedBy: AssocKey.self, forKey: .bid)
                // New format: _0 is a Bid struct {level, suit}
                // Old format: _0 is an Int (level), _1 is a Suit (rawValue)
                if let bid = try? assoc.decode(Bid.self, forKey: .v0) {
                    self = .bid(bid)
                } else {
                    let level = try assoc.decode(Int.self, forKey: .v0)
                    let suit  = try assoc.decode(Suit.self, forKey: .v1)
                    self = .bid(Bid(level, suit))
                }
            } else if c.contains(.double) {
                self = .double
            } else if c.contains(.redouble) {
                self = .redouble
            } else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown Call case"
                ))
            }
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: TopKey.self)
            switch self {
            case .pending:
                _ = c.nestedContainer(keyedBy: AssocKey.self, forKey: .pending)
            case .pass:
                _ = c.nestedContainer(keyedBy: AssocKey.self, forKey: .pass)
            case .bid(let bid):
                var assoc = c.nestedContainer(keyedBy: AssocKey.self, forKey: .bid)
                try assoc.encode(bid, forKey: .v0)
            case .double:
                _ = c.nestedContainer(keyedBy: AssocKey.self, forKey: .double)
            case .redouble:
                _ = c.nestedContainer(keyedBy: AssocKey.self, forKey: .redouble)
            }
        }
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
