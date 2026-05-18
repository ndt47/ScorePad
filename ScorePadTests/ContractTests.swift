//
//  ContractTests.swift
//  ScorePadTests
//

import XCTest
@testable import ScorePad

// MARK: - Contract Init / Properties

final class ContractTests: XCTestCase {

    // MARK: - Init from Auction

    func testInitFromAuction() {
        let a = Auction(dealer: .north)
        a.bid(Bid(3, .hearts))
        a.close()

        let c = Contract(auction: a, tricksTaken: 9)
        XCTAssertNotNil(c)
        XCTAssertEqual(c?.level, 3)
        XCTAssertEqual(c?.suit, .hearts)
        XCTAssertEqual(c?.declarer, .north)
        XCTAssertFalse(c?.doubled ?? true)
        XCTAssertFalse(c?.redoubled ?? true)
    }

    func testInitFromAuctionDoubled() {
        let a = Auction(dealer: .north)
        a.bid(Bid(3, .hearts))
        a.double()   // east
        a.close()

        let c = Contract(auction: a, tricksTaken: 9)
        XCTAssertNotNil(c)
        XCTAssertTrue(c?.doubled ?? false)
        XCTAssertFalse(c?.redoubled ?? true)
    }

    func testInitFromAuctionRedoubled() {
        let a = Auction(dealer: .north)
        a.bid(Bid(3, .hearts))
        a.double()     // east
        a.redouble()   // south
        a.close()

        let c = Contract(auction: a, tricksTaken: 9)
        XCTAssertNotNil(c)
        XCTAssertFalse(c?.doubled ?? true)
        XCTAssertTrue(c?.redoubled ?? false)
    }

    func testInitFromAuctionReturnsNilWithNoBid() {
        let a = Auction()
        a.close()
        let c = Contract(auction: a, tricksTaken: 7)
        XCTAssertNil(c)
    }

    func testInitFromAuctionVulnerable() {
        let a = Auction(dealer: .north)
        a.bid(Bid(2, .spades))
        a.close()

        let c = Contract(auction: a, tricksTaken: 8, vulnerable: true)
        XCTAssertNotNil(c)
        XCTAssertTrue(c?.vulnerable ?? false)
    }

    // MARK: - Direct Init

    func testDirectInit() {
        let c = Contract(level: 4, suit: .spades, declarer: .south, tricksTaken: 10)
        XCTAssertEqual(c.level,     4)
        XCTAssertEqual(c.suit,      .spades)
        XCTAssertEqual(c.declarer,  .south)
        XCTAssertEqual(c.tricksTaken, 10)
        XCTAssertFalse(c.vulnerable)
    }

    // MARK: - Result

    func testResultMadeExactly() {
        // result = tricksTaken - 6 - level
        let c = Contract(level: 3, suit: .hearts, declarer: .north, tricksTaken: 9)
        XCTAssertEqual(c.result, 0)
    }

    func testResultOvertricks() {
        let c = Contract(level: 3, suit: .hearts, declarer: .north, tricksTaken: 11)
        XCTAssertEqual(c.result, 2)
    }

    func testResultUndertricks() {
        let c = Contract(level: 3, suit: .hearts, declarer: .north, tricksTaken: 7)
        XCTAssertEqual(c.result, -2)
    }

    func testResultLevel1Made() {
        let c = Contract(level: 1, suit: .clubs, declarer: .north, tricksTaken: 7)
        XCTAssertEqual(c.result, 0)
    }

    func testResultLevel7Made() {
        let c = Contract(level: 7, suit: .notrump, declarer: .north, tricksTaken: 13)
        XCTAssertEqual(c.result, 0)
    }

    // MARK: - Doubling Label

    func testDoublingLabelUndoubled() {
        let c = Contract(level: 3, suit: .hearts, declarer: .north, tricksTaken: 9)
        XCTAssertEqual(c.doublingLabel, "")
    }

    func testDoublingLabelDoubled() {
        let a = Auction(dealer: .north)
        a.bid(Bid(3, .hearts)); a.double(); a.close()
        let c = Contract(auction: a, tricksTaken: 9)!
        XCTAssertEqual(c.doublingLabel, " ×")
    }

    func testDoublingLabelRedoubled() {
        let a = Auction(dealer: .north)
        a.bid(Bid(3, .hearts)); a.double(); a.redouble(); a.close()
        let c = Contract(auction: a, tricksTaken: 9)!
        XCTAssertEqual(c.doublingLabel, " ××")
    }
}

// MARK: - Honors

final class HonorsTests: XCTestCase {
    func testPoints() {
        XCTAssertEqual(Honors.none.points,         0)
        XCTAssertEqual(Honors.declarer100.points, 100)
        XCTAssertEqual(Honors.declarer150.points, 150)
        XCTAssertEqual(Honors.defender100.points, 100)
        XCTAssertEqual(Honors.defender150.points, 150)
    }

    func testAllCasesCount() {
        XCTAssertEqual(Honors.allCases.count, 5)
    }

    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for h in Honors.allCases {
            let data = try encoder.encode(h)
            let decoded = try decoder.decode(Honors.self, from: data)
            XCTAssertEqual(decoded, h)
        }
    }
}
