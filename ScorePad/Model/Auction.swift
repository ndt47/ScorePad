//
//  Auction.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/29/22.
//

import Foundation

enum AuctionResult: ScoreProviding {
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

class Auction: ObservableObject {
    let dealer: Position
    @Published var calls: [Call]
    @Published var currentBidder: Position
    
    init(dealer: Position = .north, calls: [Call] = []) {
        self.calls = calls
        self.dealer = dealer
        self.currentBidder = dealer
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
}

extension Auction {
    func pass() {
        do {
            try addCall(.init(position: currentBidder, call: .pass))
        } catch {}
    }
    
    func bid(level: Int, suit: Suit) {
        do {
            try addCall(.init(position: currentBidder, call: .bid(level, suit)))
        } catch {}
    }
    
    func double() {
        do {
            try addCall(.init(position: currentBidder, call: .double))
        } catch {}
    }
    
    func redouble() {
        do {
            try addCall(.init(position: currentBidder, call: .redouble))
        } catch {}
    }
    
    func close() {
        do {
            while !closed {
                try addCall(.init(position: currentBidder, call: .pass))
            }
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
    }
    
    func appendPasses(from start: Position, through end: Position) {
        var current = start;
        while current != end.next {
            calls.append(Call(position: current, call: .pass))
            current = current.next
        }
    }
    
    func addCall(_ call: Call) throws {
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
        currentBidder = call.position.next
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

