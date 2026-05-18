//
//  ScoreTests.swift
//  ScorePadTests
//
//  Comprehensive tests for Contract Bridge scoring rules.
//

import XCTest
@testable import ScorePad

// MARK: - Helpers

private func contract(
    level: Int, suit: Suit,
    declarer: Position = .north,
    doubled: Bool = false,
    redoubled: Bool = false,
    tricksTaken: Int,
    vulnerable: Bool = false,
    honors: Honors = .none
) -> Contract {
    if doubled || redoubled {
        let a = Auction(dealer: declarer)
        a.bid(Bid(level, suit))
        a.double()
        if redoubled { a.redouble() }
        return Contract(auction: a, honors: honors, tricksTaken: tricksTaken, vulnerable: vulnerable)!
    }
    return Contract(level: level, suit: suit, declarer: declarer, honors: honors,
                    tricksTaken: tricksTaken, vulnerable: vulnerable)
}

// Return the single .bid score value or fail
private func bidScore(_ c: Contract, file: StaticString = #file, line: UInt = #line) -> Int {
    let bids = c.scores.filter { if case .bid = $0 { return true }; return false }
    XCTAssertEqual(bids.count, 1, "expected exactly 1 bid score", file: file, line: line)
    return bids.first?.value ?? 0
}

// MARK: - Trick Scores (Under the Line)

final class TrickScoreTests: XCTestCase {

    // --- Minor suits: 20 per trick bid ---

    func testClubs20PerTrick() {
        XCTAssertEqual(bidScore(contract(level: 1, suit: .clubs, tricksTaken: 7)),  20)
        XCTAssertEqual(bidScore(contract(level: 3, suit: .clubs, tricksTaken: 9)),  60)
        XCTAssertEqual(bidScore(contract(level: 5, suit: .clubs, tricksTaken: 11)), 100)
    }

    func testDiamonds20PerTrick() {
        XCTAssertEqual(bidScore(contract(level: 1, suit: .diamonds, tricksTaken: 7)),  20)
        XCTAssertEqual(bidScore(contract(level: 4, suit: .diamonds, tricksTaken: 10)), 80)
    }

    // --- Major suits: 30 per trick bid ---

    func testHearts30PerTrick() {
        XCTAssertEqual(bidScore(contract(level: 1, suit: .hearts, tricksTaken: 7)),  30)
        XCTAssertEqual(bidScore(contract(level: 4, suit: .hearts, tricksTaken: 10)), 120)
    }

    func testSpades30PerTrick() {
        XCTAssertEqual(bidScore(contract(level: 1, suit: .spades, tricksTaken: 7)),  30)
        XCTAssertEqual(bidScore(contract(level: 4, suit: .spades, tricksTaken: 10)), 120)
    }

    // --- No Trump: 40 for first + 30 each subsequent ---

    func testNoTrumpScoring() {
        XCTAssertEqual(bidScore(contract(level: 1, suit: .notrump, tricksTaken: 7)), 40)
        XCTAssertEqual(bidScore(contract(level: 2, suit: .notrump, tricksTaken: 8)), 70)
        XCTAssertEqual(bidScore(contract(level: 3, suit: .notrump, tricksTaken: 9)), 100)
    }

    // --- Doubled: 2× trick score under the line ---

    func testDoubledMinorSuit() {
        XCTAssertEqual(bidScore(contract(level: 3, suit: .clubs, doubled: true, tricksTaken: 9)),  120)
        XCTAssertEqual(bidScore(contract(level: 3, suit: .diamonds, doubled: true, tricksTaken: 9)), 120)
    }

    func testDoubledMajorSuit() {
        XCTAssertEqual(bidScore(contract(level: 4, suit: .hearts, doubled: true, tricksTaken: 10)),  240)
        XCTAssertEqual(bidScore(contract(level: 4, suit: .spades, doubled: true, tricksTaken: 10)),  240)
    }

    func testDoubledNoTrump() {
        XCTAssertEqual(bidScore(contract(level: 3, suit: .notrump, doubled: true, tricksTaken: 9)), 200)
    }

    // --- Redoubled: 4× trick score under the line ---

    func testRedoubledMinorSuit() {
        XCTAssertEqual(bidScore(contract(level: 2, suit: .clubs, redoubled: true, tricksTaken: 8)), 160)
    }

    func testRedoubledMajorSuit() {
        XCTAssertEqual(bidScore(contract(level: 4, suit: .spades, redoubled: true, tricksTaken: 10)), 480)
    }

    func testRedoubledNoTrump() {
        XCTAssertEqual(bidScore(contract(level: 1, suit: .notrump, redoubled: true, tricksTaken: 7)), 160)
    }
}

// MARK: - Insult Bonus

final class InsultBonusTests: XCTestCase {
    private func insultScore(_ c: Contract) -> Int? {
        let insults = c.scores.compactMap { score -> Int? in
            if case let .insult(v, _) = score { return v }
            return nil
        }
        return insults.first
    }

    func testNoInsultUndoubled() {
        let c = contract(level: 3, suit: .hearts, tricksTaken: 9)
        XCTAssertNil(insultScore(c))
    }

    func testInsult50ForDoubled() {
        let c = contract(level: 3, suit: .hearts, doubled: true, tricksTaken: 9)
        XCTAssertEqual(insultScore(c), 50)
    }

    func testInsult100ForRedoubled() {
        let c = contract(level: 3, suit: .hearts, redoubled: true, tricksTaken: 9)
        XCTAssertEqual(insultScore(c), 100)
    }

    func testNoInsultOnUndertricks() {
        let c = contract(level: 3, suit: .hearts, doubled: true, tricksTaken: 8)  // 1 undertrick
        XCTAssertNil(insultScore(c))
    }
}

// MARK: - Overtricks

final class OvertrickTests: XCTestCase {
    private func overScore(_ c: Contract) -> Int? {
        let overs = c.scores.compactMap { score -> Int? in
            if case let .over(v, _) = score { return v }
            return nil
        }
        return overs.first
    }

    // Undoubled overtricks: suit rate (20/30/30 for NT)
    func testUndoubledOvertrickMinor() {
        let c = contract(level: 2, suit: .clubs, tricksTaken: 10)  // +2
        XCTAssertEqual(overScore(c), 40)  // 2 × 20
    }

    func testUndoubledOvertrickMajor() {
        let c = contract(level: 4, suit: .hearts, tricksTaken: 11)  // +1
        XCTAssertEqual(overScore(c), 30)
    }

    func testUndoubledOvertrickNoTrump() {
        let c = contract(level: 3, suit: .notrump, tricksTaken: 11)  // +2
        XCTAssertEqual(overScore(c), 60)  // 2 × 30 (flat rate for overtricks)
    }

    // Doubled overtricks not vulnerable: 100 each
    func testDoubledOvertrickNotVul() {
        let c = contract(level: 3, suit: .hearts, doubled: true, tricksTaken: 10, vulnerable: false)  // +1
        XCTAssertEqual(overScore(c), 100)
    }

    func testDoubledTwoOvertricksNotVul() {
        let c = contract(level: 3, suit: .hearts, doubled: true, tricksTaken: 11, vulnerable: false)  // +2
        XCTAssertEqual(overScore(c), 200)
    }

    // Doubled overtricks vulnerable: 200 each
    func testDoubledOvertrickVul() {
        let c = contract(level: 3, suit: .hearts, doubled: true, tricksTaken: 10, vulnerable: true)  // +1
        XCTAssertEqual(overScore(c), 200)
    }

    func testDoubledTwoOvertricksVul() {
        let c = contract(level: 3, suit: .hearts, doubled: true, tricksTaken: 11, vulnerable: true)  // +2
        XCTAssertEqual(overScore(c), 400)
    }

    // Redoubled overtricks not vulnerable: 200 each
    func testRedoubledOvertrickNotVul() {
        let c = contract(level: 2, suit: .spades, redoubled: true, tricksTaken: 9, vulnerable: false)  // +1
        XCTAssertEqual(overScore(c), 200)
    }

    // Redoubled overtricks vulnerable: 400 each
    func testRedoubledOvertrickVul() {
        let c = contract(level: 2, suit: .spades, redoubled: true, tricksTaken: 9, vulnerable: true)  // +1
        XCTAssertEqual(overScore(c), 400)
    }

    func testNoOvertrickWhenMadeExactly() {
        let c = contract(level: 4, suit: .spades, tricksTaken: 10)
        XCTAssertNil(overScore(c))
    }
}

// MARK: - Undertricks

final class UndertrickTests: XCTestCase {
    private func underScore(_ c: Contract) -> Int? {
        let unders = c.scores.compactMap { score -> Int? in
            if case let .under(v, _) = score { return v }
            return nil
        }
        return unders.first
    }

    // Undoubled not vulnerable: 50 per trick
    func testUndoubledNotVulDown1() {
        let c = contract(level: 3, suit: .hearts, tricksTaken: 8, vulnerable: false)
        XCTAssertEqual(underScore(c), 50)
    }

    func testUndoubledNotVulDown3() {
        let c = contract(level: 3, suit: .hearts, tricksTaken: 6, vulnerable: false)
        XCTAssertEqual(underScore(c), 150)
    }

    // Undoubled vulnerable: 100 per trick
    func testUndoubledVulDown1() {
        let c = contract(level: 3, suit: .hearts, tricksTaken: 8, vulnerable: true)
        XCTAssertEqual(underScore(c), 100)
    }

    func testUndoubledVulDown3() {
        let c = contract(level: 3, suit: .hearts, tricksTaken: 6, vulnerable: true)
        XCTAssertEqual(underScore(c), 300)
    }

    // Doubled not vulnerable: 100, 200, 200, 300, 300...
    func testDoubledNotVulDown1() {
        let c = contract(level: 3, suit: .hearts, doubled: true, tricksTaken: 8, vulnerable: false)
        XCTAssertEqual(underScore(c), 100)
    }

    func testDoubledNotVulDown2() {
        let c = contract(level: 3, suit: .hearts, doubled: true, tricksTaken: 7, vulnerable: false)
        XCTAssertEqual(underScore(c), 300)   // 100 + 200
    }

    func testDoubledNotVulDown3() {
        let c = contract(level: 3, suit: .hearts, doubled: true, tricksTaken: 6, vulnerable: false)
        XCTAssertEqual(underScore(c), 500)   // 100 + 200 + 200
    }

    func testDoubledNotVulDown4() {
        let c = contract(level: 4, suit: .hearts, doubled: true, tricksTaken: 6, vulnerable: false)
        XCTAssertEqual(underScore(c), 800)   // 100 + 200 + 200 + 300
    }

    func testDoubledNotVulDown5() {
        let c = contract(level: 4, suit: .hearts, doubled: true, tricksTaken: 5, vulnerable: false)
        XCTAssertEqual(underScore(c), 1100)  // 100 + 200 + 200 + 300 + 300
    }

    // Doubled vulnerable: 200, 300, 300, 300...
    func testDoubledVulDown1() {
        let c = contract(level: 3, suit: .hearts, doubled: true, tricksTaken: 8, vulnerable: true)
        XCTAssertEqual(underScore(c), 200)
    }

    func testDoubledVulDown2() {
        let c = contract(level: 3, suit: .hearts, doubled: true, tricksTaken: 7, vulnerable: true)
        XCTAssertEqual(underScore(c), 500)   // 200 + 300
    }

    func testDoubledVulDown3() {
        let c = contract(level: 3, suit: .hearts, doubled: true, tricksTaken: 6, vulnerable: true)
        XCTAssertEqual(underScore(c), 800)   // 200 + 300 + 300
    }

    func testDoubledVulDown4() {
        let c = contract(level: 4, suit: .hearts, doubled: true, tricksTaken: 6, vulnerable: true)
        XCTAssertEqual(underScore(c), 1100)  // 200 + 300 + 300 + 300
    }

    // Redoubled not vulnerable: 200, 400, 400, 600, 600...
    func testRedoubledNotVulDown1() {
        let c = contract(level: 3, suit: .hearts, redoubled: true, tricksTaken: 8, vulnerable: false)
        XCTAssertEqual(underScore(c), 200)
    }

    func testRedoubledNotVulDown2() {
        let c = contract(level: 3, suit: .hearts, redoubled: true, tricksTaken: 7, vulnerable: false)
        XCTAssertEqual(underScore(c), 600)   // 200 + 400
    }

    func testRedoubledNotVulDown3() {
        let c = contract(level: 3, suit: .hearts, redoubled: true, tricksTaken: 6, vulnerable: false)
        XCTAssertEqual(underScore(c), 1000)  // 200 + 400 + 400
    }

    func testRedoubledNotVulDown4() {
        let c = contract(level: 4, suit: .hearts, redoubled: true, tricksTaken: 6, vulnerable: false)
        XCTAssertEqual(underScore(c), 1600)  // 200 + 400 + 400 + 600
    }

    // Redoubled vulnerable: 400, 600, 600...
    func testRedoubledVulDown1() {
        let c = contract(level: 3, suit: .hearts, redoubled: true, tricksTaken: 8, vulnerable: true)
        XCTAssertEqual(underScore(c), 400)
    }

    func testRedoubledVulDown2() {
        let c = contract(level: 3, suit: .hearts, redoubled: true, tricksTaken: 7, vulnerable: true)
        XCTAssertEqual(underScore(c), 1000)  // 400 + 600
    }

    func testRedoubledVulDown3() {
        let c = contract(level: 3, suit: .hearts, redoubled: true, tricksTaken: 6, vulnerable: true)
        XCTAssertEqual(underScore(c), 1600)  // 400 + 600 + 600
    }

    func testNoUndertrickWhenMade() {
        let c = contract(level: 3, suit: .hearts, tricksTaken: 9)
        XCTAssertNil(underScore(c))
    }
}

// MARK: - Slam Bonuses

final class SlamBonusTests: XCTestCase {
    private func slamScore(_ c: Contract) -> Int? {
        c.scores.compactMap { if case let .slam(v, _) = $0 { return v }; return nil }.first
    }

    // Small slam: 500 not vul, 750 vul
    func testSmallSlamNotVul() {
        let c = contract(level: 6, suit: .hearts, tricksTaken: 12, vulnerable: false)
        XCTAssertEqual(slamScore(c), 500)
    }

    func testSmallSlamVul() {
        let c = contract(level: 6, suit: .hearts, tricksTaken: 12, vulnerable: true)
        XCTAssertEqual(slamScore(c), 750)
    }

    // Grand slam: 1000 not vul, 1500 vul
    func testGrandSlamNotVul() {
        let c = contract(level: 7, suit: .notrump, tricksTaken: 13, vulnerable: false)
        XCTAssertEqual(slamScore(c), 1000)
    }

    func testGrandSlamVul() {
        let c = contract(level: 7, suit: .notrump, tricksTaken: 13, vulnerable: true)
        XCTAssertEqual(slamScore(c), 1500)
    }

    func testNonSlamLevelsHaveNoBonus() {
        for level in 1...5 {
            let c = contract(level: level, suit: .hearts, tricksTaken: level + 6)
            XCTAssertNil(slamScore(c), "Level \(level) should have no slam bonus")
        }
    }

    func testSlamDownHasNoBonus() {
        let c = contract(level: 6, suit: .hearts, tricksTaken: 11, vulnerable: false)  // 1 down
        XCTAssertNil(slamScore(c))
    }

    func testSmallSlamDoubledNotVul() {
        let c = contract(level: 6, suit: .hearts, doubled: true, tricksTaken: 12, vulnerable: false)
        XCTAssertEqual(slamScore(c), 500)
    }

    func testGrandSlamDoubledVul() {
        let c = contract(level: 7, suit: .notrump, doubled: true, tricksTaken: 13, vulnerable: true)
        XCTAssertEqual(slamScore(c), 1500)
    }
}

// MARK: - Honors

final class HonorsScoringTests: XCTestCase {
    private func honorsScore(_ c: Contract) -> (value: Int, team: Team)? {
        for s in c.scores {
            if case let .honors(v, t, _) = s { return (v, t) }
        }
        return nil
    }

    func testNoHonors() {
        let c = contract(level: 4, suit: .spades, tricksTaken: 10, honors: .none)
        XCTAssertNil(honorsScore(c))
    }

    func testDeclarer100GoesToDeclarerTeam() {
        // Declarer is north (.we team)
        let c = contract(level: 4, suit: .spades, declarer: .north, tricksTaken: 10, honors: .declarer100)
        let score = honorsScore(c)
        XCTAssertEqual(score?.value, 100)
        XCTAssertEqual(score?.team, .we)
    }

    func testDeclarer150GoesToDeclarerTeam() {
        let c = contract(level: 4, suit: .spades, declarer: .north, tricksTaken: 10, honors: .declarer150)
        let score = honorsScore(c)
        XCTAssertEqual(score?.value, 150)
        XCTAssertEqual(score?.team, .we)
    }

    func testDefender100GoesToDefendingTeam() {
        // Declarer is north (.we), so defending team is .they
        let c = contract(level: 4, suit: .spades, declarer: .north, tricksTaken: 10, honors: .defender100)
        let score = honorsScore(c)
        XCTAssertEqual(score?.value, 100)
        XCTAssertEqual(score?.team, .they)
    }

    func testDefender150GoesToDefendingTeam() {
        let c = contract(level: 4, suit: .spades, declarer: .north, tricksTaken: 10, honors: .defender150)
        let score = honorsScore(c)
        XCTAssertEqual(score?.value, 150)
        XCTAssertEqual(score?.team, .they)
    }

    func testHonorsAwardedEvenOnUndertrick() {
        let c = contract(level: 4, suit: .spades, tricksTaken: 8, honors: .declarer100)
        XCTAssertNotNil(honorsScore(c))
    }
}

// MARK: - Score Properties

final class ScorePropertyTests: XCTestCase {
    private let weContract   = Contract(level: 3, suit: .hearts, declarer: .north, tricksTaken: 9)
    private let theyContract = Contract(level: 3, suit: .hearts, declarer: .east,  tricksTaken: 9)

    func testScoreTeamFromDeclarer() {
        let bid = Score.bid(90, weContract)
        XCTAssertEqual(bid.team, .we)
        let theyBid = Score.bid(90, theyContract)
        XCTAssertEqual(theyBid.team, .they)
    }

    func testUnderScoreTeamIsDeclarerTeam() {
        // Score.team returns the declarer's team for all score types.
        // The points distribution (Array<Score>.points) is what routes
        // undertrick penalties to the opposing team.
        let under = Score.under(100, weContract)
        XCTAssertEqual(under.team, .we)   // declarer is north (.we)
    }

    func testHonorsTeam() {
        let h = Score.honors(100, .they, weContract)
        XCTAssertEqual(h.team, .they)
    }

    func testRubberTeam() {
        let r = Score.rubber(700, .we)
        XCTAssertEqual(r.team, .we)
    }

    func testValue() {
        XCTAssertEqual(Score.bid(120, weContract).value,     120)
        XCTAssertEqual(Score.over(30, weContract).value,      30)
        XCTAssertEqual(Score.under(100, weContract).value,   100)
        XCTAssertEqual(Score.slam(500, weContract).value,    500)
        XCTAssertEqual(Score.insult(50, weContract).value,    50)
        XCTAssertEqual(Score.honors(150, .we, weContract).value, 150)
        XCTAssertEqual(Score.rubber(700, .we).value,         700)
    }

    func testScoresUnderTheLine() {
        XCTAssertTrue(Score.bid(90, weContract).scoresUnderTheLine)
        XCTAssertFalse(Score.over(30, weContract).scoresUnderTheLine)
        XCTAssertFalse(Score.under(50, weContract).scoresUnderTheLine)
        XCTAssertFalse(Score.slam(500, weContract).scoresUnderTheLine)
        XCTAssertFalse(Score.insult(50, weContract).scoresUnderTheLine)
        XCTAssertFalse(Score.honors(100, .we, weContract).scoresUnderTheLine)
        XCTAssertFalse(Score.rubber(700, .we).scoresUnderTheLine)
    }

    func testScoresOverTheLine() {
        XCTAssertFalse(Score.bid(90, weContract).scoresOverTheLine)
        XCTAssertTrue(Score.over(30, weContract).scoresOverTheLine)
        XCTAssertTrue(Score.under(50, weContract).scoresOverTheLine)
        XCTAssertTrue(Score.slam(500, weContract).scoresOverTheLine)
    }

    func testLabel() {
        let c = Contract(level: 3, suit: .hearts, declarer: .north, tricksTaken: 9)
        XCTAssertEqual(Score.bid(90, c).label, "")   // doublingLabel is "" trimmed
        XCTAssertEqual(Score.under(100, c).label, "UNDER")
        XCTAssertEqual(Score.slam(500, c).label, "SLAM")
        XCTAssertEqual(Score.honors(100, .we, c).label, "HONORS")
        XCTAssertEqual(Score.rubber(700, .we).label, "RUBBER")
    }

    func testLabelDoubled() {
        let a = Auction(dealer: .north)
        a.bid(Bid(3, .hearts)); a.double(); a.close()
        let c = Contract(auction: a, tricksTaken: 9)!
        XCTAssertEqual(Score.bid(180, c).label,   "×")
        XCTAssertEqual(Score.over(100, c).label,  "OVER ×")
        XCTAssertEqual(Score.under(100, c).label, "UNDER ×")
    }

    func testContractProperty() {
        let c = weContract
        XCTAssertNotNil(Score.bid(90, c).contract)
        XCTAssertNil(Score.rubber(700, .we).contract)
    }
}

// MARK: - Points

final class PointsTests: XCTestCase {
    func testAddition() {
        let a = Points(above: 100, below: 200)
        let b = Points(above:  50, below: 150)
        let sum = a + b
        XCTAssertEqual(sum.above, 150)
        XCTAssertEqual(sum.below, 350)
    }

    func testTotal() {
        let p = Points(above: 300, below: 200)
        XCTAssertEqual(p.total, 500)
    }

    func testAddScoreBid() {
        var p = Points()
        p.addScore(.bid(100, Contract(level: 3, suit: .notrump, declarer: .north, tricksTaken: 9)))
        XCTAssertEqual(p.below, 100)
        XCTAssertEqual(p.above, 0)
    }

    func testAddScoreOver() {
        var p = Points()
        let c = Contract(level: 4, suit: .spades, declarer: .north, tricksTaken: 11)
        p.addScore(.over(30, c))
        XCTAssertEqual(p.above, 30)
        XCTAssertEqual(p.below, 0)
    }

    func testAddScoreUnder() {
        var p = Points()
        let c = Contract(level: 4, suit: .spades, declarer: .north, tricksTaken: 9)
        p.addScore(.under(50, c))
        XCTAssertEqual(p.above, 50)  // undertricks go above for the defending team
    }

    func testAddScoreSlam() {
        var p = Points()
        let c = Contract(level: 6, suit: .hearts, declarer: .north, tricksTaken: 12)
        p.addScore(.slam(500, c))
        XCTAssertEqual(p.above, 500)
        XCTAssertEqual(p.below, 0)
    }

    func testAddScoreRubber() {
        var p = Points()
        p.addScore(.rubber(700, .we))
        XCTAssertEqual(p.above, 700)
        XCTAssertEqual(p.below, 0)
    }
}

// MARK: - Score Array Points Distribution

final class ScoreArrayTests: XCTestCase {

    func testPointsDistributedByTeam() {
        // 3H made by north (we): 90 below for we
        let c = Contract(level: 3, suit: .hearts, declarer: .north, tricksTaken: 9)
        let pts = c.scores.points
        XCTAssertEqual(pts.we.below,   90)
        XCTAssertEqual(pts.they.below, 0)
        XCTAssertEqual(pts.we.above,   0)
        XCTAssertEqual(pts.they.above, 0)
    }

    func testUndertricksGoToOpponent() {
        // 3H down 2 by north (we fail): penalty points go to they
        let c = Contract(level: 3, suit: .hearts, declarer: .north, tricksTaken: 7, vulnerable: false)
        let pts = c.scores.points
        XCTAssertEqual(pts.they.above, 100)   // 2 × 50
        XCTAssertEqual(pts.we.above,   0)
        XCTAssertEqual(pts.we.below,   0)
    }

    func testPointsForTeamMethod() {
        let c = Contract(level: 4, suit: .spades, declarer: .north, tricksTaken: 10)
        let wePts = c.scores.points(for: .we)
        XCTAssertEqual(wePts.below, 120)
        let theyPts = c.scores.points(for: .they)
        XCTAssertEqual(theyPts.below, 0)
    }

    func testUnderTheLine() {
        let c = Contract(level: 3, suit: .hearts, declarer: .north, tricksTaken: 10)  // +1
        let under = c.scores.underTheLine()
        XCTAssertEqual(under.count, 1)
        XCTAssertEqual(under[0].value, 90)
    }

    func testOverTheLine() {
        let c = Contract(level: 3, suit: .hearts, declarer: .north, tricksTaken: 10)  // +1
        let over = c.scores.overTheLine()
        XCTAssertEqual(over.count, 1)
        XCTAssertEqual(over[0].value, 30)
    }

    func testForTeam() {
        // north bids 3H (we), east bids 2S (they)
        let weC   = Contract(level: 3, suit: .hearts, declarer: .north, tricksTaken: 9)
        let theyC = Contract(level: 2, suit: .spades, declarer: .east,  tricksTaken: 8)
        let allScores = weC.scores + theyC.scores
        let weScores   = allScores.forTeam(.we)
        let theyScores = allScores.forTeam(.they)
        XCTAssertEqual(weScores.count,   1)
        XCTAssertEqual(theyScores.count, 1)
    }

    func testForTeamIncludesUndertrickPenalty() {
        // 3H down 1 by north (we fail) → they score the penalty
        let c = Contract(level: 3, suit: .hearts, declarer: .north, tricksTaken: 8, vulnerable: false)
        let theyScores = c.scores.forTeam(.they)
        XCTAssertEqual(theyScores.count, 1)
        XCTAssertEqual(theyScores[0].value, 50)
    }
}

// MARK: - Full Contract Score Compositions

final class ContractScoreCompositionTests: XCTestCase {

    // 3NT made: 100 below for we
    func testThreeNoTrumpMade() {
        let c = contract(level: 3, suit: .notrump, tricksTaken: 9)
        let scores = c.scores
        XCTAssertEqual(scores.count, 1)
        if case let .bid(v, _) = scores[0] {
            XCTAssertEqual(v, 100)
        } else { XCTFail("expected bid") }
    }

    // 4S made exactly: 120 below, no overtricks
    func testFourSpadesMadeExactly() {
        let c = contract(level: 4, suit: .spades, tricksTaken: 10)
        let scores = c.scores
        XCTAssertEqual(scores.count, 1)
        XCTAssertEqual(scores[0].value, 120)
    }

    // 4S +1 overtrick: 120 below + 30 over
    func testFourSpadesPlusOne() {
        let c = contract(level: 4, suit: .spades, tricksTaken: 11)
        let scores = c.scores
        XCTAssertEqual(scores.count, 2)
        let bid  = scores.first { if case .bid   = $0 { return true }; return false }
        let over = scores.first { if case .over  = $0 { return true }; return false }
        XCTAssertEqual(bid?.value,  120)
        XCTAssertEqual(over?.value,  30)
    }

    // 6H not vul made: 180 bid + 500 slam
    func testSmallSlamHearts() {
        let c = contract(level: 6, suit: .hearts, tricksTaken: 12, vulnerable: false)
        let scores = c.scores
        let bid  = scores.first { if case .bid  = $0 { return true }; return false }
        let slam = scores.first { if case .slam = $0 { return true }; return false }
        XCTAssertEqual(bid?.value,  180)
        XCTAssertEqual(slam?.value, 500)
    }

    // 7NT vul made: 220 bid + 1500 slam
    func testGrandSlamNoTrumpVul() {
        let c = contract(level: 7, suit: .notrump, tricksTaken: 13, vulnerable: true)
        let scores = c.scores
        let bid  = scores.first { if case .bid  = $0 { return true }; return false }
        let slam = scores.first { if case .slam = $0 { return true }; return false }
        XCTAssertEqual(bid?.value,  220)
        XCTAssertEqual(slam?.value, 1500)
    }

    // 4H doubled made: 240 bid + 50 insult
    func testFourHeartsDoubledMade() {
        let c = contract(level: 4, suit: .hearts, doubled: true, tricksTaken: 10, vulnerable: false)
        let scores = c.scores
        let bid    = scores.first { if case .bid    = $0 { return true }; return false }
        let insult = scores.first { if case .insult = $0 { return true }; return false }
        XCTAssertEqual(bid?.value,    240)
        XCTAssertEqual(insult?.value,  50)
        XCTAssertNil(scores.first { if case .under = $0 { return true }; return false })
    }

    // 4H redoubled made +1 not vul: 480 bid + 100 insult + 200 over
    func testFourHeartsRedoubledPlusOne() {
        let c = contract(level: 4, suit: .hearts, redoubled: true, tricksTaken: 11, vulnerable: false)
        let scores = c.scores
        let bid    = scores.first { if case .bid    = $0 { return true }; return false }
        let insult = scores.first { if case .insult = $0 { return true }; return false }
        let over   = scores.first { if case .over   = $0 { return true }; return false }
        XCTAssertEqual(bid?.value,    480)
        XCTAssertEqual(insult?.value, 100)
        XCTAssertEqual(over?.value,   200)
    }
}

// MARK: - AuctionResult Scores

final class AuctionResultTests: XCTestCase {
    func testMissDealHasNoScores() {
        let r = AuctionResult.missDeal(.north)
        XCTAssertTrue(r.scores.isEmpty)
    }

    func testPassHandHasNoScores() {
        let a = Auction(dealer: .north)
        a.close()
        let r = AuctionResult.pass(a)
        XCTAssertTrue(r.scores.isEmpty)
    }

    func testContractResultScores() {
        let c = Contract(level: 3, suit: .hearts, declarer: .north, tricksTaken: 9)
        let r = AuctionResult.contract(Auction(), c)
        XCTAssertFalse(r.scores.isEmpty)
        XCTAssertEqual(r.scores[0].value, 90)
    }

    func testDealerProperty() {
        XCTAssertEqual(AuctionResult.missDeal(.east).dealer, .east)

        let a = Auction(dealer: .south)
        XCTAssertEqual(AuctionResult.pass(a).dealer, .south)
        XCTAssertEqual(AuctionResult.contract(a, Contract(level: 1, suit: .clubs, declarer: .south, tricksTaken: 7)).dealer, .south)
    }
}

// MARK: - Game State

final class GameTests: XCTestCase {

    // Helper to build a history from (level, suit, declarer, tricksTaken) tuples
    private func history(_ hands: [(Int, Suit, Position, Int)]) -> [AuctionResult] {
        hands.map { (level, suit, declarer, tricks) in
            .contract(Auction(), Contract(level: level, suit: suit, declarer: declarer, tricksTaken: tricks))
        }
    }

    func testEmptyHistoryHasNoGames() {
        XCTAssertTrue([AuctionResult]().games.isEmpty)
    }

    func testInitialGameIsNone() {
        let h = history([(1, .clubs, .north, 6)])  // 1C down 1
        let games = h.games
        XCTAssertEqual(games.count, 1)
        if case .none = games[0] { } else { XCTFail("expected .none, got \(games[0])") }
    }

    func testPartialGameState() {
        // 3C by we = 60 below, not yet a game
        let h = history([(3, .clubs, .north, 9)])
        let games = h.games
        XCTAssertEqual(games.count, 1)
        if case .partial = games[0] { } else { XCTFail("expected .partial") }
    }

    func testGameComplete() {
        // 3NT by we = 100 below → game!
        let h = history([(3, .notrump, .north, 9)])
        let games = h.games
        XCTAssertEqual(games.count, 1)
        if case let .complete(team, _) = games[0] {
            XCTAssertEqual(team, .we)
        } else { XCTFail("expected .complete, got \(games[0])") }
    }

    func testGameCompleteWithAccumulation() {
        // 2C (40) + 3C (60) = 100 → game
        let h = history([(2, .clubs, .north, 8), (3, .clubs, .north, 9)])
        let games = h.games
        XCTAssertEqual(games.count, 1)
        if case let .complete(team, _) = games[0] {
            XCTAssertEqual(team, .we)
        } else { XCTFail("expected .complete") }
    }

    func testTwoGamesOnBoard() {
        // Game 1: 3NT by we; Game 2: starts fresh
        let h = history([
            (3, .notrump, .north, 9),   // game 1 complete (we)
            (2, .clubs, .north, 8),     // start of game 2 (partial)
        ])
        let games = h.games
        XCTAssertEqual(games.count, 2)
        if case .complete = games[0] { } else { XCTFail("game 1 should be complete") }
        if case .partial  = games[1] { } else { XCTFail("game 2 should be partial") }
    }

    func testRubberTwoGames() {
        // We win game 1 and game 2 → rubber
        let h = history([
            (3, .notrump, .north, 9),  // game 1 complete (we)
            (3, .notrump, .north, 9),  // game 2 complete (we) → rubber
        ])
        let games = h.games
        let last = games.last!
        if case let .rubber(team, _) = last {
            XCTAssertEqual(team, .we)
        } else { XCTFail("expected .rubber, got \(last)") }
    }

    func testRubberThreeGames() {
        // they win game 1, we win game 2 and 3 → rubber after 3 games
        let h = history([
            (3, .notrump, .east,  9),  // game 1: they
            (3, .notrump, .north, 9),  // game 2: we
            (3, .notrump, .north, 9),  // game 3: we → rubber
        ])
        let games = h.games
        let last = games.last!
        if case let .rubber(team, _) = last {
            XCTAssertEqual(team, .we)
        } else { XCTFail("expected .rubber") }
        XCTAssertEqual(games.count, 3)
    }

    func testVulnerableTeamsAfterOneGame() {
        let h = history([(3, .notrump, .north, 9)])
        let games = h.games
        XCTAssertTrue(games.vulnerableTeams.contains(.we))
        XCTAssertFalse(games.vulnerableTeams.contains(.they))
    }

    func testVulnerableTeamsAfterBothTeamsWinOneGame() {
        let h = history([
            (3, .notrump, .north, 9),   // we win game 1
            (3, .notrump, .east,  9),   // they win game 2
        ])
        let games = h.games
        XCTAssertTrue(games.vulnerableTeams.contains(.we))
        XCTAssertTrue(games.vulnerableTeams.contains(.they))
    }

    func testVulnerableTeamsClearedAfterRubber() {
        let h = history([
            (3, .notrump, .north, 9),
            (3, .notrump, .north, 9),  // rubber
        ])
        let games = h.games
        XCTAssertTrue(games.vulnerableTeams.isEmpty)
    }

    func testPartialScoresResetAfterGame() {
        // they have 60 below in game 1 (3C made), then we make game with 3NT
        // In game 2 they should start from 0
        let h: [AuctionResult] = [
            .contract(Auction(), Contract(level: 3, suit: .clubs, declarer: .east,  tricksTaken: 9)),  // they: 60
            .contract(Auction(), Contract(level: 3, suit: .notrump, declarer: .north, tricksTaken: 9)), // we: 100 → game 1 complete
        ]
        let games = h.games
        XCTAssertEqual(games.count, 1)
        if case let .complete(winner, _) = games[0] {
            XCTAssertEqual(winner, .we)
        } else { XCTFail() }
    }
}

// MARK: - Rubber Scoring

final class RubberTests: XCTestCase {

    func testCurrentDealerAdvancesWithHistory() {
        let rubber = Rubber(dealer: .north)
        XCTAssertEqual(rubber.currentDealer, .north)
        rubber.addAuctionResult(.missDeal(.north))
        XCTAssertEqual(rubber.currentDealer, .east)
        rubber.addAuctionResult(.pass(Auction(dealer: .east)))
        XCTAssertEqual(rubber.currentDealer, .south)
    }

    func testIsNotFinishedInitially() {
        XCTAssertFalse(Rubber().isFinished)
    }

    func testRubberBonus700ForTwoZeroWin() {
        // We win 2-0 (no games for them) → 700 bonus
        let rubber = Rubber(
            history: [
                .contract(Auction(), Contract(level: 3, suit: .notrump, declarer: .north, tricksTaken: 9)),
                .contract(Auction(), Contract(level: 3, suit: .notrump, declarer: .north, tricksTaken: 9)),
            ]
        )
        XCTAssertTrue(rubber.isFinished)
        let rubberScores = rubber.scores.filter { if case .rubber = $0 { return true }; return false }
        XCTAssertEqual(rubberScores.count, 1)
        XCTAssertEqual(rubberScores[0].value, 700)
        XCTAssertEqual(rubberScores[0].team, .we)
    }

    func testRubberBonus500ForTwoOneWin() {
        // they win game 1, we win games 2 and 3 → 500 bonus for we
        let rubber = Rubber(
            history: [
                .contract(Auction(), Contract(level: 3, suit: .notrump, declarer: .east,  tricksTaken: 9)),
                .contract(Auction(), Contract(level: 3, suit: .notrump, declarer: .north, tricksTaken: 9)),
                .contract(Auction(), Contract(level: 3, suit: .notrump, declarer: .north, tricksTaken: 9, vulnerable: true)),
            ]
        )
        XCTAssertTrue(rubber.isFinished)
        let rubberScores = rubber.scores.filter { if case .rubber = $0 { return true }; return false }
        XCTAssertEqual(rubberScores.count, 1)
        XCTAssertEqual(rubberScores[0].value, 500)
        XCTAssertEqual(rubberScores[0].team, .we)
    }

    func testWinningTeam() {
        let rubber = Rubber(
            history: [
                .contract(Auction(), Contract(level: 3, suit: .notrump, declarer: .north, tricksTaken: 9)),
                .contract(Auction(), Contract(level: 3, suit: .notrump, declarer: .north, tricksTaken: 9)),
            ]
        )
        XCTAssertEqual(rubber.winningTeam, .we)
    }

    func testIsVulnerable() {
        let rubber = Rubber(
            history: [
                .contract(Auction(), Contract(level: 3, suit: .notrump, declarer: .north, tricksTaken: 9)),
            ]
        )
        XCTAssertTrue(rubber.isVulnerable(.we))
        XCTAssertFalse(rubber.isVulnerable(.they))
    }

    func testReplaceContractAdjustsVulnerability() {
        // _adjustContracts is triggered by replaceContract. Set up a rubber where
        // game1 completes (we win), then game2 starts. game2Contract is initially
        // entered as non-vulnerable. After replacing game1 (triggering adjustment),
        // game2Contract should be updated to vulnerable = true.
        let game1Contract = Contract(level: 3, suit: .notrump, declarer: .north, tricksTaken: 9, vulnerable: false)
        let game2Contract = Contract(level: 2, suit: .hearts, declarer: .north, tricksTaken: 8, vulnerable: false)

        let rubber = Rubber(history: [
            .contract(Auction(), game1Contract),
            .contract(Auction(), game2Contract),
        ])

        // Before replaceContract, vulnerable flag is as originally set
        if case let .contract(_, c) = rubber.history[1] {
            XCTAssertFalse(c.vulnerable, "Before adjustment, game2 should be non-vulnerable")
        }

        // Replace game1 with an equivalent result — triggers _adjustContracts(from:0)
        rubber.replaceContract(game1Contract, with: .contract(Auction(), game1Contract))

        // After adjustment, game2 should be marked vulnerable (we won game 1)
        if case let .contract(_, c) = rubber.history[1] {
            XCTAssertTrue(c.vulnerable, "After adjustment, game2 should be vulnerable")
        } else {
            XCTFail("Expected contract at index 1")
        }
    }

    func testPartialScore() {
        // 2H made (60 below) - not a game yet
        let rubber = Rubber(
            history: [
                .contract(Auction(), Contract(level: 2, suit: .hearts, declarer: .north, tricksTaken: 8)),
            ]
        )
        XCTAssertEqual(rubber.partialScore(for: .we), 60)
        XCTAssertEqual(rubber.partialScore(for: .they), 0)
    }

    func testPointsForTeam() {
        let rubber = Rubber(
            history: [
                .contract(Auction(), Contract(level: 3, suit: .notrump, declarer: .north, tricksTaken: 9)),
                .contract(Auction(), Contract(level: 3, suit: .notrump, declarer: .north, tricksTaken: 9)),
            ]
        )
        let wePts = rubber.points(for: .we)
        XCTAssertEqual(wePts.below, 200)  // 100 + 100 below
        XCTAssertEqual(wePts.above, 700)  // rubber bonus
    }

    func testCodableRoundtrip() throws {
        let rubber = Rubber.mock
        let data = try JSONEncoder().encode(rubber)
        let decoded = try JSONDecoder().decode(Rubber.self, from: data)
        XCTAssertEqual(decoded.id, rubber.id)
        XCTAssertEqual(decoded.history.count, rubber.history.count)
    }
}
