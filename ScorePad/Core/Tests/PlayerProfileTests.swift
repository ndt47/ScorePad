import XCTest
import SwiftData
@testable import ScorePad

// MARK: - Name matching

final class PersonProfileMatchingTests: XCTestCase {
    func testMatchesNameIgnoringCaseAndSurroundingSpace() {
        let alice = PersonProfile(name: "Alice")
        XCTAssertTrue(PersonProfile.matching("  alice ", in: [alice]) === alice)
    }

    func testMatchesAlias() {
        let bob = PersonProfile(name: "Bobby")
        bob.aliases = ["Bob"]
        XCTAssertTrue(PersonProfile.matching("bob", in: [bob]) === bob)
    }

    func testExactNameBeatsAnotherPlayersAlias() {
        let alice = PersonProfile(name: "Alice")
        alice.aliases = ["Zed"]
        let zed = PersonProfile(name: "Zed")
        XCTAssertTrue(PersonProfile.matching("Zed", in: [alice, zed]) === zed)
    }

    func testNoMatch() {
        XCTAssertNil(PersonProfile.matching("Carol", in: [PersonProfile(name: "Alice")]))
    }
}

// MARK: - PlayerSlot

@MainActor
final class PlayerSlotTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }

    override func setUp() async throws {
        container = try makeInMemoryContainer()
    }

    private func slot(_ text: String, picked: PersonProfile? = nil) -> PlayerSlot {
        var slot = PlayerSlot()
        slot.text = text
        slot.profile = picked
        return slot
    }

    func testEverySeatNeedsAName() {
        XCTAssertNotNil(PlayerSlot.problem(with: [slot("Alice"), slot("  ")], roster: []))
    }

    func testSameNameTwiceIsAProblem() {
        XCTAssertNotNil(PlayerSlot.problem(with: [slot("Alice"), slot("alice")], roster: []))
    }

    func testNameAndAliasOfSamePlayerIsAProblem() {
        let bob = PersonProfile(name: "Bobby")
        bob.aliases = ["Bob"]
        let problem = PlayerSlot.problem(with: [slot("Bobby"), slot("Bob")], roster: [bob])
        XCTAssertEqual(problem, "Bobby and Bob are the same player.")
    }

    func testDistinctNamesAreFine() {
        XCTAssertNil(PlayerSlot.problem(with: [slot("Alice"), slot("Bob")], roster: []))
    }

    func testResolveUsesPickedThenMatchedThenCreates() throws {
        let alice = PersonProfile(name: "Alice")
        let bob = PersonProfile(name: "Bob")
        context.insert(alice)
        context.insert(bob)

        let resolved = try PlayerSlot.resolve([slot("Alice", picked: alice), slot("BOB"), slot(" Carol ")],
                                              in: context)

        XCTAssertTrue(resolved[0] === alice)
        XCTAssertTrue(resolved[1] === bob)
        XCTAssertEqual(resolved[2].name, "Carol")
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PersonProfile>()), 3)
    }

    func testResolveCreatesNothingForKnownPlayers() throws {
        context.insert(PersonProfile(name: "Alice"))
        _ = try PlayerSlot.resolve([slot("alice")], in: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PersonProfile>()), 1)
    }
}

// MARK: - PlayerProfileService

@MainActor
final class PlayerProfileServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }
    private var service: PlayerProfileService {
        PlayerProfileService(context: context, modules: ScorePadApp.modules)
    }

    private var alice: PersonProfile!
    private var bob: PersonProfile!
    private var carol: PersonProfile!
    private var dan: PersonProfile!
    private var rubber: Rubber!
    private var mille: MilleBornesGame!
    private var phase10: Phase10Game!

    // Alice plays every game type; Bob plays Bridge and Mille Bornes; Carol and Dan only Bridge.
    override func setUp() async throws {
        container = try makeInMemoryContainer()
        alice = PersonProfile(name: "Alice")
        bob = PersonProfile(name: "Bob")
        carol = PersonProfile(name: "Carol")
        dan = PersonProfile(name: "Dan")
        for profile in [alice, bob, carol, dan] { context.insert(profile!) }

        rubber = Rubber(players: [
            Player(ref: PlayerRef(profile: alice), position: .north),
            Player(ref: PlayerRef(profile: bob), position: .east),
            Player(ref: PlayerRef(profile: carol), position: .south),
            Player(ref: PlayerRef(profile: dan), position: .west),
        ])
        mille = MilleBornesGame(team1Players: [PlayerRef(profile: alice)],
                                team2Players: [PlayerRef(profile: bob)])
        phase10 = Phase10Game(players: [PlayerRef(profile: alice)])
        context.insert(rubber)
        context.insert(mille)
        context.insert(phase10)
        try context.save()
    }

    func testGameCountsCoverEveryModule() throws {
        let counts = try service.gameCounts()
        XCTAssertEqual(counts[alice.id], 3)
        XCTAssertEqual(counts[bob.id], 2)
        XCTAssertEqual(counts[carol.id], 1)
    }

    func testRenameUpdatesEveryGameAndKeepsOldNameAsAlias() throws {
        try service.rename(alice, to: " Alicia ")

        XCTAssertEqual(alice.name, "Alicia")
        XCTAssertEqual(alice.aliases, ["Alice"])
        XCTAssertEqual(rubber.players[0].name, "Alicia")
        XCTAssertEqual(mille.team1Players[0].cachedName, "Alicia")
        XCTAssertEqual(phase10.players[0].cachedName, "Alicia")
    }

    func testChangingOnlyCaseAddsNoAlias() throws {
        try service.rename(alice, to: "ALICE")
        XCTAssertEqual(alice.name, "ALICE")
        XCTAssertEqual(alice.aliases, [])
    }

    func testRenameToAnotherPlayersNameIsRefused() {
        XCTAssertThrowsError(try service.rename(alice, to: "bob")) { error in
            XCTAssertEqual(error as? PlayerProfileError, .nameInUse(requested: "bob", owner: "Bob"))
        }
        XCTAssertEqual(alice.name, "Alice")
    }

    func testAliasThatIsAnotherPlayersNameIsRefused() {
        XCTAssertThrowsError(try service.addAlias("Bob", to: alice))
        XCTAssertEqual(alice.aliases, [])
    }

    func testMergeMovesSeatsAndNamesToPrimary() throws {
        bob.aliases = ["Bobby"]
        let bobID = bob.id

        try service.merge([bob], into: carol)

        XCTAssertEqual(Set(carol.aliases), ["Bob", "Bobby"])
        XCTAssertEqual(rubber.players[1].ref, PlayerRef(profile: carol))
        XCTAssertEqual(mille.team2Players, [PlayerRef(profile: carol)])
        let remaining = try context.fetch(FetchDescriptor<PersonProfile>()).map(\.id)
        XCTAssertFalse(remaining.contains(bobID))
    }

    func testDeletingAPlayerInGamesIsRefused() throws {
        XCTAssertThrowsError(try service.delete([alice])) { error in
            XCTAssertEqual(error as? PlayerProfileError, .playerInUse(name: "Alice", games: 3))
        }
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PersonProfile>()), 4)
    }

    func testDeletingAnUnusedPlayerSucceeds() throws {
        let erin = PersonProfile(name: "Erin")
        context.insert(erin)
        try service.delete([erin])
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PersonProfile>()), 4)
    }

    func testMilleBornesTeamsKeepTheirSplit() throws {
        mille.team1Players = [PlayerRef(profile: alice), PlayerRef(profile: carol)]
        mille.team2Players = [PlayerRef(profile: bob), PlayerRef(profile: dan)]
        try service.rename(carol, to: "Caroline")
        XCTAssertEqual(mille.team1Players.map(\.cachedName), ["Alice", "Caroline"])
        XCTAssertEqual(mille.team2Players.map(\.cachedName), ["Bob", "Dan"])
    }
}

// MARK: - App schema

final class AppSchemaTests: XCTestCase {
    func testSchemaHasRosterAndEveryModuleModel() {
        let entities = Set(ScorePadApp.schema.entities.map(\.name))
        let expected = Set(([PersonProfile.self] + ScorePadApp.modules.flatMap(\.modelTypes))
            .map { String(describing: $0) })
        XCTAssertEqual(entities, expected)
    }
}

// MARK: - Helpers

func makeInMemoryContainer() throws -> ModelContainer {
    try ModelContainer(
        for: ScorePadApp.schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    )
}
