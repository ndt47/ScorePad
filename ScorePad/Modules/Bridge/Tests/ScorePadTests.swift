//
//  ScorePadTests.swift
//  ScorePadTests
//

import XCTest
@testable import ScorePad

// MARK: - Position

final class PositionTests: XCTestCase {
    func testNextCycle() {
        XCTAssertEqual(Position.north.next, .east)
        XCTAssertEqual(Position.east.next,  .south)
        XCTAssertEqual(Position.south.next, .west)
        XCTAssertEqual(Position.west.next,  .north)
    }

    func testPreviousCycle() {
        XCTAssertEqual(Position.north.previous, .west)
        XCTAssertEqual(Position.east.previous,  .north)
        XCTAssertEqual(Position.south.previous, .east)
        XCTAssertEqual(Position.west.previous,  .south)
    }

    func testNextPreviousAreInverses() {
        for p in Position.allCases {
            XCTAssertEqual(p.next.previous, p)
            XCTAssertEqual(p.previous.next, p)
        }
    }

    func testTeam() {
        XCTAssertEqual(Position.north.team, .we)
        XCTAssertEqual(Position.south.team, .we)
        XCTAssertEqual(Position.east.team,  .they)
        XCTAssertEqual(Position.west.team,  .they)
    }

    func testDummy() {
        XCTAssertEqual(Position.north.dummy, .south)
        XCTAssertEqual(Position.south.dummy, .north)
        XCTAssertEqual(Position.east.dummy,  .west)
        XCTAssertEqual(Position.west.dummy,  .east)
    }

    func testDummyIsSelf() {
        for p in Position.allCases {
            XCTAssertEqual(p.dummy.dummy, p)
        }
    }

    func testComparable() {
        XCTAssertLessThan(Position.north, .east)
        XCTAssertLessThan(Position.east,  .south)
        XCTAssertLessThan(Position.south, .west)
        XCTAssertGreaterThan(Position.west, .north)
    }

    func testLabels() {
        XCTAssertEqual(Position.north.label, "North")
        XCTAssertEqual(Position.east.label,  "East")
        XCTAssertEqual(Position.south.label, "South")
        XCTAssertEqual(Position.west.label,  "West")
    }

    func testAllCases() {
        XCTAssertEqual(Position.allCases.count, 4)
        XCTAssertTrue(Position.allCases.contains(.north))
        XCTAssertTrue(Position.allCases.contains(.east))
        XCTAssertTrue(Position.allCases.contains(.south))
        XCTAssertTrue(Position.allCases.contains(.west))
    }

    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for p in Position.allCases {
            let data = try encoder.encode(p)
            let decoded = try decoder.decode(Position.self, from: data)
            XCTAssertEqual(decoded, p)
        }
    }
}

// MARK: - Team

final class TeamTests: XCTestCase {
    func testOpponent() {
        XCTAssertEqual(Team.we.opponent,   .they)
        XCTAssertEqual(Team.they.opponent, .we)
    }

    func testOpponentIsInvolution() {
        for t in Team.allCases {
            XCTAssertEqual(t.opponent.opponent, t)
        }
    }

    func testPositions() {
        XCTAssertEqual(Set(Team.we.positions),   [.north, .south])
        XCTAssertEqual(Set(Team.they.positions), [.east, .west])
    }

    func testPositionsAndTeamAreConsistent() {
        for t in Team.allCases {
            for p in t.positions {
                XCTAssertEqual(p.team, t, "\(p) should belong to \(t)")
            }
        }
    }

    func testLabels() {
        XCTAssertEqual(Team.we.label,   "We")
        XCTAssertEqual(Team.they.label, "They")
    }

    func testAllCases() {
        XCTAssertEqual(Team.allCases.count, 2)
    }

    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for t in Team.allCases {
            let data = try encoder.encode(t)
            let decoded = try decoder.decode(Team.self, from: data)
            XCTAssertEqual(decoded, t)
        }
    }
}

// MARK: - Suit

final class SuitTests: XCTestCase {
    func testOrdering() {
        XCTAssertLessThan(Suit.clubs,    .diamonds)
        XCTAssertLessThan(Suit.diamonds, .hearts)
        XCTAssertLessThan(Suit.hearts,   .spades)
        XCTAssertLessThan(Suit.spades,   .notrump)
    }

    func testOrderingTransitive() {
        XCTAssertLessThan(Suit.clubs,   .hearts)
        XCTAssertLessThan(Suit.clubs,   .notrump)
        XCTAssertLessThan(Suit.diamonds,.spades)
    }

    func testPointsMinorSuits() {
        // Clubs: 20 per trick
        XCTAssertEqual(Suit.clubs.points(for: 1), 20)
        XCTAssertEqual(Suit.clubs.points(for: 3), 60)
        XCTAssertEqual(Suit.clubs.points(for: 5), 100)
        // Diamonds: 20 per trick
        XCTAssertEqual(Suit.diamonds.points(for: 1), 20)
        XCTAssertEqual(Suit.diamonds.points(for: 3), 60)
        XCTAssertEqual(Suit.diamonds.points(for: 5), 100)
    }

    func testPointsMajorSuits() {
        // Hearts: 30 per trick
        XCTAssertEqual(Suit.hearts.points(for: 1), 30)
        XCTAssertEqual(Suit.hearts.points(for: 3), 90)
        XCTAssertEqual(Suit.hearts.points(for: 4), 120)
        // Spades: 30 per trick
        XCTAssertEqual(Suit.spades.points(for: 1), 30)
        XCTAssertEqual(Suit.spades.points(for: 4), 120)
    }

    func testPointsNoTrump() {
        // NT: 40 for first trick, 30 each subsequent
        XCTAssertEqual(Suit.notrump.points(for: 1), 40)
        XCTAssertEqual(Suit.notrump.points(for: 2), 70)
        XCTAssertEqual(Suit.notrump.points(for: 3), 100)
        XCTAssertEqual(Suit.notrump.points(for: 6), 190)
        XCTAssertEqual(Suit.notrump.points(for: 7), 220)
    }

    func testPointsOvertrickRateIsFlat() {
        // When over: true, NT uses flat 30/trick rate (same as other tricks above 1)
        XCTAssertEqual(Suit.notrump.points(for: 1, over: true), 30)
        XCTAssertEqual(Suit.notrump.points(for: 2, over: true), 60)
        // Minor suits unchanged
        XCTAssertEqual(Suit.clubs.points(for: 1, over: true), 20)
        // Major suits unchanged
        XCTAssertEqual(Suit.hearts.points(for: 1, over: true), 30)
    }

    func testPointsInvalidRange() {
        // Out-of-range returns 0
        XCTAssertEqual(Suit.clubs.points(for: 0), 0)
        XCTAssertEqual(Suit.hearts.points(for: 8), 0)
    }

    func testNext() {
        XCTAssertEqual(Suit.clubs.next,    .diamonds)
        XCTAssertEqual(Suit.diamonds.next, .hearts)
        XCTAssertEqual(Suit.hearts.next,   .spades)
        XCTAssertEqual(Suit.spades.next,   .notrump)
        XCTAssertNil(Suit.notrump.next)
    }

    func testAllCases() {
        XCTAssertEqual(Suit.allCases.count, 5)
        XCTAssertTrue(Suit.allCases.contains(.clubs))
        XCTAssertTrue(Suit.allCases.contains(.notrump))
    }

    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for s in Suit.allCases {
            let data = try encoder.encode(s)
            let decoded = try decoder.decode(Suit.self, from: data)
            XCTAssertEqual(decoded, s)
        }
    }
}

// MARK: - Bid

final class BidTests: XCTestCase {
    func testInit() {
        let b = Bid(3, .hearts)
        XCTAssertEqual(b.level, 3)
        XCTAssertEqual(b.suit, .hearts)
    }

    func testLabeledInit() {
        let b = Bid(level: 4, suit: .spades)
        XCTAssertEqual(b.level, 4)
        XCTAssertEqual(b.suit, .spades)
    }

    func testComparableSameLevelDifferentSuit() {
        XCTAssertLessThan(Bid(2, .clubs),    Bid(2, .diamonds))
        XCTAssertLessThan(Bid(2, .diamonds), Bid(2, .hearts))
        XCTAssertLessThan(Bid(2, .hearts),   Bid(2, .spades))
        XCTAssertLessThan(Bid(2, .spades),   Bid(2, .notrump))
    }

    func testComparableDifferentLevel() {
        XCTAssertLessThan(Bid(1, .notrump), Bid(2, .clubs))
        XCTAssertLessThan(Bid(3, .spades),  Bid(4, .clubs))
        XCTAssertGreaterThan(Bid(7, .clubs),  Bid(6, .notrump))
    }

    func testAllBidsCount() {
        XCTAssertEqual(Bid.allBids.count, 35)  // 7 levels × 5 suits
    }

    func testAllBidsAreSorted() {
        let bids = Bid.allBids
        for i in 0..<(bids.count - 1) {
            XCTAssertLessThan(bids[i], bids[i + 1])
        }
    }

    func testAllBidsLowestAndHighest() {
        XCTAssertEqual(Bid.allBids.first, Bid(1, .clubs))
        XCTAssertEqual(Bid.allBids.last,  Bid(7, .notrump))
    }

    func testIDIsValue() {
        let b = Bid(3, .hearts)
        XCTAssertEqual(b.id, b.value)
    }

    func testInitFromID() {
        for bid in Bid.allBids {
            let reconstructed = Bid(id: bid.id)
            XCTAssertEqual(reconstructed.level, bid.level)
            XCTAssertEqual(reconstructed.suit,  bid.suit)
        }
    }

    func testHashable() {
        let set: Set<Bid> = [Bid(1, .clubs), Bid(1, .clubs), Bid(2, .hearts)]
        XCTAssertEqual(set.count, 2)
    }

    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for bid in Bid.allBids {
            let data = try encoder.encode(bid)
            let decoded = try decoder.decode(Bid.self, from: data)
            XCTAssertEqual(decoded, bid)
        }
    }
}

// MARK: - Player

final class PlayerTests: XCTestCase {
    func testCodable() throws {
        let player = Player(name: "Alice", position: .north)
        let data = try JSONEncoder().encode(player)
        let decoded = try JSONDecoder().decode(Player.self, from: data)
        XCTAssertEqual(decoded.name,     "Alice")
        XCTAssertEqual(decoded.position, .north)
    }
}
