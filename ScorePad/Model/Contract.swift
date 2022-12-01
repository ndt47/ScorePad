//
//  Contract.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/28/22.
//

import Foundation

struct Contract {
    enum Honors: Equatable {
        case none
        case declarer(Int)
        case defender(Int)
    }
    
    var auction: Auction
    var level: Int
    var suit: Suit
    var declarer: Position
    var doubled: Bool
    var redoubled: Bool
    var honors: Honors = .none
    var tricksTaken: Int = 0
    
    // Properties set when the contract is registered
    var vulnerable: Bool = false
    var date: Date = .now
    
    var result: Int {
        return tricksTaken - 6 - level
    }
    
    init?(auction: Auction, honors: Honors = .none, tricksTaken: Int = 0) {
        guard let level = auction.level,
              let suit = auction.suit,
              let declarer = auction.declarer else {
            return nil
        }
        self.auction = auction
        self.level = level
        self.suit = suit
        self.declarer = declarer
        self.doubled = auction.doubled
        self.redoubled = auction.redoubled
        self.honors = honors
        self.tricksTaken = tricksTaken
    }
    
    init(level: Int,
         suit: Suit,
         declarer: Position,
         doubled: Bool = false,
         redoubled: Bool = false,
         honors: Honors = .none,
         tricksTaken: Int,
         vulnerable: Bool = false) {
        self.auction = Auction()
        self.level = level
        self.suit = suit
        self.declarer = declarer
        self.doubled = auction.doubled
        self.redoubled = auction.redoubled
        self.honors = honors
        self.tricksTaken = tricksTaken
    }
}


