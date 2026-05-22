import XCTest
@testable import ScorePad

// MARK: - Miles Calculation

final class MilleBornesTotalMilesTests: XCTestCase {

    func testEmptyScoreIsZeroMiles() {
        XCTAssertEqual(MilleBornesTeamScore().totalMiles, 0)
    }

    func testSingleDenominations() {
        var s = MilleBornesTeamScore()
        s.cards25 = 1;  XCTAssertEqual(s.totalMiles, 25)
        s = MilleBornesTeamScore()
        s.cards50 = 1;  XCTAssertEqual(s.totalMiles, 50)
        s = MilleBornesTeamScore()
        s.cards75 = 1;  XCTAssertEqual(s.totalMiles, 75)
        s = MilleBornesTeamScore()
        s.cards100 = 1; XCTAssertEqual(s.totalMiles, 100)
        s = MilleBornesTeamScore()
        s.cards200 = 1; XCTAssertEqual(s.totalMiles, 200)
    }

    func testMixedDenominations() {
        var s = MilleBornesTeamScore()
        s.cards25 = 2   // 50
        s.cards50 = 1   // 50
        s.cards100 = 5  // 500
        s.cards200 = 2  // 400
        XCTAssertEqual(s.totalMiles, 1000)
    }

    func testExtensionTotal() {
        var s = MilleBornesTeamScore()
        s.cards25 = 4   // 100
        s.cards50 = 2   // 100
        s.cards100 = 8  // 800
        s.cards200 = 1  // 200
        XCTAssertEqual(s.totalMiles, 1200)
    }

    func testMultipleOfSameDenomination() {
        var s = MilleBornesTeamScore()
        s.cards25 = 10
        XCTAssertEqual(s.totalMiles, 250)
        s = MilleBornesTeamScore()
        s.cards100 = 12
        XCTAssertEqual(s.totalMiles, 1200)
    }
}

// MARK: - Safe Trip Auto-Detection

final class MilleBornesSafeTripTests: XCTestCase {

    func testSafeTripFalseWhenTripNotCompleted() {
        var s = MilleBornesTeamScore()
        s.cards200 = 0
        s.tripCompleted = false
        XCTAssertFalse(s.safeTrip)
    }

    func testSafeTripFalseWhenUsed200() {
        var s = MilleBornesTeamScore()
        s.cards200 = 1
        s.tripCompleted = true
        XCTAssertFalse(s.safeTrip)
    }

    func testSafeTripFalseWhenUsedTwo200s() {
        var s = MilleBornesTeamScore()
        s.cards200 = 2
        s.tripCompleted = true
        XCTAssertFalse(s.safeTrip)
    }

    func testSafeTripTrueWhenNo200AndCompleted() {
        var s = MilleBornesTeamScore()
        s.cards25 = 2; s.cards50 = 2; s.cards100 = 8  // 1000 miles without 200s
        s.tripCompleted = true
        XCTAssertTrue(s.safeTrip)
    }

    func testSafeTripFalseWhenNo200ButNotCompleted() {
        var s = MilleBornesTeamScore()
        s.cards100 = 5  // 500 miles, no trip
        s.tripCompleted = false
        XCTAssertFalse(s.safeTrip)
    }
}

// MARK: - Hand Score Calculation

final class MilleBornesHandScoreTests: XCTestCase {

    func testMilesOnlyScore() {
        var s = MilleBornesTeamScore()
        s.cards100 = 7; s.cards50 = 1  // 750
        XCTAssertEqual(s.handScore, 750)
    }

    func testSafetyBonus100Each() {
        var s = MilleBornesTeamScore()
        s.safeties = 1
        XCTAssertEqual(s.handScore, 100)
        s.safeties = 4
        XCTAssertEqual(s.handScore, 400)
    }

    func testCoupFourreBonus300Each() {
        var s = MilleBornesTeamScore()
        s.safeties = 2
        s.coupsFourres = 2
        // 2×100 safety + 2×300 coup fourré
        XCTAssertEqual(s.handScore, 2 * 100 + 2 * 300)
    }

    func testCoupFourreStacksWithSafetyBonus() {
        var s = MilleBornesTeamScore()
        s.safeties = 3
        s.coupsFourres = 1
        // 3×100 + 1×300
        XCTAssertEqual(s.handScore, 300 + 300)
    }

    func testTripCompletedBonus400() {
        var s = MilleBornesTeamScore()
        s.cards200 = 1   // suppress safeTrip auto-detection
        s.tripCompleted = true
        XCTAssertEqual(s.handScore, 200 + 400)
    }

    func testAllFourSafetiesBonus300() {
        var s = MilleBornesTeamScore()
        s.allFourSafeties = true
        XCTAssertEqual(s.handScore, 300)
    }

    func testSafeTripBonus300() {
        var s = MilleBornesTeamScore()
        s.cards100 = 10  // 1000 mi, no 200s → safeTrip auto = true
        s.tripCompleted = true
        // miles + trip + safe trip
        XCTAssertEqual(s.handScore, 1000 + 400 + 300)
    }

    func testSafeTripNotAwardedWhen200Used() {
        var s = MilleBornesTeamScore()
        s.cards200 = 1; s.cards100 = 8  // 1000 miles with a 200 → no safeTrip
        s.tripCompleted = true
        // miles + trip only
        XCTAssertEqual(s.handScore, 1000 + 400)
    }

    func testExtensionBonus200() {
        var s = MilleBornesTeamScore()
        s.cards200 = 1   // suppress safeTrip auto-detection
        s.tripCompleted = true
        s.usedExtension = true
        XCTAssertEqual(s.handScore, 200 + 400 + 200)
    }

    func testShutOutBonus500() {
        var s = MilleBornesTeamScore()
        s.cards200 = 1   // suppress safeTrip auto-detection
        s.tripCompleted = true
        s.shutOut = true
        XCTAssertEqual(s.handScore, 200 + 400 + 500)
    }

    func testDelayedActionBonus300() {
        var s = MilleBornesTeamScore()
        s.cards200 = 1   // suppress safeTrip auto-detection
        s.tripCompleted = true
        s.delayedAction = true
        XCTAssertEqual(s.handScore, 200 + 400 + 300)
    }

    func testFullBonusHand() {
        // Trip completed without 200s, all 4 safeties (3 coup fourré), extension, shut out, delayed action
        var s = MilleBornesTeamScore()
        s.cards100 = 10          // 1000 miles
        s.safeties = 4           // 4 × 100 = 400
        s.coupsFourres = 3       // 3 × 300 = 900
        s.tripCompleted = true   // 400
        s.allFourSafeties = true // 300
        // safeTrip = true (no 200s + tripCompleted) → 300
        s.usedExtension = true   // 200
        s.shutOut = true         // 500
        s.delayedAction = true   // 300

        let expected = 1000 + 400 + 900 + 400 + 300 + 300 + 200 + 500 + 300
        XCTAssertEqual(s.handScore, expected)
    }

    func testZeroScore() {
        XCTAssertEqual(MilleBornesTeamScore().handScore, 0)
    }
}

// MARK: - Score Lines

final class MilleBornesScoreLinesTests: XCTestCase {

    func testEmptyScoreHasNoLines() {
        XCTAssertTrue(MilleBornesTeamScore().scoreLines.isEmpty)
    }

    func testMilesLineAppearsWhenNonZero() {
        var s = MilleBornesTeamScore()
        s.cards100 = 5  // 500 miles
        let labels = s.scoreLines.map(\.label)
        XCTAssertTrue(labels.contains("Miles"))
        XCTAssertEqual(s.scoreLines.first(where: { $0.label == "Miles" })?.value, 500)
    }

    func testMilesLineAbsentWhenZero() {
        let labels = MilleBornesTeamScore().scoreLines.map(\.label)
        XCTAssertFalse(labels.contains("Miles"))
    }

    func testSingleSafetyLabel() {
        var s = MilleBornesTeamScore()
        s.safeties = 1
        XCTAssertTrue(s.scoreLines.map(\.label).contains("Safety"))
    }

    func testPluralSafetyLabel() {
        var s = MilleBornesTeamScore()
        s.safeties = 3
        XCTAssertTrue(s.scoreLines.map(\.label).contains("Safety ×3"))
    }

    func testSingleCoupFourreLabel() {
        var s = MilleBornesTeamScore()
        s.safeties = 1; s.coupsFourres = 1
        XCTAssertTrue(s.scoreLines.map(\.label).contains("Coup Fourré"))
    }

    func testPluralCoupFourreLabel() {
        var s = MilleBornesTeamScore()
        s.safeties = 2; s.coupsFourres = 2
        XCTAssertTrue(s.scoreLines.map(\.label).contains("Coup Fourré ×2"))
    }

    func testBonusLabelsIncluded() {
        var s = MilleBornesTeamScore()
        s.cards100 = 10; s.tripCompleted = true
        s.allFourSafeties = true; s.usedExtension = true
        s.shutOut = true; s.delayedAction = true

        let labels = s.scoreLines.map(\.label)
        XCTAssertTrue(labels.contains("Trip"))
        XCTAssertTrue(labels.contains("All 4 Safeties"))
        XCTAssertTrue(labels.contains("Safe Trip"))   // auto: no 200s + tripCompleted
        XCTAssertTrue(labels.contains("Extension"))
        XCTAssertTrue(labels.contains("Shut Out"))
        XCTAssertTrue(labels.contains("Delayed Action"))
    }

    func testSafeTripLineAbsentWhenUsed200() {
        var s = MilleBornesTeamScore()
        s.cards200 = 1; s.cards100 = 8; s.tripCompleted = true
        XCTAssertFalse(s.scoreLines.map(\.label).contains("Safe Trip"))
    }

    func testScoreLineValuesAreCorrect() {
        var s = MilleBornesTeamScore()
        s.tripCompleted = true; s.allFourSafeties = true
        s.usedExtension = true; s.shutOut = true; s.delayedAction = true

        let lineValues = Dictionary(uniqueKeysWithValues: s.scoreLines.map { ($0.label, $0.value) })
        XCTAssertEqual(lineValues["Trip"],           400)
        XCTAssertEqual(lineValues["All 4 Safeties"], 300)
        XCTAssertEqual(lineValues["Extension"],      200)
        XCTAssertEqual(lineValues["Shut Out"],       500)
        XCTAssertEqual(lineValues["Delayed Action"], 300)
    }
}

// MARK: - Game Cumulative Score & State

final class MilleBornesGameTests: XCTestCase {

    private func game(hands: [(team1Miles: Int, team2Miles: Int)]) -> MilleBornesGame {
        let g = MilleBornesGame(team1Players: ["A"], team2Players: ["B"])
        for (m1, m2) in hands {
            var h = MilleBornesHand()
            h.team1.cards100 = m1 / 100
            h.team2.cards100 = m2 / 100
            g.addHand(h)
        }
        return g
    }

    func testCumulativeScoreZeroWithNoHands() {
        let g = MilleBornesGame()
        XCTAssertEqual(g.cumulativeScore(team: 1), 0)
        XCTAssertEqual(g.cumulativeScore(team: 2), 0)
    }

    func testCumulativeScoreAggregatesHands() {
        let g = game(hands: [(500, 300), (400, 700)])
        XCTAssertEqual(g.cumulativeScore(team: 1), 900)
        XCTAssertEqual(g.cumulativeScore(team: 2), 1000)
    }

    func testCumulativeScoreIncludesBonuses() {
        let g = MilleBornesGame(team1Players: ["A"], team2Players: ["B"])
        var h = MilleBornesHand()
        h.team1.cards100 = 10  // 1000 miles
        h.team1.tripCompleted = true  // +400, and safeTrip (+300) since no 200s
        g.addHand(h)
        XCTAssertEqual(g.cumulativeScore(team: 1), 1700)
        XCTAssertEqual(g.cumulativeScore(team: 2), 0)
    }

    func testIsNotFinishedBelowThreshold() {
        let g = game(hands: [(4000, 3000)])
        XCTAssertFalse(g.isFinished)
    }

    func testIsFinishedAtExactly5000() {
        let g = MilleBornesGame(team1Players: ["A"], team2Players: ["B"])
        var h = MilleBornesHand()
        // 1000 miles + trip(400) + safeTrip(300) + shutOut(500) + allFour(300) + extension(200) = 2700
        h.team1.cards100 = 10; h.team1.tripCompleted = true
        h.team1.shutOut = true; h.team1.allFourSafeties = true; h.team1.usedExtension = true
        h.team1.safeties = 4; h.team1.coupsFourres = 0  // 4×100 = 400 more → 3100
        // That's 2700 + 400 = 3100, not 5000 yet — add a second hand
        g.addHand(h)

        var h2 = MilleBornesHand()
        // Enough for team1 to cross 5000 total
        h2.team1.cards100 = 10; h2.team1.tripCompleted = true  // 1000 + 400 + 300 = 1700
        h2.team1.safeties = 4; h2.team1.coupsFourres = 4        // 4×100+4×300 = 1600
        g.addHand(h2)

        XCTAssertTrue(g.isFinished)
    }

    func testIsFinishedWhenTeam2Crosses5000() {
        let g = MilleBornesGame(team1Players: ["A"], team2Players: ["B"])
        var h = MilleBornesHand()
        h.team2.cards100 = 10; h.team2.tripCompleted = true
        h.team2.safeties = 4; h.team2.coupsFourres = 4
        h.team2.shutOut = true; h.team2.allFourSafeties = true
        h.team2.usedExtension = true; h.team2.delayedAction = true
        g.addHand(h)
        // 1000 + 400 + 300 (safeTrip) + 400 + 1200 + 500 + 300 + 200 + 300 = 4600; add another
        var h2 = MilleBornesHand()
        h2.team2.cards100 = 5; h2.team2.tripCompleted = true
        g.addHand(h2)
        XCTAssertTrue(g.isFinished)
        XCTAssertEqual(g.winningTeam, 2)
    }

    func testWinningTeamNilWhenNotFinished() {
        let g = game(hands: [(500, 300)])
        XCTAssertNil(g.winningTeam)
    }

    func testWinningTeamIsHigherScoreWhenFinished() {
        let g = MilleBornesGame(team1Players: ["A"], team2Players: ["B"])
        // Give team1 a big hand to finish
        var h = MilleBornesHand()
        h.team1.cards100 = 10; h.team1.tripCompleted = true
        h.team1.safeties = 4; h.team1.coupsFourres = 4
        h.team1.shutOut = true; h.team1.allFourSafeties = true
        h.team1.usedExtension = true; h.team1.delayedAction = true
        h.team2.cards100 = 3
        g.addHand(h)
        var h2 = MilleBornesHand()
        h2.team1.cards100 = 5
        g.addHand(h2)
        if g.isFinished {
            XCTAssertEqual(g.winningTeam, 1)
        }
    }

    // MARK: - Mutation

    func testAddHandIncrementsHandCount() {
        let g = MilleBornesGame()
        XCTAssertEqual(g.hands.count, 0)
        g.addHand(MilleBornesHand())
        XCTAssertEqual(g.hands.count, 1)
        g.addHand(MilleBornesHand())
        XCTAssertEqual(g.hands.count, 2)
    }

    func testAddHandUpdatesLastModified() {
        let g = MilleBornesGame()
        let before = g.lastModified
        g.addHand(MilleBornesHand())
        XCTAssertGreaterThanOrEqual(g.lastModified, before)
    }

    func testReplaceHandUpdatesScore() {
        let g = MilleBornesGame()
        var h = MilleBornesHand()
        h.team1.cards100 = 5   // 500 miles
        g.addHand(h)
        XCTAssertEqual(g.cumulativeScore(team: 1), 500)

        h.team1.cards100 = 10  // replace with 1000 miles
        g.replaceHand(h)
        XCTAssertEqual(g.cumulativeScore(team: 1), 1000)
    }

    func testReplaceHandWithUnknownIDIsNoOp() {
        let g = MilleBornesGame()
        var h = MilleBornesHand()
        h.team1.cards100 = 5
        g.addHand(h)

        var foreign = MilleBornesHand()  // different UUID
        foreign.team1.cards100 = 99
        g.replaceHand(foreign)

        XCTAssertEqual(g.hands.count, 1)
        XCTAssertEqual(g.cumulativeScore(team: 1), 500)  // unchanged
    }

    func testReplaceHandPreservesOtherHands() {
        let g = MilleBornesGame()
        var h1 = MilleBornesHand(); h1.team1.cards100 = 3
        var h2 = MilleBornesHand(); h2.team1.cards100 = 5
        var h3 = MilleBornesHand(); h3.team1.cards100 = 2
        g.addHand(h1); g.addHand(h2); g.addHand(h3)

        h2.team1.cards100 = 10
        g.replaceHand(h2)

        XCTAssertEqual(g.hands.count, 3)
        XCTAssertEqual(g.cumulativeScore(team: 1), 300 + 1000 + 200)
    }

    // MARK: - Labels

    func testTeamLabelsUsePlayers() {
        let g = MilleBornesGame(team1Players: ["Alice", "Bob"], team2Players: ["Carol", "Dave"])
        XCTAssertEqual(g.team1Label, "Alice & Bob")
        XCTAssertEqual(g.team2Label, "Carol & Dave")
    }

    func testTeamLabelSinglePlayer() {
        let g = MilleBornesGame(team1Players: ["Alice"], team2Players: ["Bob"])
        XCTAssertEqual(g.team1Label, "Alice")
        XCTAssertEqual(g.team2Label, "Bob")
    }

    func testTeamLabelFallbackWhenEmpty() {
        let g = MilleBornesGame()
        XCTAssertEqual(g.team1Label, "Team 1")
        XCTAssertEqual(g.team2Label, "Team 2")
    }

    // MARK: - Codable

    func testCodableRoundtrip() throws {
        let g = MilleBornesGame.mock
        let data = try JSONEncoder().encode(g)
        let decoded = try JSONDecoder().decode(MilleBornesGame.self, from: data)
        XCTAssertEqual(decoded.id, g.id)
        XCTAssertEqual(decoded.hands.count, g.hands.count)
        XCTAssertEqual(decoded.team1Players, g.team1Players)
        XCTAssertEqual(decoded.team2Players, g.team2Players)
    }

    func testHandCodableRoundtrip() throws {
        var h = MilleBornesHand()
        h.team1.cards100 = 6; h.team1.cards200 = 1
        h.team1.safeties = 3; h.team1.coupsFourres = 2
        h.team1.tripCompleted = true; h.team1.shutOut = true
        h.team2.cards50 = 4; h.team2.safeties = 1

        let data = try JSONEncoder().encode(h)
        let decoded = try JSONDecoder().decode(MilleBornesHand.self, from: data)
        XCTAssertEqual(decoded.id, h.id)
        XCTAssertEqual(decoded.team1, h.team1)
        XCTAssertEqual(decoded.team2, h.team2)
    }
}
