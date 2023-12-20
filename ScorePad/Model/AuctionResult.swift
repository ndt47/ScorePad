//
//  AuctionResult.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/20/23.
//

import Foundation

enum AuctionResult: ScoreProviding, Codable {
    case missDeal(Position)
    case pass(Auction)
    case contract(Auction, Contract)
    
    var dealer: Position {
        switch self {
        case let .missDeal(dealer):
            return dealer
        case let .pass(auction), let .contract(auction, _):
            return auction.dealer
        }
    }
    
    var scores: [Score] {
        switch self {
        case .missDeal, .pass: return []
        case let .contract(_, contract): return contract.scores
        }
    }
}
