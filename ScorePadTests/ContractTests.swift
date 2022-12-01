//
//  ContractTests.swift
//  ScorePadTests
//
//  Created by Nathan Taylor on 11/29/22.
//

import XCTest

final class ContractTests: XCTestCase {

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

    //    func testScoring() throws {
    //        var auction = Auction()
    //
    //        XCTAssertNoThrow(try auction.pass())
    //        XCTAssertNoThrow(try auction.bid(level: 1, suit: .diamonds))
    //        XCTAssertNoThrow(try auction.bid(level: 2, suit: .hearts))
    //        XCTAssertNoThrow(try auction.bid(level: 3, suit: .diamonds))
    //        XCTAssertNoThrow(try auction.pass())
    //        XCTAssertNoThrow(try auction.bid(level: 5, suit: .diamonds))
    //
    //        let down1 = Contract(auction: auction, tricksTaken: 10)
    //        XCTAssertNotNil(down1)
    //
    //        let nonVulnerableDown1 = [down1!].points(vulnerable: [])
    //        XCTAssertEqual(nonVulnerableDown1.we.above, 50)
    //        XCTAssertEqual(nonVulnerableDown1.we.below, 0)
    //        XCTAssertEqual(nonVulnerableDown1.they.above, 0)
    //        XCTAssertEqual(nonVulnerableDown1.they.below, 0)
    //
    //        let vulnerableDown1 = [down1!].points(vulnerable: [.they])
    //        XCTAssertEqual(vulnerableDown1.we.above, 100)
    //        XCTAssertEqual(vulnerableDown1.we.below, 0)
    //        XCTAssertEqual(vulnerableDown1.they.above, 0)
    //        XCTAssertEqual(vulnerableDown1.they.below, 0)
    //
    //        let down3 = Contract(auction: auction, tricksTaken: 8)
    //        XCTAssertNotNil(down3)
    //
    //        let nonVulnerableDown3 = [down3!].points(vulnerable: [])
    //        XCTAssertEqual(nonVulnerableDown3.we.above, 150)
    //        XCTAssertEqual(nonVulnerableDown3.we.below, 0)
    //        XCTAssertEqual(nonVulnerableDown3.they.above, 0)
    //        XCTAssertEqual(nonVulnerableDown3.they.below, 0)
    //
    //        let vulnerableDown3 = [down3!].points(vulnerable: [.they])
    //        XCTAssertEqual(vulnerableDown3.we.above, 300)
    //        XCTAssertEqual(vulnerableDown3.we.below, 0)
    //        XCTAssertEqual(vulnerableDown3.they.above, 0)
    //        XCTAssertEqual(vulnerableDown3.they.below, 0)
    //
    //        let made = Contract(auction: auction, tricksTaken: 11)
    //        XCTAssertNotNil(made)
    //
    //        let madeNotVulnerable = [made!].points(vulnerable: [])
    //        XCTAssertEqual(madeNotVulnerable.we.above, 0)
    //        XCTAssertEqual(madeNotVulnerable.we.below, 0)
    //        XCTAssertEqual(madeNotVulnerable.they.above, 0)
    //        XCTAssertEqual(madeNotVulnerable.they.below, 100)
    //
    //        let madeVulnerable = [made!].points(vulnerable: [.they])
    //        XCTAssertEqual(madeVulnerable.we.above, 0)
    //        XCTAssertEqual(madeVulnerable.we.below, 0)
    //        XCTAssertEqual(madeVulnerable.they.above, 0)
    //        XCTAssertEqual(madeVulnerable.they.below, 100)
    //
    //        let over1 = Contract(auction: auction, tricksTaken: 11)
    //        XCTAssertNotNil(over1!)
    //
    //        let over1NotVulnerable = [over1!].points(vulnerable: [])
    //        XCTAssertEqual(over1NotVulnerable.we.above, 0)
    //        XCTAssertEqual(over1NotVulnerable.we.below, 0)
    //        XCTAssertEqual(over1NotVulnerable.they.above, 20)
    //        XCTAssertEqual(over1NotVulnerable.they.below, 100)
    //
    //        let vulnerableOver1 = [over1!].points(vulnerable: [])
    //        XCTAssertEqual(vulnerableOver1.we.above, 0)
    //        XCTAssertEqual(vulnerableOver1.we.below, 0)
    //        XCTAssertEqual(vulnerableOver1.they.above, 20)
    //        XCTAssertEqual(vulnerableOver1.they.below, 100)
    //
    //        XCTAssertNoThrow(try auction.double())
    //        XCTAssertTrue(auction.doubled)
    //
    //        test.tricksTaken = 10
    //        let nonVulnerableDoubleDown1 = [test].points(vulnerable: [])
    //        XCTAssertEqual(nonVulnerableDoubleDown1.we.above, 100)
    //        XCTAssertEqual(nonVulnerableDoubleDown1.we.below, 0)
    //        XCTAssertEqual(nonVulnerableDoubleDown1.they.above, 0)
    //        XCTAssertEqual(nonVulnerableDoubleDown1.they.below, 0)
    //
    //        let vulnerableDoubleDown1 = [test].points(vulnerable: [.they])
    //        XCTAssertEqual(vulnerableDoubleDown1.we.above, 200)
    //        XCTAssertEqual(vulnerableDoubleDown1.we.below, 0)
    //        XCTAssertEqual(vulnerableDoubleDown1.they.above, 0)
    //        XCTAssertEqual(vulnerableDoubleDown1.they.below, 0)
    //
    //        test.tricksTaken = 8
    //        let nonVulnerableDoubledDown3 = [test].points(vulnerable: [])
    //        XCTAssertEqual(nonVulnerableDoubledDown3.we.above, 500)
    //        XCTAssertEqual(nonVulnerableDoubledDown3.we.below, 0)
    //        XCTAssertEqual(nonVulnerableDoubledDown3.they.above, 0)
    //        XCTAssertEqual(nonVulnerableDoubledDown3.they.below, 0)
    //
    //        let vulnerableDoubledDown3 = [test].points(vulnerable: [.they])
    //        XCTAssertEqual(vulnerableDoubledDown3.we.above, 800)
    //        XCTAssertEqual(vulnerableDoubledDown3.we.below, 0)
    //        XCTAssertEqual(vulnerableDoubledDown3.they.above, 0)
    //        XCTAssertEqual(vulnerableDoubledDown3.they.below, 0)
    //
    //        test.tricksTaken = 11
    //        let madeDoubled = [test].points(vulnerable: [])
    //        XCTAssertEqual(madeDoubled.we.above, 0)
    //        XCTAssertEqual(madeDoubled.we.below, 0)
    //        XCTAssertEqual(madeDoubled.they.above, 0)
    //        XCTAssertEqual(madeDoubled.they.below, 200)
    //
    //        let madeVulnerableDoubled = [test].points(vulnerable: [.they])
    //        XCTAssertEqual(madeVulnerableDoubled.we.above, 0)
    //        XCTAssertEqual(madeVulnerableDoubled.we.below, 0)
    //        XCTAssertEqual(madeVulnerableDoubled.they.above, 0)
    //        XCTAssertEqual(madeVulnerableDoubled.they.below, 200)
    //
    //        test.tricksTaken = 12
    //        let doubledOver1 = [test].points(vulnerable: [])
    //        XCTAssertEqual(doubledOver1.we.above, 0)
    //        XCTAssertEqual(doubledOver1.we.below, 0)
    //        XCTAssertEqual(doubledOver1.they.above, 100)
    //        XCTAssertEqual(doubledOver1.they.below, 200)
    //
    //        let vulnerableDoubledOver1 = [test].points(vulnerable: [.they])
    //        XCTAssertEqual(vulnerableDoubledOver1.we.above, 0)
    //        XCTAssertEqual(vulnerableDoubledOver1.we.below, 0)
    //        XCTAssertEqual(vulnerableDoubledOver1.they.above, 200)
    //        XCTAssertEqual(vulnerableDoubledOver1.they.below, 200)
    //    }

}
