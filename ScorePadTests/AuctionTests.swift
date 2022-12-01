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
        XCTAssertEqual(test.currentPosition, .north)
    }
    
    func testBidding() throws {
        var test = Auction()
        
        XCTAssertNoThrow(try test.pass())
        XCTAssertEqual(test.dealer, .north)
        XCTAssertFalse(test.calls.isEmpty)
        XCTAssertEqual(test.currentPosition, .east)
        XCTAssertFalse(test.closed)

        XCTAssertNoThrow(try test.bid(level: 1, suit: .diamonds))
        XCTAssertEqual(test.dealer, .north)
        XCTAssertFalse(test.calls.isEmpty)
        XCTAssertEqual(test.currentPosition, .south)
        XCTAssertNotNil(test.lastBid)
        XCTAssertNotNil(test.declarer)
        XCTAssertEqual(test.declarer!, .east)
        XCTAssertNotNil(test.level)
        XCTAssertEqual(test.level!, 1)
        XCTAssertNotNil(test.suit)
        XCTAssertEqual(test.suit!, .diamonds)
        XCTAssertFalse(test.closed)

        XCTAssertNoThrow(try test.bid(level: 2, suit: .hearts))
        XCTAssertEqual(test.dealer, .north)
        XCTAssertFalse(test.calls.isEmpty)
        XCTAssertEqual(test.currentPosition, .west)
        XCTAssertNotNil(test.lastBid)
        XCTAssertNotNil(test.declarer)
        XCTAssertEqual(test.declarer!, .south)
        XCTAssertNotNil(test.level)
        XCTAssertEqual(test.level!, 2)
        XCTAssertNotNil(test.suit)
        XCTAssertEqual(test.suit!, .hearts)
        XCTAssertFalse(test.closed)

        XCTAssertNoThrow(try test.bid(level: 3, suit: .diamonds))
        XCTAssertEqual(test.dealer, .north)
        XCTAssertFalse(test.calls.isEmpty)
        XCTAssertEqual(test.currentPosition, .north)
        XCTAssertNotNil(test.lastBid)
        XCTAssertNotNil(test.declarer)
        XCTAssertEqual(test.declarer!, .east)
        XCTAssertNotNil(test.level)
        XCTAssertEqual(test.level!, 3)
        XCTAssertNotNil(test.suit)
        XCTAssertEqual(test.suit!, .diamonds)
        XCTAssertFalse(test.closed)

        XCTAssertNoThrow(try test.pass())
        XCTAssertEqual(test.dealer, .north)
        XCTAssertFalse(test.calls.isEmpty)
        XCTAssertEqual(test.currentPosition, .east)
        XCTAssertNotNil(test.lastBid)
        XCTAssertNotNil(test.declarer)
        XCTAssertEqual(test.declarer!, .east)
        XCTAssertNotNil(test.level)
        XCTAssertEqual(test.level!, 3)
        XCTAssertNotNil(test.suit)
        XCTAssertEqual(test.suit!, .diamonds)
        XCTAssertFalse(test.closed)

        XCTAssertNoThrow(try test.bid(level: 5, suit: .diamonds))
        XCTAssertEqual(test.dealer, .north)
        XCTAssertFalse(test.calls.isEmpty)
        XCTAssertEqual(test.currentPosition, .south)
        XCTAssertNotNil(test.lastBid)
        XCTAssertNotNil(test.declarer)
        XCTAssertEqual(test.declarer!, .east)
        XCTAssertNotNil(test.level)
        XCTAssertEqual(test.level!, 5)
        XCTAssertNotNil(test.suit)
        XCTAssertEqual(test.suit!, .diamonds)
        XCTAssertFalse(test.closed)

        XCTAssertNoThrow(try test.double())
        XCTAssertEqual(test.dealer, .north)
        XCTAssertFalse(test.calls.isEmpty)
        XCTAssertEqual(test.currentPosition, .west)
        XCTAssertNotNil(test.lastBid)
        XCTAssertNotNil(test.declarer)
        XCTAssertEqual(test.declarer!, .east)
        XCTAssertNotNil(test.level)
        XCTAssertEqual(test.level!, 5)
        XCTAssertNotNil(test.suit)
        XCTAssertEqual(test.suit!, .diamonds)
        XCTAssertTrue(test.doubled)
        XCTAssertFalse(test.closed)
        
        XCTAssertNoThrow(try test.pass())
        XCTAssertFalse(test.closed)
        XCTAssertNoThrow(try test.pass())
        XCTAssertFalse(test.closed)
        XCTAssertNoThrow(try test.pass())
        XCTAssertTrue(test.closed)
    }
    
    func testPassHand() throws {
        var test = Auction()
        XCTAssertNoThrow(try test.pass())
        XCTAssertFalse(test.closed)
        XCTAssertNoThrow(try test.pass())
        XCTAssertFalse(test.closed)
        XCTAssertNoThrow(try test.pass())
        XCTAssertFalse(test.closed)
        XCTAssertNoThrow(try test.pass())
        XCTAssertTrue(test.closed)
    }
}
