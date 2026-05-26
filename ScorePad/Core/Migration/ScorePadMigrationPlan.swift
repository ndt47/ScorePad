import Foundation
import SwiftData

// MARK: - Schema V1 (on-device state: players stored as [String])

enum ScorePadSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            ScorePadSchemaV1.MilleBornesGame.self,
            ScorePadSchemaV1.Phase10Game.self,
            Rubber.self,
            Auction.self,
            PersonProfile.self,
        ]
    }

    @Model
    final class MilleBornesGame {
        var id: UUID = UUID()
        var dateCreated: Date = Date.now
        var lastModified: Date = Date.now
        var team1Players: [String] = []
        var team2Players: [String] = []
        var hands: [MilleBornesHand] = []

        init() {}
    }

    @Model
    final class Phase10Game {
        var id: UUID = UUID()
        var dateCreated: Date = Date.now
        var lastModified: Date = Date.now
        var players: [String] = []
        var hands: [Phase10Hand] = []

        init() {}
    }
}

// MARK: - Schema V2 (target: players stored as [PlayerRef])

enum ScorePadSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            MilleBornesGame.self,
            Phase10Game.self,
            Rubber.self,
            Auction.self,
            PersonProfile.self,
        ]
    }
}

// MARK: - Migration Plan

enum ScorePadMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [ScorePadSchemaV1.self, ScorePadSchemaV2.self] }
    static var stages: [MigrationStage] { [migrateV1toV2] }

    // Temporary storage bridging willMigrate → didMigrate (migration runs serially)
    nonisolated(unsafe) static var milleData: [UUID: (t1: [String], t2: [String])] = [:]
    nonisolated(unsafe) static var p10Data: [UUID: [String]] = [:]

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: ScorePadSchemaV1.self,
        toVersion: ScorePadSchemaV2.self,
        willMigrate: { context in
            // Snapshot V1 string arrays before SwiftData drops the incompatible columns
            milleData = try .init(uniqueKeysWithValues:
                context.fetch(FetchDescriptor<ScorePadSchemaV1.MilleBornesGame>())
                    .map { ($0.id, (t1: $0.team1Players, t2: $0.team2Players)) })
            p10Data = try .init(uniqueKeysWithValues:
                context.fetch(FetchDescriptor<ScorePadSchemaV1.Phase10Game>())
                    .map { ($0.id, $0.players) })
        },
        didMigrate: { context in
            defer { milleData = [:]; p10Data = [:] }

            // Build a name → PersonProfile map, creating missing profiles as needed
            var byName: [String: PersonProfile] = try .init(uniqueKeysWithValues:
                context.fetch(FetchDescriptor<PersonProfile>()).map { ($0.name.lowercased(), $0) })
            func profile(for name: String) -> PersonProfile {
                if let p = byName[name.lowercased()] { return p }
                let p = PersonProfile(name: name)
                context.insert(p)
                byName[name.lowercased()] = p
                return p
            }

            // Mille Bornes — populate [PlayerRef] from saved V1 strings
            for game in try context.fetch(FetchDescriptor<MilleBornesGame>()) {
                if let d = milleData[game.id] {
                    game.team1Players = d.t1.map { PlayerRef(profile: profile(for: $0)) }
                    game.team2Players = d.t2.map { PlayerRef(profile: profile(for: $0)) }
                }
            }

            // Phase 10 — same
            for game in try context.fetch(FetchDescriptor<Phase10Game>()) {
                if let names = p10Data[game.id] {
                    game.players = names.map { PlayerRef(profile: profile(for: $0)) }
                }
            }

            // Bridge — Rubber.players: [Player] stays binary Codable (no SwiftData type change).
            // Link any players whose profileID hasn't been set yet.
            for rubber in try context.fetch(FetchDescriptor<Rubber>()) {
                var players = rubber.players; var changed = false
                for i in players.indices where players[i].ref.profileID == nil {
                    players[i].ref.profileID = profile(for: players[i].name).id
                    changed = true
                }
                if changed { rubber.players = players }
            }

            try context.save()
        }
    )
}
