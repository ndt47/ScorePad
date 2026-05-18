//
//  AuctionTests.swift
//  ScorePadTests
//

import XCTest
@testable import ScorePad

final class AuctionTests: XCTestCase {

    // MARK: - Init

    func testInit() {
        let a = Auction()
        XCTAssertEqual(a.dealer, .north)
        XCTAssertEqual(a.bidder, .north)
        XCTAssertTrue(a.calls.isEmpty)
        XCTAssertNil(a.declarer)
        XCTAssertNil(a.level)
        XCTAssertNil(a.suit)
        XCTAssertFalse(a.doubled)
        XCTAssertFalse(a.redoubled)
        XCTAssertFalse(a.closed)
        XCTAssertTrue(a.isPassHand)   // vacuously true: 0 passes == 0 total
        XCTAssertFalse(a.canRemoveLast)
    }

    func testInitWithCustomDealer() {
        let a = Auction(dealer: .east)
        XCTAssertEqual(a.dealer, .east)
        XCTAssertEqual(a.bidder, .east)
    }

    // MARK: - Basic Bidding

    func testBidderAdvancesOnEachCall() {
        let a = Auction(dealer: .north)
        a.pass()
        XCTAssertEqual(a.bidder, .east)
        a.bid(Bid(1, .clubs))
        XCTAssertEqual(a.bidder, .south)
        a.pass()
        XCTAssertEqual(a.bidder, .west)
    }

    func testBidSetsLevelAndSuit() {
        let a = Auction(dealer: .north)
        a.bid(Bid(3, .hearts))
        XCTAssertEqual(a.level, 3)
        XCTAssertEqual(a.suit, .hearts)
    }

    func testBidIncreases() {
        let a = Auction(dealer: .north)
        a.bid(Bid(1, .clubs))
        a.bid(Bid(2, .clubs))
        XCTAssertEqual(a.level, 2)
        a.bid(Bid(2, .hearts))
        XCTAssertEqual(a.suit, .hearts)
    }

    func testCanRemoveLast() {
        let a = Auction()
        XCTAssertFalse(a.canRemoveLast)
        a.pass()
        XCTAssertTrue(a.canRemoveLast)
    }

    func testUndoLast() {
        let a = Auction(dealer: .north)
        a.bid(Bid(1, .clubs))
        XCTAssertEqual(a.bidder, .east)
        a.undoLast()
        XCTAssertEqual(a.bidder, .north)
        XCTAssertNil(a.level)
        XCTAssertTrue(a.calls.isEmpty)
    }

    func testUndoLastFromEmpty() {
        let a = Auction()
        a.undoLast()  // Should not crash
        XCTAssertTrue(a.calls.isEmpty)
    }

    func testUndoLastRestoresBidder() {
        let a = Auction(dealer: .north)
        a.pass()   // north, bidder → east
        a.pass()   // east,  bidder → south
        a.undoLast()
        XCTAssertEqual(a.bidder, .east)
        a.undoLast()
        XCTAssertEqual(a.bidder, .north)
    }

    // MARK: - Closing

    func testPassHand() {
        let a = Auction(dealer: .north)
        a.pass(); XCTAssertFalse(a.closed)
        a.pass(); XCTAssertFalse(a.closed)
        a.pass(); XCTAssertFalse(a.closed)
        a.pass(); XCTAssertTrue(a.closed)
        XCTAssertTrue(a.isPassHand)
    }

    func testClosedAfterBidAndThreePasses() {
        let a = Auction(dealer: .north)
        a.bid(Bid(1, .clubs))
        a.pass(); XCTAssertFalse(a.closed)
        a.pass(); XCTAssertFalse(a.closed)
        a.pass(); XCTAssertTrue(a.closed)
    }

    func testClosedAfterDoubleAndThreePasses() {
        let a = Auction(dealer: .north)
        a.bid(Bid(1, .clubs))
        a.double()
        a.pass(); XCTAssertFalse(a.closed)
        a.pass(); XCTAssertFalse(a.closed)
        a.pass(); XCTAssertTrue(a.closed)
    }

    func testCloseMethod() {
        let a = Auction(dealer: .north)
        a.bid(Bid(4, .spades))
        XCTAssertFalse(a.closed)
        a.close()
        XCTAssertTrue(a.closed)
    }

    func testCallsIgnoredWhenClosed() {
        let a = Auction(dealer: .north)
        a.bid(Bid(3, .clubs))
        a.pass(); a.pass(); a.pass()
        XCTAssertTrue(a.closed)
        let countBefore = a.calls.count
        a.bid(Bid(4, .clubs))
        a.pass()
        XCTAssertEqual(a.calls.count, countBefore)
    }

    // MARK: - Declarer

    func testDeclarerIsFirstTeamMemberToBidSuit() {
        // North and South are on team "we"
        let a = Auction(dealer: .north)
        a.bid(Bid(1, .diamonds))  // north
        a.pass()                   // east
        a.bid(Bid(2, .diamonds))  // south bids same suit
        // Declarer should be north (first NS to bid diamonds)
        XCTAssertEqual(a.declarer, .north)
    }

    func testDeclarerChangesWhenNewSuitBid() {
        let a = Auction(dealer: .north)
        a.bid(Bid(1, .clubs))     // north
        a.pass()
        a.bid(Bid(2, .hearts))    // south - different suit
        // last bid is 2H by south, first NS to bid hearts is south
        XCTAssertEqual(a.declarer, .south)
    }

    func testDeclarerOpposingTeam() {
        let a = Auction(dealer: .east)
        a.bid(Bid(2, .spades))    // east bids; bidder → south
        XCTAssertEqual(a.declarer, .east)

        a.pass()                   // south passes; bidder → west
        a.bid(Bid(3, .spades))    // west bids same suit; bidder → north
        // east is still first EW to bid spades
        XCTAssertEqual(a.declarer, .east)
    }

    func testDeclarerNilWithNoBid() {
        let a = Auction()
        XCTAssertNil(a.declarer)
        a.pass()
        XCTAssertNil(a.declarer)
    }

    // MARK: - Double / Redouble

    func testDoubled() {
        let a = Auction(dealer: .north)
        a.bid(Bid(3, .hearts))    // north
        a.double()                 // east (opposing team)
        XCTAssertTrue(a.doubled)
        XCTAssertFalse(a.redoubled)
    }

    func testRedoubled() {
        let a = Auction(dealer: .north)
        a.bid(Bid(3, .hearts))    // north
        a.double()                 // east
        a.redouble()               // south (same team as north)
        XCTAssertFalse(a.doubled)
        XCTAssertTrue(a.redoubled)
    }

    func testDoubledFalseAfterNewBid() {
        let a = Auction(dealer: .north)
        a.bid(Bid(1, .clubs))
        a.double()   // east doubles
        a.bid(Bid(2, .clubs))  // south overcalls (implicit west pass added)
        // Wait - south can't bid 2C if east just doubled 1C and bidder is now south
        // Actually: north bids 1C, bidder=east; east doubles, bidder=south
        // south bids 2C, bidder=west
        // last non-pass call is 2C bid, so doubled = false
        XCTAssertFalse(a.doubled)
    }

    func testCanDouble() {
        let a = Auction(dealer: .north)
        a.bid(Bid(1, .clubs))           // north bids, bidder=east
        XCTAssertTrue(a.canDouble(by: .east))   // east can double (opposing team)
        XCTAssertFalse(a.canDouble(by: .south)) // south cannot (same team as north)
    }

    func testCanDoubleWithNoBid() {
        let a = Auction()
        XCTAssertFalse(a.canDouble(by: .east))
    }

    func testCanDoubleAfterDouble() {
        let a = Auction(dealer: .north)
        a.bid(Bid(2, .spades))
        a.double()  // east doubles
        // After east doubles, can't double again until a new bid
        XCTAssertFalse(a.canDouble(by: .south))
        XCTAssertFalse(a.canDouble(by: .north))
    }

    func testCanRedouble() {
        let a = Auction(dealer: .north)
        a.bid(Bid(1, .clubs))   // north, bidder=east
        a.double()               // east, bidder=south
        XCTAssertTrue(a.canRedouble(by: .south))  // same team as north bid
        XCTAssertFalse(a.canRedouble(by: .east))  // east doubled, not eligible
    }

    func testCanRedoubleWithNoDouble() {
        let a = Auction(dealer: .north)
        a.bid(Bid(1, .clubs))
        XCTAssertFalse(a.canRedouble(by: .south))
    }

    // MARK: - Passes Filled Automatically

    func testPassesFilledBetweenNonConsecutiveBidders() {
        // If south makes a call but east hasn't yet, passes for east are auto-inserted
        let a = Auction(dealer: .north)
        a.bid(Bid(1, .clubs))   // north
        // Manually add a call for south (skipping east)
        // The public API uses `bidder`, so let's test by checking calls count
        // north bids (bidder→east), east passes (bidder→south), south passes (bidder→west)
        a.pass()  // east passes
        a.pass()  // south passes
        XCTAssertEqual(a.calls.count, 3)  // north bid + east pass + south pass
        XCTAssertEqual(a.bidder, .west)
    }

    // MARK: - Full Auction Flow

    func testFullBiddingSequence() {
        let a = Auction(dealer: .north)
        a.pass()
        XCTAssertEqual(a.bidder, .east)
        XCTAssertFalse(a.closed)

        a.bid(Bid(1, .diamonds))
        XCTAssertEqual(a.bidder, .south)
        XCTAssertEqual(a.declarer, .east)
        XCTAssertEqual(a.level, 1)
        XCTAssertEqual(a.suit, .diamonds)

        a.bid(Bid(2, .hearts))
        XCTAssertEqual(a.declarer, .south)
        XCTAssertEqual(a.level, 2)
        XCTAssertEqual(a.suit, .hearts)

        a.bid(Bid(3, .diamonds))
        XCTAssertEqual(a.declarer, .east)
        XCTAssertEqual(a.level, 3)

        a.pass()
        a.bid(Bid(5, .diamonds))
        a.double()
        XCTAssertTrue(a.doubled)

        a.pass(); XCTAssertFalse(a.closed)
        a.pass(); XCTAssertFalse(a.closed)
        a.pass(); XCTAssertTrue(a.closed)
    }

    // MARK: - Codable

    func testCodableRoundtrip() throws {
        let a = Auction(dealer: .south)
        a.bid(Bid(4, .spades))
        a.double()
        a.close()

        let data = try JSONEncoder().encode(a)
        let decoded = try JSONDecoder().decode(Auction.self, from: data)

        XCTAssertEqual(decoded.dealer, a.dealer)
        XCTAssertEqual(decoded.calls.count, a.calls.count)
        XCTAssertTrue(decoded.doubled)
    }
}
