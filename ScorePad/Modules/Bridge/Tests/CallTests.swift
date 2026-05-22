//
//  CallTests.swift
//  ScorePadTests

import XCTest
@testable import ScorePad

final class CallTests: XCTestCase {

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = .sortedKeys
        return e
    }()
    private let decoder = JSONDecoder()

    // MARK: - Helpers

    private func json<T: Encodable>(_ value: T) throws -> String {
        String(data: try encoder.encode(value), encoding: .utf8)!
    }

    private func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
        try decoder.decode(type, from: Data(string.utf8))
    }

    // MARK: - Current-format encoding

    /// Prints the live encoded form so we can confirm the format assumption.
    func testPrintCurrentEncodings() throws {
        print("pass  →", try json(Call.Call.pass))
        print("bid   →", try json(Call.Call.bid(Bid(3, .hearts))))
        print("dbl   →", try json(Call.Call.double))
        print("rdbl  →", try json(Call.Call.redouble))
        print("pend  →", try json(Call.Call.pending))
    }

    // MARK: - Roundtrip: current format

    func testPassRoundtrip() throws {
        let encoded = try encoder.encode(Call.Call.pass)
        let decoded = try decoder.decode(Call.Call.self, from: encoded)
        guard case .pass = decoded else { return XCTFail("Expected .pass, got \(decoded)") }
    }

    func testPendingRoundtrip() throws {
        let encoded = try encoder.encode(Call.Call.pending)
        let decoded = try decoder.decode(Call.Call.self, from: encoded)
        guard case .pending = decoded else { return XCTFail("Expected .pending, got \(decoded)") }
    }

    func testDoubleRoundtrip() throws {
        let encoded = try encoder.encode(Call.Call.double)
        let decoded = try decoder.decode(Call.Call.self, from: encoded)
        guard case .double = decoded else { return XCTFail("Expected .double, got \(decoded)") }
    }

    func testRedoubleRoundtrip() throws {
        let encoded = try encoder.encode(Call.Call.redouble)
        let decoded = try decoder.decode(Call.Call.self, from: encoded)
        guard case .redouble = decoded else { return XCTFail("Expected .redouble, got \(decoded)") }
    }

    func testBidRoundtrip() throws {
        let cases: [(Int, Suit)] = [(1, .clubs), (3, .hearts), (7, .notrump)]
        for (level, suit) in cases {
            let encoded = try encoder.encode(Call.Call.bid(Bid(level, suit)))
            let decoded = try decoder.decode(Call.Call.self, from: encoded)
            guard case .bid(let bid) = decoded else {
                return XCTFail("Expected .bid for \(level)\(suit), got \(decoded)")
            }
            XCTAssertEqual(bid.level, level, "level mismatch for \(level)\(suit)")
            XCTAssertEqual(bid.suit,  suit,  "suit mismatch for \(level)\(suit)")
        }
    }

    // MARK: - Migration: old bid(Int, Suit) format → new bid(Bid)

    /// The old synthesised encoder wrote bid(Int, Suit) as {"bid":{"_0":<level>,"_1":<suitRawValue>}}.
    func testBidMigrationFromOldFormat() throws {
        // Suit.hearts.rawValue == 2
        let oldJSON = #"{"bid":{"_0":3,"_1":2}}"#
        let decoded = try decode(Call.Call.self, from: oldJSON)
        guard case .bid(let bid) = decoded else {
            return XCTFail("Expected .bid, got \(decoded)")
        }
        XCTAssertEqual(bid.level, 3)
        XCTAssertEqual(bid.suit, .hearts)
    }

    func testBidMigrationAllSuits() throws {
        for suit in Suit.allCases {
            let oldJSON = #"{"bid":{"_0":4,"_1":\#(suit.rawValue)}}"#
            let decoded = try decode(Call.Call.self, from: oldJSON)
            guard case .bid(let bid) = decoded else {
                return XCTFail("Expected .bid for suit \(suit)")
            }
            XCTAssertEqual(bid.level, 4)
            XCTAssertEqual(bid.suit, suit)
        }
    }

    func testBidMigrationAllLevels() throws {
        for level in 1...7 {
            let oldJSON = #"{"bid":{"_0":\#(level),"_1":3}}"# // spades
            let decoded = try decode(Call.Call.self, from: oldJSON)
            guard case .bid(let bid) = decoded else {
                return XCTFail("Expected .bid for level \(level)")
            }
            XCTAssertEqual(bid.level, level)
            XCTAssertEqual(bid.suit, .spades)
        }
    }

    // MARK: - Full Call struct roundtrip

    func testFullCallRoundtrip() throws {
        let original = Call(id: UUID(), date: .now, position: .south, call: .bid(Bid(4, .spades)))
        let encoded  = try encoder.encode(original)
        let decoded  = try decoder.decode(Call.self, from: encoded)
        XCTAssertEqual(decoded.id,       original.id)
        XCTAssertEqual(decoded.position, original.position)
        guard case .bid(let bid) = decoded.call else {
            return XCTFail("Expected .bid")
        }
        XCTAssertEqual(bid.level, 4)
        XCTAssertEqual(bid.suit,  .spades)
    }

    // MARK: - Auction roundtrip

    func testAuctionCallsRoundtrip() throws {
        let calls: [Call] = [
            Call(id: UUID(), date: .now, position: .north, call: .pass),
            Call(id: UUID(), date: .now, position: .east,  call: .bid(Bid(1, .diamonds))),
            Call(id: UUID(), date: .now, position: .south, call: .double),
            Call(id: UUID(), date: .now, position: .west,  call: .pass),
            Call(id: UUID(), date: .now, position: .north, call: .pass),
            Call(id: UUID(), date: .now, position: .east,  call: .pass),
        ]
        let auction = Auction(dealer: .north, calls: calls)
        let data    = try encoder.encode(auction)
        let decoded = try decoder.decode(Auction.self, from: data)

        XCTAssertEqual(decoded.calls.count, calls.count)
        guard case .bid(let bid) = decoded.calls[1].call else {
            return XCTFail("Expected .bid at index 1")
        }
        XCTAssertEqual(bid.level, 1)
        XCTAssertEqual(bid.suit,  .diamonds)
        guard case .double = decoded.calls[2].call else {
            return XCTFail("Expected .double at index 2")
        }
    }

    // MARK: - Auction migration from old Call format

    func testAuctionCallsMigrationFromOldFormat() throws {
        // Encode an Auction manually with old-format bid JSON embedded.
        // Position.north.rawValue == 0, Position.east.rawValue == 1
        // Suit.spades.rawValue == 3
        let oldAuctionJSON = #"""
        {
          "dealer": 0,
          "bidder": 2,
          "calls": [
            {"id":"00000000-0000-0000-0000-000000000001","date":0,"position":0,"call":{"pass":{}}},
            {"id":"00000000-0000-0000-0000-000000000002","date":0,"position":1,"call":{"bid":{"_0":4,"_1":3}}},
            {"id":"00000000-0000-0000-0000-000000000003","date":0,"position":2,"call":{"pass":{}}},
            {"id":"00000000-0000-0000-0000-000000000004","date":0,"position":3,"call":{"pass":{}}}
          ]
        }
        """#
        let decoded = try decode(Auction.self, from: oldAuctionJSON)
        XCTAssertEqual(decoded.calls.count, 4)
        guard case .bid(let bid) = decoded.calls[1].call else {
            return XCTFail("Expected .bid at index 1, got \(decoded.calls[1].call)")
        }
        XCTAssertEqual(bid.level, 4)
        XCTAssertEqual(bid.suit, .spades)
    }
}
