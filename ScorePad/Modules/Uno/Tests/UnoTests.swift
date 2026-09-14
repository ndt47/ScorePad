import XCTest
import SwiftData
@testable import ScorePad

final class UnoGameTests: XCTestCase {

    private func game(_ scoring: UnoScoring, players: Int = 3, target: Int = 500) -> UnoGame {
        UnoGame(players: (0..<players).map { .preview("P\($0)") }, scoring: scoring, targetScore: target)
    }

    private func hand(out: Int, left: [Int], side: UnoSide = .light) -> UnoHand {
        var hand = UnoHand(playerCount: left.count, wentOutIndex: out, side: side)
        hand.pointsLeft = left
        return hand
    }

    // MARK: - Scoring

    func testWinnerCollectsEveryoneElsesCards() {
        let g = game(.winnerCollects)
        g.addHand(hand(out: 1, left: [30, 0, 45]))
        XCTAssertEqual(g.cumulativeScore(for: 0), 0)
        XCTAssertEqual(g.cumulativeScore(for: 1), 75)
        XCTAssertEqual(g.cumulativeScore(for: 2), 0)
    }

    func testPointsAgainstScoresYourOwnCards() {
        let g = game(.pointsAgainst)
        g.addHand(hand(out: 1, left: [30, 0, 45]))
        XCTAssertEqual(g.cumulativeScore(for: 0), 30)
        XCTAssertEqual(g.cumulativeScore(for: 1), 0)
        XCTAssertEqual(g.cumulativeScore(for: 2), 45)
    }

    func testScoresAccumulateOverHands() {
        let g = game(.winnerCollects)
        g.addHand(hand(out: 0, left: [0, 20, 30]))
        g.addHand(hand(out: 2, left: [10, 5, 0]))
        g.addHand(hand(out: 0, left: [0, 7, 8]))
        XCTAssertEqual(g.cumulativeScore(for: 0), 65)
        XCTAssertEqual(g.cumulativeScore(for: 2), 15)
    }

    // MARK: - Finishing and winners

    func testNotFinishedBelowTarget() {
        let g = game(.winnerCollects, target: 100)
        g.addHand(hand(out: 0, left: [0, 50, 49]))
        XCTAssertFalse(g.isFinished)
        XCTAssertEqual(g.winnerIndices, [])
    }

    func testWinnerCollectsFinishesAtTargetAndHighestWins() {
        let g = game(.winnerCollects, target: 100)
        g.addHand(hand(out: 0, left: [0, 50, 50]))
        XCTAssertTrue(g.isFinished)
        XCTAssertEqual(g.winnerIndices, [0])
    }

    func testPointsAgainstFinishesAtTargetAndLowestWins() {
        let g = game(.pointsAgainst, target: 100)
        g.addHand(hand(out: 1, left: [60, 0, 20]))
        g.addHand(hand(out: 2, left: [45, 10, 0]))
        XCTAssertTrue(g.isFinished)      // player 0 reached 105
        XCTAssertEqual(g.winnerIndices, [1])
    }

    func testTiedPlayersAreAllWinners() {
        let g = game(.pointsAgainst, target: 100)
        g.addHand(hand(out: 0, left: [0, 100, 0]))  // player 2 was left holding only a zero
        XCTAssertEqual(g.winnerIndices, [0, 2])
        XCTAssertTrue(g.isWinner(2))
    }

    func testEditingAHandRescores() {
        let g = game(.winnerCollects, target: 100)
        g.addHand(hand(out: 0, left: [0, 60, 50]))
        XCTAssertTrue(g.isFinished)
        var edited = g.hands[0]
        edited.pointsLeft = [0, 10, 10]
        g.replaceHand(edited)
        XCTAssertFalse(g.isFinished)
        XCTAssertEqual(g.cumulativeScore(for: 0), 20)
    }

    // MARK: - Went-out player

    func testWhoeverWentOutAlwaysHoldsZero() {
        let g = game(.pointsAgainst)
        g.addHand(hand(out: 1, left: [10, 99, 20]))   // a stray entry for the player who went out
        XCTAssertEqual(g.hands[0].pointsLeft, [10, 0, 20])
        XCTAssertEqual(g.hands[0].handValue, 30)
        XCTAssertEqual(g.cumulativeScore(for: 1), 0)
    }

    func testHandValueIgnoresTheWentOutEntryEvenBeforeSaving() {
        XCTAssertEqual(hand(out: 0, left: [50, 10, 5]).handValue, 15)
        XCTAssertEqual(hand(out: 0, left: [50, 10, 5]).pointsLeft(for: 7), 0)
    }

    // MARK: - Dealer

    func testDealerStartsAtChosenPlayerAndRotates() {
        let g = UnoGame(players: [.preview("A"), .preview("B"), .preview("C")], startingDealerIndex: 2)
        XCTAssertEqual(g.currentDealerIndex, 2)
        g.addHand(hand(out: 0, left: [0, 1, 1]))
        XCTAssertEqual(g.currentDealerIndex, 0)
        for _ in 0..<4 { g.addHand(hand(out: 0, left: [0, 1, 1])) }
        XCTAssertEqual(g.currentDealerIndex, 1)   // (2 + 5) % 3
    }

    // MARK: - Mock

    func testMockIsAFlipGameInProgress() {
        let g = UnoGame.mock
        XCTAssertEqual(g.edition, .flip)
        XCTAssertFalse(g.isFinished)
        XCTAssertEqual(g.cumulativeScore(for: 0), 298 + 107)
    }
}

final class UnoCardTests: XCTestCase {

    private func card(_ id: String, _ edition: UnoEdition, _ side: UnoSide = .light) -> UnoCard? {
        edition.cards(side: side).first { $0.id == id }
    }

    /// Every face of every deck, pinned against the table in docs/design/uno.md.
    func testCardTablesMatchTheDesignDoc() {
        func values(_ edition: UnoEdition, _ side: UnoSide) -> [String: Int] {
            Dictionary(uniqueKeysWithValues: edition.cards(side: side).filter { !$0.isNumber }.map { ($0.name, $0.points) })
        }
        XCTAssertEqual(values(.classic, .light), [
            "Skip": 20, "Reverse": 20, "Draw Two": 20,
            "Wild Shuffle Hands": 40, "Wild Customizable": 40,
            "Wild": 50, "Wild Draw Four": 50,
        ])
        XCTAssertEqual(values(.flip, .light), [
            "Draw One": 10, "Skip": 20, "Reverse": 20, "Flip": 20, "Wild": 40, "Wild Draw Two": 50,
        ])
        XCTAssertEqual(values(.flip, .dark), [
            "Draw Five": 20, "Reverse": 20, "Flip": 20, "Skip Everyone": 30, "Wild": 40, "Wild Draw Color": 60,
        ])
    }

    func testClassicIgnoresTheSide() {
        XCTAssertEqual(UnoEdition.classic.cards(side: .dark), UnoEdition.classic.cards(side: .light))
    }

    func testClassicValues() {
        XCTAssertEqual(card("skip", .classic)?.points, 20)
        XCTAssertEqual(card("draw2", .classic)?.points, 20)
        XCTAssertEqual(card("shuffle", .classic)?.points, 40)
        XCTAssertEqual(card("wild", .classic)?.points, 50)
        XCTAssertEqual(card("wild4", .classic)?.points, 50)
        XCTAssertEqual(UnoEdition.classic.cards(side: .light).filter(\.isNumber).map(\.points), Array(0...9))
    }

    func testFlipCountsBySide() {
        XCTAssertEqual(card("draw1", .flip, .light)?.points, 10)
        XCTAssertNil(card("draw1", .flip, .dark), "Draw One is a light-side card")
        XCTAssertEqual(card("wild", .flip, .light)?.points, 40)
        XCTAssertEqual(card("wild2", .flip, .light)?.points, 50)
        XCTAssertEqual(card("skipAll", .flip, .dark)?.points, 30)
        XCTAssertEqual(card("wildColor", .flip, .dark)?.points, 60)
        XCTAssertEqual(card("draw5", .flip, .dark)?.points, 20)
    }

    func testFlipHasNoZeroCards() {
        for side in UnoSide.allCases {
            XCTAssertEqual(UnoEdition.flip.cards(side: side).filter(\.isNumber).map(\.points), Array(1...9))
        }
    }

    func testCardIDsAreUniquePerDeckFace() {
        for edition in UnoEdition.allCases {
            for side in UnoSide.allCases {
                let ids = edition.cards(side: side).map(\.id)
                XCTAssertEqual(Set(ids).count, ids.count, "\(edition) \(side)")
            }
        }
    }
}

// MARK: - Player roster integration

@MainActor
final class UnoPlayerRosterTests: XCTestCase {
    func testRosterOperationsReachUnoGames() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let alice = PersonProfile(name: "Alice")
        let bob = PersonProfile(name: "Bob")
        context.insert(alice)
        context.insert(bob)
        let game = UnoGame(players: PlayerRef.seats(for: [alice, bob]))
        context.insert(game)
        try context.save()
        let service = PlayerProfileService(context: context, modules: ScorePadApp.modules)

        XCTAssertEqual(try service.gameCounts()[alice.id], 1)
        XCTAssertThrowsError(try service.delete([alice]))

        try service.rename(alice, to: "Alicia")
        XCTAssertEqual(game.players.map(\.cachedName), ["Alicia", "Bob"])
    }
}

// MARK: - Storage

@MainActor
final class UnoStorageTests: XCTestCase {
    func testGameSurvivesSaveAndFetch() throws {
        let container = try makeInMemoryContainer()
        let game = UnoGame(players: [.preview("A"), .preview("B"), .preview("C")],
                           edition: .flip, scoring: .pointsAgainst, targetScore: 250, startingDealerIndex: 1)
        var first = UnoHand(playerCount: 3, wentOutIndex: 2, side: .dark)
        first.pointsLeft = [60, 30, 0]
        var second = UnoHand(playerCount: 3, wentOutIndex: 0, side: .light)
        second.pointsLeft = [0, 12, 45]
        game.addHand(first)
        game.addHand(second)
        container.mainContext.insert(game)
        try container.mainContext.save()

        let fetched = try XCTUnwrap(ModelContext(container).fetch(FetchDescriptor<UnoGame>()).first)
        XCTAssertEqual(fetched.edition, .flip)
        XCTAssertEqual(fetched.scoring, .pointsAgainst)
        XCTAssertEqual(fetched.targetScore, 250)
        XCTAssertEqual(fetched.startingDealerIndex, 1)
        XCTAssertEqual(fetched.players, game.players)
        XCTAssertEqual(fetched.hands, game.hands)
        XCTAssertEqual(fetched.cumulativeScore(for: 2), 45)
    }
}
