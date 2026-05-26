import XCTest
@testable import ScorePad

final class Phase10GameTests: XCTestCase {

    // MARK: - Phase progression

    func testCurrentPhaseStartsAtOne() {
        let game = Phase10Game(players: [PlayerRef(name: "A")])
        XCTAssertEqual(game.currentPhase(for: 0), 1)
    }

    func testCurrentPhaseAdvancesOnCompletion() {
        let game = Phase10Game(players: [PlayerRef(name: "A"), PlayerRef(name: "B")])
        var h = Phase10Hand(playerCount: 2)
        h.playerResults[0] = Phase10PlayerResult(score: 10, completedPhase: true)
        h.playerResults[1] = Phase10PlayerResult(score: 20, completedPhase: false)
        game.hands = [h]
        XCTAssertEqual(game.currentPhase(for: 0), 2)
        XCTAssertEqual(game.currentPhase(for: 1), 1)
    }

    func testCurrentPhaseCapsAtTen() {
        let game = Phase10Game(players: [PlayerRef(name: "A")])
        game.hands = (0..<12).map { _ in
            var h = Phase10Hand(playerCount: 1)
            h.playerResults[0].completedPhase = true
            return h
        }
        XCTAssertEqual(game.currentPhase(for: 0), 10)
    }

    func testPhaseAtHandIndex() {
        let game = Phase10Game(players: [PlayerRef(name: "A")])
        var h1 = Phase10Hand(playerCount: 1)
        h1.playerResults[0] = Phase10PlayerResult(score: 0, completedPhase: true)
        var h2 = Phase10Hand(playerCount: 1)
        h2.playerResults[0] = Phase10PlayerResult(score: 5, completedPhase: false)
        game.hands = [h1, h2]
        XCTAssertEqual(game.phase(for: 0, atHandIndex: 0), 1)
        XCTAssertEqual(game.phase(for: 0, atHandIndex: 1), 2)
    }

    // MARK: - Finish / win conditions

    func testNotFinishedBeforePhase10() {
        let game = Phase10Game(players: [PlayerRef(name: "A")])
        game.hands = (0..<9).map { _ in
            var h = Phase10Hand(playerCount: 1)
            h.playerResults[0].completedPhase = true
            return h
        }
        XCTAssertFalse(game.isFinished)
        XCTAssertNil(game.winnerIndex)
    }

    func testFinishedAfterPhase10() {
        let game = Phase10Game(players: [PlayerRef(name: "A")])
        game.hands = (0..<10).map { _ in
            var h = Phase10Hand(playerCount: 1)
            h.playerResults[0].completedPhase = true
            return h
        }
        XCTAssertTrue(game.isFinished)
        XCTAssertEqual(game.winnerIndex, 0)
    }

    func testWinnerTiebreakerPicksLowestScore() {
        let game = Phase10Game(players: [PlayerRef(name: "A"), PlayerRef(name: "B")])
        // Both complete all 10 phases; A scores 50 on the last hand, B only 10
        game.hands = (0..<10).map { i in
            var h = Phase10Hand(playerCount: 2)
            h.playerResults[0] = Phase10PlayerResult(score: i == 9 ? 50 : 0, completedPhase: true)
            h.playerResults[1] = Phase10PlayerResult(score: i == 9 ? 10 : 0, completedPhase: true)
            return h
        }
        XCTAssertEqual(game.winnerIndex, 1)
    }

    func testWinnerIsFirstToFinishPhase10WhenOtherHasnt() {
        let game = Phase10Game(players: [PlayerRef(name: "A"), PlayerRef(name: "B")])
        game.hands = (0..<10).map { _ in
            var h = Phase10Hand(playerCount: 2)
            h.playerResults[0].completedPhase = true
            h.playerResults[1].completedPhase = false
            return h
        }
        XCTAssertEqual(game.winnerIndex, 0)
    }

    // MARK: - Scoring

    func testCumulativeScore() {
        let game = Phase10Game(players: [PlayerRef(name: "A")])
        var h1 = Phase10Hand(playerCount: 1); h1.playerResults[0].score = 35
        var h2 = Phase10Hand(playerCount: 1); h2.playerResults[0].score = 15
        game.hands = [h1, h2]
        XCTAssertEqual(game.cumulativeScore(for: 0), 50)
    }

    func testCumulativeScoreIsZeroWithNoHands() {
        let game = Phase10Game(players: [PlayerRef(name: "A")])
        XCTAssertEqual(game.cumulativeScore(for: 0), 0)
    }

    // MARK: - Phase descriptions

    func testPhaseDescriptionsCount() {
        XCTAssertEqual(Phase10Game.phases.count, 10)
    }

    func testPhaseDescriptionBoundaryGuards() {
        XCTAssertEqual(Phase10Game.phaseDescription(for: 0), "")
        XCTAssertEqual(Phase10Game.phaseDescription(for: 11), "")
        XCTAssertFalse(Phase10Game.phaseDescription(for: 1).isEmpty)
        XCTAssertFalse(Phase10Game.phaseDescription(for: 10).isEmpty)
    }

    // MARK: - Add / replace hand

    func testAddHandUpdatesLastModified() throws {
        let game = Phase10Game(players: [PlayerRef(name: "A")])
        let before = game.lastModified
        // Ensure clock advances
        Thread.sleep(forTimeInterval: 0.01)
        game.addHand(Phase10Hand(playerCount: 1))
        XCTAssertGreaterThan(game.lastModified, before)
    }

    func testReplaceHandPreservesOtherHands() {
        let game = Phase10Game(players: [PlayerRef(name: "A")])
        var h1 = Phase10Hand(playerCount: 1); h1.playerResults[0].score = 10
        var h2 = Phase10Hand(playerCount: 1); h2.playerResults[0].score = 20
        game.hands = [h1, h2]

        var updated = h1
        updated.playerResults[0].score = 99
        game.replaceHand(updated)

        XCTAssertEqual(game.hands[0].playerResults[0].score, 99)
        XCTAssertEqual(game.hands[1].playerResults[0].score, 20)
    }
}
