import XCTest
import SwiftData
@testable import ScorePad

// MARK: - Name matching

final class PersonProfileMatchingTests: XCTestCase {
    func testMatchesNameIgnoringCaseAndSurroundingSpace() {
        let alice = PersonProfile(name: "Alice")
        XCTAssertEqual(PersonProfile.candidates(for: "  alice ", in: [alice]), [alice])
    }

    func testMatchesFullNameAndAlias() {
        let bob = PersonProfile(name: "Bob", lastName: "Smith")
        bob.aliases = ["Bobby"]
        XCTAssertEqual(PersonProfile.candidates(for: "bob smith", in: [bob]), [bob])
        XCTAssertEqual(PersonProfile.candidates(for: "Bobby", in: [bob]), [bob])
    }

    func testSharedNameMatchesEveryone() {
        let bobSmith = PersonProfile(name: "Bob", lastName: "Smith")
        let bobJones = PersonProfile(name: "Bob", lastName: "Jones")
        let robert = PersonProfile(name: "Robert")
        robert.aliases = ["Bob"]
        XCTAssertEqual(PersonProfile.candidates(for: "Bob", in: [bobSmith, bobJones, robert]),
                       [bobSmith, bobJones, robert])
        XCTAssertEqual(PersonProfile.candidates(for: "Bob Jones", in: [bobSmith, bobJones, robert]), [bobJones])
    }

    func testSuggestionsListEveryExactMatchBeforePartialOnes() {
        let partials = ["Eddie", "Edgar", "Edith", "Edmund", "Edward"].map { PersonProfile(name: $0) }
        let fred = PersonProfile(name: "Fred")
        fred.aliases = ["Ed"]
        let ted = PersonProfile(name: "Ted")
        ted.aliases = ["Ed"]
        let suggestions = PersonProfile.suggestions(for: "ed", in: partials + [fred, ted], limit: 5)
        XCTAssertEqual(Array(suggestions.prefix(2)), [fred, ted])
        XCTAssertEqual(suggestions.count, 5)
    }

    func testExactMatchesAreNeverCut() {
        let bobs = (1...7).map { PersonProfile(name: "Bob", lastName: "\($0)") }
        XCTAssertEqual(PersonProfile.suggestions(for: "Bob", in: bobs, limit: 5).count, 7)
    }

    func testSeatsGiveSameNamedPlayersTheirInitial() {
        let bobSmith = PersonProfile(name: "Bob", lastName: "Smith")
        let bobJones = PersonProfile(name: "Bob", lastName: "Jones")
        let alice = PersonProfile(name: "Alice", lastName: "Liddell")
        XCTAssertEqual(PlayerRef.seats(for: [bobSmith, alice, bobJones]).map(\.cachedName),
                       ["Bob S.", "Alice", "Bob J."])
        XCTAssertEqual(PlayerRef.seats(for: [bobSmith, alice])[0].cachedBaseName, "Bob")
    }

    func testFullNameFallsBackToName() {
        XCTAssertEqual(PersonProfile(name: "Alice").fullName, "Alice")
        XCTAssertEqual(PersonProfile(name: "Alice", lastName: " Liddell ").fullName, "Alice Liddell")
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

    private func slot(_ text: String, _ choice: PlayerSlot.Choice = .automatic) -> PlayerSlot {
        var slot = PlayerSlot()
        slot.text = text
        slot.choice = choice
        return slot
    }

    func testEverySeatNeedsAName() {
        XCTAssertEqual(PlayerSlot.problem(with: [slot("Alice"), slot("  ")], roster: []),
                       "Enter a name for every player.")
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

    func testAmbiguousNameMustBeChosen() {
        let bobSmith = PersonProfile(name: "Bob", lastName: "Smith")
        let bobJones = PersonProfile(name: "Bob", lastName: "Jones")
        let roster = [bobSmith, bobJones]

        XCTAssertEqual(slot("Bob").resolution(in: roster), .ambiguous(roster))
        XCTAssertNotNil(PlayerSlot.problem(with: [slot("Bob")], roster: roster))
        XCTAssertNil(PlayerSlot.problem(with: [slot("Bob Jones", .existing(bobJones))], roster: roster))
    }

    func testTwoSameNamedPlayersCanShareAGame() {
        let bobSmith = PersonProfile(name: "Bob", lastName: "Smith")
        let bobJones = PersonProfile(name: "Bob", lastName: "Jones")
        let roster = [bobSmith, bobJones]
        let slots = [slot("Bob Smith", .existing(bobSmith)), slot("Bob Jones", .existing(bobJones))]
        XCTAssertNil(PlayerSlot.problem(with: slots, roster: roster))
    }

    func testExplicitNewPlayerIgnoresNameMatch() {
        let bob = PersonProfile(name: "Bob")
        XCTAssertEqual(slot("Bob").resolution(in: [bob]), .existing(bob))
        XCTAssertEqual(slot("Bob", .new).resolution(in: [bob]), .new)
        XCTAssertNil(PlayerSlot.problem(with: [slot("Bob"), slot("Bob", .new)], roster: [bob]))
    }

    func testDeletedPickFallsBackToNameMatch() {
        let bob = PersonProfile(name: "Bob")
        let gone = PersonProfile(name: "Bob")
        XCTAssertEqual(slot("Bob", .existing(gone)).resolution(in: [bob]), .existing(bob))
    }

    func testResolveUsesChosenThenMatchedThenCreates() throws {
        let alice = PersonProfile(name: "Alice")
        let bobSmith = PersonProfile(name: "Bob", lastName: "Smith")
        let bobJones = PersonProfile(name: "Bob", lastName: "Jones")
        [alice, bobSmith, bobJones].forEach(context.insert)
        let roster = [alice, bobSmith, bobJones]

        let resolved = PlayerSlot.resolve(
            [slot("ALICE"), slot("Bob Jones", .existing(bobJones)), slot("Bob", .new), slot(" Carol ")],
            roster: roster, in: context)

        XCTAssertTrue(resolved[0] === alice)
        XCTAssertTrue(resolved[1] === bobJones)
        XCTAssertEqual(resolved[2].name, "Bob")
        XCTAssertFalse(roster.contains(resolved[2]))
        XCTAssertEqual(resolved[3].name, "Carol")
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PersonProfile>()), 5)
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

    func testNamesAndAliasesNeedNotBeUnique() throws {
        try service.rename(alice, to: "Bob")
        try service.addAlias("Bob", to: carol)
        XCTAssertEqual(alice.name, "Bob")
        XCTAssertEqual(carol.aliases, ["Bob"])
    }

    func testLastNameDoesNotChangeGameNames() throws {
        try service.setLastName(" Liddell ", for: alice)
        XCTAssertEqual(alice.fullName, "Alice Liddell")
        XCTAssertEqual(phase10.players[0].cachedName, "Alice")
    }

    func testLastNameTellsApartSameNamedPlayersInAGame() throws {
        try service.rename(dan, to: "Carol")
        XCTAssertEqual(rubber.players.map(\.name), ["Alice", "Bob", "Carol", "Carol"])
        try service.setLastName("Smith", for: carol)
        try service.setLastName("Jones", for: dan)
        XCTAssertEqual(rubber.players.map(\.name), ["Alice", "Bob", "Carol S.", "Carol J."])
    }

    func testGameCountsChangeNothing() throws {
        _ = try service.gameCounts()
        XCTAssertFalse(context.hasChanges)
    }

    func testRefusedOperationKeepsUnsavedWork() throws {
        let unsaved = Phase10Game(players: [PlayerRef(profile: dan)])
        context.insert(unsaved)
        let unsavedID = unsaved.id

        XCTAssertThrowsError(try service.merge([bob], into: alice))  // they played together

        let fresh = ModelContext(container)
        let games = try fresh.fetch(FetchDescriptor<Phase10Game>())
        XCTAssertTrue(games.contains { $0.id == unsavedID })
    }

    func testPlayersWhoSharedAGameCannotBeMerged() throws {
        XCTAssertThrowsError(try service.merge([bob], into: alice)) { error in
            XCTAssertEqual(error as? PlayerProfileError, .playedTogether(first: "Alice", second: "Bob"))
            XCTAssertEqual(error.localizedDescription,
                           "Alice and Bob played in the same game, so they can't be the same player.")
        }
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PersonProfile>()), 4)
        XCTAssertEqual(alice.aliases, [])
    }

    func testRefreshReplacesANameThePlayerIsKnownBy() throws {
        alice.aliases = ["Ally"]  // e.g. her old name before a rename synced from another device
        var refs = phase10.players
        refs[0].cachedName = "Ally"
        phase10.players = refs
        try service.refreshCachedNames()
        XCTAssertEqual(phase10.players[0].cachedName, "Alice")
    }

    func testRefreshLeavesANameThisDeviceDoesNotKnow() throws {
        // A newer name synced from another device before the renamed profile arrived.
        var refs = phase10.players
        refs[0].cachedName = "Alicia"
        phase10.players = refs
        try service.refreshCachedNames()
        XCTAssertEqual(phase10.players[0].cachedName, "Alicia")
    }

    func testMergeMovesSeatsAndNamesToPrimary() throws {
        // Erin never played with Bob, so she can absorb him.
        let erin = PersonProfile(name: "Erin")
        context.insert(erin)
        bob.aliases = ["Bobby"]
        bob.lastName = "Builder"
        let bobID = bob.id

        try service.merge([bob], into: erin)

        XCTAssertEqual(Set(erin.aliases), ["Bob", "Bobby"])
        XCTAssertEqual(erin.lastName, "Builder")
        XCTAssertEqual(rubber.players[1].ref, PlayerRef(profile: erin))
        XCTAssertEqual(mille.team2Players, [PlayerRef(profile: erin)])
        let remaining = try context.fetch(FetchDescriptor<PersonProfile>()).map(\.id)
        XCTAssertFalse(remaining.contains(bobID))
        XCTAssertEqual(remaining.count, 4)
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
