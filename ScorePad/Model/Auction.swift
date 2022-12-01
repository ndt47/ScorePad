//
//  Auction.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/29/22.
//

import Foundation

struct Auction {
    var dealer: Position = .north
    var calls: [Call] = []
    var currentPosition: Position = .north
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
        case .double, .redouble: return true
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
}

extension Auction {
    mutating func pass() throws {
        try addCall(.init(position: currentPosition, call: .pass))
    }
    
    mutating func bid(level: Int, suit: Suit) throws {
        try addCall(.init(position: currentPosition, call: .bid(level, suit)))
    }
    
    mutating func double() throws {
        try addCall(.init(position: currentPosition, call: .double))
    }
    
    mutating func redouble() throws {
        try addCall(.init(position: currentPosition, call: .redouble))
    }
}

fileprivate extension Auction {
    enum CallError: Error {
        case invalidBid
        case invalidDouble
        case invalidRedouble
        case biddingClosed
    }
    
    mutating func appendPasses(from start: Position, through end: Position) {
        var current = start;
        while current != end.next {
            calls.append(Call(position: current, call: .pass))
            current = current.next
        }
    }
    
    mutating func addCall(_ call: Call) throws {
        let lastCaller = calls.last?.position ?? dealer
        if lastCaller != call.position.previous {
            // Append passes up to the current position
            appendPasses(from: lastCaller, through: call.position.previous)
        }
        switch call.call {
        case .pass: break // no validation needed, can always pass
        case let .bid(level, suit):
            if let lastLevel = lastBid?.level, let lastSuit = lastBid?.suit {
                guard 0 < level, level <= 7 else {
                    throw CallError.invalidBid
                }
                guard level > lastLevel || (level == lastLevel && suit > lastSuit) else {
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
        currentPosition = call.position.next
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

