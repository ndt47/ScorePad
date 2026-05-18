//
//  ScoreTests.swift
//  ScorePadTests
//
//  Created by Nathan Taylor on 11/28/22.
//

import XCTest
@testable import ScorePad

final class AuctionTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    
    func testInit() throws {
        let test = Auction()
        XCTAssertEqual(test.dealer, .north)
        XCTAssertTrue(test.calls.isEmpty)
        XCTAssertEqual(test.bidder, .north)
    }

    func testBidding() throws {
        let test = Auction()

        test.pass()
        XCTAssertEqual(test.dealer, .north)
        XCTAssertFalse(test.calls.isEmpty)
        XCTAssertEqual(test.bidder, .east)
        XCTAssertFalse(test.closed)

        test.bid(Bid(1, .diamonds))
        XCTAssertEqual(test.bidder, .south)
        XCTAssertNotNil(test.declarer)
        XCTAssertEqual(test.declarer, .east)
        XCTAssertEqual(test.level, 1)
        XCTAssertEqual(test.suit, .diamonds)
        XCTAssertFalse(test.closed)

        test.bid(Bid(2, .hearts))
        XCTAssertEqual(test.bidder, .west)
        XCTAssertEqual(test.declarer, .south)
        XCTAssertEqual(test.level, 2)
        XCTAssertEqual(test.suit, .hearts)
        XCTAssertFalse(test.closed)

        test.bid(Bid(3, .diamonds))
        XCTAssertEqual(test.bidder, .north)
        XCTAssertEqual(test.declarer, .east)
        XCTAssertEqual(test.level, 3)
        XCTAssertEqual(test.suit, .diamonds)
        XCTAssertFalse(test.closed)

        test.pass()
        XCTAssertEqual(test.bidder, .east)
        XCTAssertFalse(test.closed)

        test.bid(Bid(5, .diamonds))
        XCTAssertEqual(test.bidder, .south)
        XCTAssertEqual(test.declarer, .east)
        XCTAssertEqual(test.level, 5)
        XCTAssertFalse(test.closed)

        test.double()
        XCTAssertEqual(test.bidder, .west)
        XCTAssertTrue(test.doubled)
        XCTAssertFalse(test.closed)

        test.pass(); XCTAssertFalse(test.closed)
        test.pass(); XCTAssertFalse(test.closed)
        test.pass(); XCTAssertTrue(test.closed)
    }

    func testPassHand() throws {
        let test = Auction()
        test.pass(); XCTAssertFalse(test.closed)
        test.pass(); XCTAssertFalse(test.closed)
        test.pass(); XCTAssertFalse(test.closed)
        test.pass(); XCTAssertTrue(test.closed)
    }
}
