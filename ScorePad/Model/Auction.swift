//
//  Auction.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/29/22.
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

class Auction: ObservableObject, Codable {
    let dealer: Position
    @Published var bidder: Position
    @Published var calls: [Call]
    
    init(dealer: Position = .north, calls: [Call] = []) {
        self.calls = calls
        self.dealer = dealer
        self.bidder = dealer
    }
    
    enum CodingKeys: CodingKey {
        case dealer
        case bidder
        case calls
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dealer = try container.decode(Position.self, forKey: .dealer)
        bidder = try container.decode(Position.self, forKey: .bidder)
        calls = try container.decode(Array<Call>.self, forKey: .calls)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dealer, forKey: .dealer)
        try container.encode(bidder, forKey: .bidder)
        try container.encode(calls, forKey: .calls)
    }
}

extension Auction {
    var lastBid: Call? { calls.lastBid() }
    var declarer: Position? {
        guard let call = lastBid else { return nil }
        let suitBids = calls.filter { call.position.team == $0.position.team }.filter { $0.followsSuit(of: call) }
        return suitBids.first?.position
    }
    var level: Int? { lastBid?.level }
    var suit: Suit? { lastBid?.suit }
    var doubled: Bool {
        guard let lastCall = calls.excludingPasses().last else { return false }
        switch lastCall.call {
        case .double: return true
        default: return false
        }
    }
    var redoubled: Bool {
        guard let lastCall = calls.excludingPasses().last else { return false }
        switch lastCall.call {
        case .redouble: return true
        default: return false
        }
    }
    
    var closed: Bool {
        var suffix = calls.suffix(4)
        guard suffix.count == 4 else { return false }
        // If we have four passes, this is a passed contract
        if suffix.allPasses() {  return true }
        // If the first is a non-pass, and is followed by three passes, then the contract
        // is closed
        else if let first = suffix.popFirst(), !first.isPass, suffix.allPasses() { return true }
        return false
    }
    
    var isPassHand: Bool {
        calls.allPasses()
    }
    
    func canDouble(by position: Position) -> Bool {
        guard let lastCall = calls.excludingPasses().last,
              case .bid = lastCall.call,
              lastCall.position.team != position.team else { return false }
        return true
    }
    
    func canRedouble(by position: Position) -> Bool {
        guard let lastCall = calls.excludingPasses().last,
              case .double = lastCall.call,
              lastCall.position.team != position.team else { return false }
        return true
    }
    
    var canRemoveLast: Bool {
        calls.count > 0
    }
}

extension Auction {
    func pass() {
        guard !closed else { return }
        do {
            try addCall(.init(position: bidder, call: .pass))
        } catch {
            print(String(describing: error))
        }
    }
    
    func bid(level: Int, suit: Suit) {
        guard !closed else { return }
        do {
            try addCall(.init(position: bidder, call: .bid(level, suit)))
        } catch {
            print(String(describing: error))
        }
    }
    
    func double() {
        guard !closed else { return }
        do {
            try addCall(.init(position: bidder, call: .double))
        } catch {
            print(String(describing: error))
        }
    }
    
    func redouble() {
        guard !closed else { return }
        do {
            try addCall(.init(position: bidder, call: .redouble))
        } catch {
            print(String(describing: error))
        }
    }
    
    func close() {
        do {
            while !closed {
                try addCall(.init(position: bidder, call: .pass))
            }
        } catch {
            print(String(describing: error))
        }
    }
    
    func undoLast() {
        do {
            try removeLastCall()
        } catch {}
    }
}

fileprivate extension Auction {
    enum CallError: Error {
        case pendingCall
        case invalidBid
        case invalidDouble
        case invalidRedouble
        case biddingClosed
        case cannotRemove
    }
    
    func appendPasses(from start: Position, through end: Position) {
        var current = start;
        while current != end.next {
            calls.append(Call(position: current, call: .pass))
            current = current.next
        }
    }
    
    func addCall(_ call: Call) throws {
        guard !closed else { throw CallError.biddingClosed }
        
        let lastCaller = calls.last?.position ?? dealer
        if lastCaller != call.position.previous {
            // Append passes up to the current position
            appendPasses(from: lastCaller, through: call.position.previous)
        }
        switch call.call {
        case .pending:
            throw CallError.pendingCall
        case .pass: break // no validation needed, can always pass
        case let .bid(level, suit):
            if let lastLevel = lastBid?.level, let lastSuit = lastBid?.suit {
                guard 0 < level, level <= 7 else {
                    throw CallError.invalidBid
                }
                guard level > lastLevel || suit > lastSuit else {
                    throw CallError.invalidBid
                }
            }
        case .double:
            guard let lastBid = lastBid, lastBid.position.team != call.position.team else {
                // Can't double our own team's bid
                throw CallError.invalidDouble
            }
        case .redouble:
            guard let lastCall = calls.last, case .double = lastCall.call, lastCall.position.team != call.position.team else {
                throw CallError.invalidRedouble
            }
        }
        
        calls.append(call)
        bidder = call.position.next
    }
    
    func removeLastCall() throws {
        guard !calls.isEmpty else { throw CallError.cannotRemove }
        if let call = calls.popLast() {
            bidder = call.position
        }
    }
    
    func countTrailingPasses() -> Int {
        var count = 0
        for value in calls.enumerated().reversed() {
            switch value.element.call {
            case .pass:
                count += 1
            default:
                return count
            }
        }
        return count
    }
}

