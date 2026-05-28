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
        s.cards200 = 0  // 0 miles → tripCompleted = false
        XCTAssertFalse(s.safeTrip(isTwoPlayerGame: true))
    }

    func testSafeTripFalseWhenUsed200() {
        var s = MilleBornesTeamScore()
        s.cards200 = 1; s.cards100 = 5  // 700 miles → tripCompleted, but used a 200
        XCTAssertFalse(s.safeTrip(isTwoPlayerGame: true))
    }

    func testSafeTripFalseWhenUsedTwo200s() {
        var s = MilleBornesTeamScore()
        s.cards200 = 2; s.cards100 = 6  // 1000 miles → tripCompleted, but used 200s
        XCTAssertFalse(s.safeTrip(isTwoPlayerGame: true))
    }

    func testSafeTripTrueWhenNo200AndCompleted() {
        var s = MilleBornesTeamScore()
        s.cards100 = 7  // exactly 700 miles, no 200s → tripCompleted + safeTrip
        XCTAssertTrue(s.safeTrip(isTwoPlayerGame: true))
    }

    func testSafeTripFalseWhenNo200ButNotCompleted() {
        var s = MilleBornesTeamScore()
        s.cards100 = 5  // 500 miles — not 700 or 1000, so tripCompleted = false
        XCTAssertFalse(s.safeTrip(isTwoPlayerGame: true))
    }
}

// MARK: - Trip Completion Rules (2-player vs 4-player)

final class MilleBornesTripCompletedTests: XCTestCase {

    func testTwoPlayerTripAt700() {
        var s = MilleBornesTeamScore()
        s.cards100 = 7  // 700 miles
        XCTAssertTrue(s.tripCompleted(isTwoPlayerGame: true))
        XCTAssertFalse(s.tripCompleted(isTwoPlayerGame: false))  // 4-player needs 1000
    }

    func testFourPlayerTripAt1000() {
        var s = MilleBornesTeamScore()
        s.cards100 = 10  // 1000 miles
        XCTAssertTrue(s.tripCompleted(isTwoPlayerGame: false))
        XCTAssertTrue(s.tripCompleted(isTwoPlayerGame: true))
    }

    func testFourPlayerNoTripAt700() {
        var s = MilleBornesTeamScore()
        s.cards100 = 7  // 700 miles — a win in 2-player, not in 4-player
        XCTAssertFalse(s.tripCompleted(isTwoPlayerGame: false))
    }

    func testTwoPlayerExtensionDefersTripTo1000() {
        var s = MilleBornesTeamScore()
        s.cards100 = 7; s.usedExtension = true  // 700 mi + extension → not done yet
        XCTAssertFalse(s.tripCompleted(isTwoPlayerGame: true))
        s.cards100 = 10  // 1000 miles → now done
        XCTAssertTrue(s.tripCompleted(isTwoPlayerGame: true))
    }

    func testOpponentExtensionAlsoDefersTripTo1000() {
        // When the opponent calls the extension, the non-calling team must also play to 1000.
        var team1 = MilleBornesTeamScore()
        team1.cards100 = 7  // 700 miles, did NOT call extension
        var team2 = MilleBornesTeamScore()
        team2.usedExtension = true  // opponent called it

        let extensionCalled = team1.usedExtension || team2.usedExtension
        XCTAssertFalse(team1.tripCompleted(isTwoPlayerGame: true, extensionCalled: extensionCalled))

        team1.cards100 = 10  // 1000 miles → now done
        XCTAssertTrue(team1.tripCompleted(isTwoPlayerGame: true, extensionCalled: extensionCalled))
    }

    func testFourPlayerHandScoreAt700HasNoTripBonus() {
        var s = MilleBornesTeamScore()
        s.cards100 = 7  // 700 miles, 4-player — miles only, no trip bonus
        XCTAssertEqual(s.handScore(isTwoPlayerGame: false), 700)
    }

    func testFourPlayerHandScoreAt1000HasTripBonus() {
        var s = MilleBornesTeamScore()
        s.cards100 = 10  // 1000 miles, no 200s → tripCompleted + safeTrip
        XCTAssertEqual(s.handScore(isTwoPlayerGame: false), 1000 + 400 + 300)
    }
}

// MARK: - Hand Score Calculation

final class MilleBornesHandScoreTests: XCTestCase {

    func testMilesOnlyScore() {
        var s = MilleBornesTeamScore()
        s.cards100 = 7; s.cards50 = 1  // 750
        XCTAssertEqual(s.handScore(isTwoPlayerGame: true), 750)
    }

    func testSafetyBonus100Each() {
        var s = MilleBornesTeamScore()
        s.rightOfWay.played = true
        XCTAssertEqual(s.handScore(isTwoPlayerGame: true), 100)
        s.punctureProof.played = true
        s.drivingAce.played = true  // 3 safeties — stop before allFourSafeties triggers
        XCTAssertEqual(s.handScore(isTwoPlayerGame: true), 300)
    }

    func testCoupFourreBonus300Each() {
        var s = MilleBornesTeamScore()
        s.rightOfWay    = MilleBornesSafetyState(played: true, coupFourre: true)
        s.punctureProof = MilleBornesSafetyState(played: true, coupFourre: true)
        // 2×100 safety + 2×300 coup fourré
        XCTAssertEqual(s.handScore(isTwoPlayerGame: true), 2 * 100 + 2 * 300)
    }

    func testCoupFourreStacksWithSafetyBonus() {
        var s = MilleBornesTeamScore()
        s.rightOfWay    = MilleBornesSafetyState(played: true, coupFourre: true)
        s.punctureProof.played = true
        s.drivingAce.played = true
        // 3×100 + 1×300
        XCTAssertEqual(s.handScore(isTwoPlayerGame: true), 300 + 300)
    }

    func testTripCompletedBonus400() {
        var s = MilleBornesTeamScore()
        s.cards200 = 1; s.cards100 = 5  // 700 miles → tripCompleted, no safeTrip (has 200)
        XCTAssertEqual(s.handScore(isTwoPlayerGame: true), 700 + 400)
    }

    func testAllFourSafetiesBonus300() {
        var s = MilleBornesTeamScore()
        s.rightOfWay.played = true; s.punctureProof.played = true
        s.drivingAce.played = true; s.extraTank.played = true
        XCTAssertEqual(s.handScore(isTwoPlayerGame: true), 4 * 100 + 300)
    }

    func testSafeTripBonus300() {
        var s = MilleBornesTeamScore()
        s.cards100 = 10  // 1000 miles, no 200s → tripCompleted + safeTrip auto
        XCTAssertEqual(s.handScore(isTwoPlayerGame: true), 1000 + 400 + 300)
    }

    func testSafeTripNotAwardedWhen200Used() {
        var s = MilleBornesTeamScore()
        s.cards200 = 1; s.cards100 = 8  // 1000 miles with a 200 → tripCompleted, no safeTrip
        XCTAssertEqual(s.handScore(isTwoPlayerGame: true), 1000 + 400)
    }

    func testExtensionBonus400WhenCompletedAtThousand() {
        var s = MilleBornesTeamScore()
        s.cards200 = 1; s.cards100 = 8  // 1000 miles, called extension and won
        s.usedExtension = true
        // trip(400) + extension(400); no safeTrip (has 200 card)
        XCTAssertEqual(s.handScore(isTwoPlayerGame: true), 1000 + 400 + 400)
    }

    func testExtensionBonus200WhenCalledButNotCompleted() {
        var s = MilleBornesTeamScore()
        s.cards200 = 1; s.cards100 = 5  // 700 miles, called extension but opponent won
        s.usedExtension = true
        // tripCompleted = false (700 mi + usedExtension means hand continues), extension = 200
        XCTAssertFalse(s.tripCompleted(isTwoPlayerGame: true))
        XCTAssertEqual(s.handScore(isTwoPlayerGame: true), 700 + 200)
    }

    func testShutOutBonus500() {
        var h = MilleBornesHand()
        h.team1.cards200 = 1; h.team1.cards100 = 5  // 700 miles → tripCompleted, no safeTrip
        // team2 has 0 miles → shutOut auto
        XCTAssertTrue(h.team1ShutOut(isTwoPlayerGame: true))
        XCTAssertEqual(h.team1Score(isTwoPlayerGame: true), 700 + 400 + 500)
    }

    func testDelayedActionBonus300() {
        var s = MilleBornesTeamScore()
        s.cards200 = 1; s.cards100 = 5  // 700 miles → tripCompleted, no safeTrip
        s.delayedAction = true
        XCTAssertEqual(s.handScore(isTwoPlayerGame: true), 700 + 400 + 300)
    }

    func testFullBonusHand() {
        // 1000 miles (no 200s) → tripCompleted, safeTrip, allFourSafeties auto; extension explicit
        // team2 has 0 miles → shutOut auto at hand level
        var h = MilleBornesHand()
        h.team1.cards100 = 10
        h.team1.rightOfWay    = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team1.punctureProof = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team1.drivingAce    = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team1.extraTank.played = true
        h.team1.usedExtension = true
        h.team1.delayedAction = true

        // 1000 + 400 (trip) + 900 (CF) + 400 (safeties) + 300 (allFour) + 300 (safeTrip) + 400 (extension) + 500 (shutOut) + 300 (delayedAction)
        let expected = 1000 + 400 + 900 + 400 + 300 + 300 + 400 + 500 + 300
        XCTAssertEqual(h.team1Score(isTwoPlayerGame: true), expected)
    }

    func testZeroScore() {
        XCTAssertEqual(MilleBornesTeamScore().handScore(isTwoPlayerGame: true), 0)
    }
}

// MARK: - Score Lines

final class MilleBornesScoreLinesTests: XCTestCase {

    func testEmptyScoreHasNoLines() {
        XCTAssertTrue(MilleBornesTeamScore().scoreLines(isTwoPlayerGame: true).isEmpty)
    }

    func testMilesLineAppearsWhenNonZero() {
        var s = MilleBornesTeamScore()
        s.cards100 = 5  // 500 miles
        let labels = s.scoreLines(isTwoPlayerGame: true).map(\.label)
        XCTAssertTrue(labels.contains("Miles"))
        XCTAssertEqual(s.scoreLines(isTwoPlayerGame: true).first(where: { $0.label == "Miles" })?.value, 500)
    }

    func testMilesLineAbsentWhenZero() {
        let labels = MilleBornesTeamScore().scoreLines(isTwoPlayerGame: true).map(\.label)
        XCTAssertFalse(labels.contains("Miles"))
    }

    func testSingleSafetyLabel() {
        var s = MilleBornesTeamScore()
        s.rightOfWay.played = true
        XCTAssertTrue(s.scoreLines(isTwoPlayerGame: true).map(\.label).contains("Safety"))
    }

    func testPluralSafetyLabel() {
        var s = MilleBornesTeamScore()
        s.rightOfWay.played = true; s.punctureProof.played = true; s.drivingAce.played = true
        XCTAssertTrue(s.scoreLines(isTwoPlayerGame: true).map(\.label).contains("Safety ×3"))
    }

    func testSingleCoupFourreLabel() {
        var s = MilleBornesTeamScore()
        s.rightOfWay = MilleBornesSafetyState(played: true, coupFourre: true)
        XCTAssertTrue(s.scoreLines(isTwoPlayerGame: true).map(\.label).contains("Coup Fourré"))
    }

    func testPluralCoupFourreLabel() {
        var s = MilleBornesTeamScore()
        s.rightOfWay    = MilleBornesSafetyState(played: true, coupFourre: true)
        s.punctureProof = MilleBornesSafetyState(played: true, coupFourre: true)
        XCTAssertTrue(s.scoreLines(isTwoPlayerGame: true).map(\.label).contains("Coup Fourré ×2"))
    }

    func testBonusLabelsIncluded() {
        var s = MilleBornesTeamScore()
        s.cards100 = 10   // 1000 miles → tripCompleted + safeTrip (no 200s)
        s.rightOfWay.played = true; s.punctureProof.played = true
        s.drivingAce.played = true; s.extraTank.played = true  // allFourSafeties
        s.usedExtension = true
        s.delayedAction = true

        let labels = s.scoreLines(isTwoPlayerGame: true).map(\.label)
        XCTAssertTrue(labels.contains("Trip"))
        XCTAssertTrue(labels.contains("All 4 Safeties"))
        XCTAssertTrue(labels.contains("Safe Trip"))
        XCTAssertTrue(labels.contains("Called Extension"))
        XCTAssertTrue(labels.contains("Delayed Action"))
        // Shut Out is computed at the hand level, not in scoreLines
    }

    func testSafeTripLineAbsentWhenUsed200() {
        var s = MilleBornesTeamScore()
        s.cards200 = 1; s.cards100 = 8  // 1000 miles → tripCompleted, but used 200 → no safeTrip
        XCTAssertFalse(s.scoreLines(isTwoPlayerGame: true).map(\.label).contains("Safe Trip"))
    }

    func testScoreLineValuesAreCorrect() {
        var s = MilleBornesTeamScore()
        s.cards200 = 1; s.cards100 = 8  // 1000 miles → tripCompleted, no safeTrip (has 200)
        s.rightOfWay.played = true; s.punctureProof.played = true
        s.drivingAce.played = true; s.extraTank.played = true  // allFourSafeties
        s.usedExtension = true
        s.delayedAction = true

        let lineValues = Dictionary(uniqueKeysWithValues: s.scoreLines(isTwoPlayerGame: true).map { ($0.label, $0.value) })
        XCTAssertEqual(lineValues["Trip"],             400)
        XCTAssertEqual(lineValues["All 4 Safeties"],   300)
        XCTAssertEqual(lineValues["Called Extension"], 400)  // 1000 miles → won with extension
        XCTAssertEqual(lineValues["Delayed Action"],   300)
        // Shut Out is computed at the hand level, not in scoreLines
    }
}

// MARK: - Game Cumulative Score & State

final class MilleBornesGameTests: XCTestCase {

    private func game(hands: [(team1Miles: Int, team2Miles: Int)]) -> MilleBornesGame {
        let g = MilleBornesGame(team1Players: [PlayerRef(cachedName: "A")], team2Players: [PlayerRef(cachedName: "B")])
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
        let g = game(hands: [(500, 300), (400, 500)])  // all below 700 — no trip bonuses
        XCTAssertEqual(g.cumulativeScore(team: 1), 900)
        XCTAssertEqual(g.cumulativeScore(team: 2), 800)
    }

    func testCumulativeScoreIncludesBonuses() {
        let g = MilleBornesGame(team1Players: [PlayerRef(cachedName: "A")], team2Players: [PlayerRef(cachedName: "B")])
        var h = MilleBornesHand()
        h.team1.cards100 = 10  // 1000 miles → tripCompleted + safeTrip (no 200s) auto
        h.team2.cards100 = 3   // 300 miles — prevents shutOut so only trip bonuses apply
        g.addHand(h)
        XCTAssertEqual(g.cumulativeScore(team: 1), 1700)
        XCTAssertEqual(g.cumulativeScore(team: 2), 300)
    }

    func testIsNotFinishedBelowThreshold() {
        let g = game(hands: [(4000, 3000)])
        XCTAssertFalse(g.isFinished)
    }

    func testIsFinishedAtExactly5000() {
        let g = MilleBornesGame(team1Players: [PlayerRef(cachedName: "A")], team2Players: [PlayerRef(cachedName: "B")])
        var h = MilleBornesHand()
        // 1000 mi + ext → tripCompleted + safeTrip + allFourSafeties auto; team2=0 → shutOut auto
        // 1000 + 400 (trip) + 400 (ext@1000) + 300 (safeTrip) + 300 (allFour) + 400 (4×safety) + 500 (shutOut) = 3300
        h.team1.cards100 = 10
        h.team1.rightOfWay.played = true; h.team1.punctureProof.played = true
        h.team1.drivingAce.played = true; h.team1.extraTank.played = true
        h.team1.usedExtension = true
        g.addHand(h)

        var h2 = MilleBornesHand()
        h2.team1.cards100 = 10
        h2.team1.rightOfWay    = MilleBornesSafetyState(played: true, coupFourre: true)
        h2.team1.punctureProof = MilleBornesSafetyState(played: true, coupFourre: true)
        h2.team1.drivingAce    = MilleBornesSafetyState(played: true, coupFourre: true)
        h2.team1.extraTank     = MilleBornesSafetyState(played: true, coupFourre: true)
        g.addHand(h2)

        XCTAssertTrue(g.isFinished)
    }

    func testIsFinishedWhenTeam2Crosses5000() {
        let g = MilleBornesGame(team1Players: [PlayerRef(cachedName: "A")], team2Players: [PlayerRef(cachedName: "B")])
        var h = MilleBornesHand()
        // 1000 mi + ext → tripCompleted + safeTrip + allFourSafeties auto; team1=0 → shutOut auto
        // 1000 + 400 (trip) + 300 (safeTrip) + 300 (allFour) + 400 (safeties) + 1200 (CF) + 400 (ext@1000) + 300 (delayed) + 500 (shutOut) = 4800
        h.team2.cards100 = 10
        h.team2.rightOfWay    = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team2.punctureProof = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team2.drivingAce    = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team2.extraTank     = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team2.usedExtension = true
        h.team2.delayedAction = true
        g.addHand(h)
        var h2 = MilleBornesHand()
        h2.team2.cards100 = 5  // 500 miles, no trip — enough to cross 5000
        g.addHand(h2)
        XCTAssertTrue(g.isFinished)
        XCTAssertEqual(g.winningTeam, 2)
    }

    func testWinningTeamNilWhenNotFinished() {
        let g = game(hands: [(500, 300)])
        XCTAssertNil(g.winningTeam)
    }

    func testWinningTeamIsHigherScoreWhenFinished() {
        let g = MilleBornesGame(team1Players: [PlayerRef(cachedName: "A")], team2Players: [PlayerRef(cachedName: "B")])
        var h = MilleBornesHand()
        // 1000 mi → tripCompleted + safeTrip + allFourSafeties auto; extension explicit
        h.team1.cards100 = 10
        h.team1.rightOfWay    = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team1.punctureProof = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team1.drivingAce    = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team1.extraTank     = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team1.usedExtension = true
        h.team1.delayedAction = true
        // team2 has 0 miles → shutOut auto-triggers for team1
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

        h.team1.cards100 = 6  // replace with 600 miles (below 700 — no trip bonuses)
        g.replaceHand(h)
        XCTAssertEqual(g.cumulativeScore(team: 1), 600)
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

        h2.team1.cards100 = 6  // replace with 600 miles (below 700 — no trip bonuses)
        g.replaceHand(h2)

        XCTAssertEqual(g.hands.count, 3)
        XCTAssertEqual(g.cumulativeScore(team: 1), 300 + 600 + 200)
    }

    // MARK: - Labels

    func testTeamLabelsUsePlayers() {
        let g = MilleBornesGame(team1Players: [PlayerRef(cachedName: "Alice"), PlayerRef(cachedName: "Bob")], team2Players: [PlayerRef(cachedName: "Carol"), PlayerRef(cachedName: "Dave")])
        XCTAssertEqual(g.team1Label, "Alice & Bob")
        XCTAssertEqual(g.team2Label, "Carol & Dave")
    }

    func testTeamLabelSinglePlayer() {
        let g = MilleBornesGame(team1Players: [PlayerRef(cachedName: "Alice")], team2Players: [PlayerRef(cachedName: "Bob")])
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
        h.team1.cards100 = 6; h.team1.cards200 = 1  // 800 miles
        h.team1.rightOfWay    = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team1.punctureProof = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team1.drivingAce.played = true
        h.team2.cards50 = 4; h.team2.rightOfWay.played = true

        let data = try JSONEncoder().encode(h)
        let decoded = try JSONDecoder().decode(MilleBornesHand.self, from: data)
        XCTAssertEqual(decoded.id, h.id)
        XCTAssertEqual(decoded.team1, h.team1)
        XCTAssertEqual(decoded.team2, h.team2)
    }
}
