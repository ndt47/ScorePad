//
//  Bid.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/20/23.
//

import Foundation

struct Bid: Identifiable, Hashable, Codable, Comparable {
    var id: Int { value }
    
    static func < (lhs: Bid, rhs: Bid) -> Bool {
        lhs.value < rhs.value
    }
    
    var level: Int
    var suit: Suit
    
    internal var value: Int { (level * Suit.allCases.count) + suit.rawValue }
    
    static var allBids: [Self] {
        var bids: [Self] = .init()
        for level in 1...7 {
            for suit in Suit.allCases {
                bids.append(Bid(level, suit))
            }
        }
        return bids
    }
    
    init(_ level: Int, _ suit: Suit) {
        self.level = level
        self.suit = suit
    }
    
    init(level: Int, suit: Suit) {
        self.level = level
        self.suit = suit
    }
    
    init(id: ID) {
        var count = Suit.allCases.count
        self.level = id / count
        self.suit = Suit(rawValue: id % count)!
    }

    func hash(into hasher: inout Hasher) {
        level.hash(into: &hasher)
        suit.hash(into: &hasher)
    }
}
