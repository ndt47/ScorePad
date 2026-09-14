import Foundation
import SwiftData

enum PlayerProfileError: LocalizedError, Equatable {
    /// Another profile already uses this name or alias.
    case nameInUse(requested: String, owner: String)
    /// The profile appears in saved games, so deleting it would orphan them.
    case playerInUse(name: String, games: Int)

    var errorDescription: String? {
        switch self {
        case let .nameInUse(requested, owner):
            return requested.isSameName(as: owner)
                ? "There is already a player named \(owner). Merge the two players instead."
                : "\(requested) is already an alias of \(owner). Merge the two players instead."
        case let .playerInUse(name, games):
            return "\(name) appears in \(games) game\(games == 1 ? "" : "s"). Merge them into another player instead."
        }
    }
}

/// Roster operations that must stay consistent with every game's PlayerRefs. Game data is
/// reached through each module's `updatePlayerRefs` hook, so a new module is covered as soon
/// as it is registered. Every mutating operation saves on success and rolls back on failure.
@MainActor
struct PlayerProfileService {
    let context: ModelContext
    let modules: [any GameModule]

    // MARK: - Queries

    /// Number of saved games each profile appears in, keyed by profile ID.
    func gameCounts() throws -> [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for module in modules {
            try module.updatePlayerRefs(in: context) { refs in
                for id in Set(refs.map(\.profileID)) { counts[id, default: 0] += 1 }
            }
        }
        return counts
    }

    // MARK: - Mutations

    /// Renames a profile, keeps the old name as an alias, and updates every game's display name.
    func rename(_ profile: PersonProfile, to newName: String) throws {
        let name = newName.normalizedName
        guard !name.isEmpty, name != profile.name else { return }
        try commit {
            try requireNameAvailable(name, for: profile)
            let oldName = profile.name
            profile.aliases.removeAll { $0.isSameName(as: name) }
            if !oldName.isSameName(as: name) && !profile.aliases.contains(where: { $0.isSameName(as: oldName) }) {
                profile.aliases.append(oldName)
            }
            profile.name = name
            try updateRefs { ref in
                if ref.refers(to: profile) { ref.cachedName = name }
            }
        }
    }

    func addAlias(_ alias: String, to profile: PersonProfile) throws {
        let alias = alias.normalizedName
        guard !alias.isEmpty, !profile.answers(to: alias) else { return }
        try commit {
            try requireNameAvailable(alias, for: profile)
            profile.aliases.append(alias)
        }
    }

    func removeAlias(_ alias: String, from profile: PersonProfile) throws {
        try commit {
            profile.aliases.removeAll { $0.isSameName(as: alias) }
        }
    }

    /// Folds each secondary into `primary`: their names become aliases of `primary`, every game
    /// seat they held now refers to `primary`, and the secondary profiles are deleted.
    func merge(_ secondaries: [PersonProfile], into primary: PersonProfile) throws {
        let secondaries = secondaries.filter { $0.id != primary.id }
        guard !secondaries.isEmpty else { return }
        try commit {
            for secondary in secondaries {
                for name in [secondary.name] + secondary.aliases where !primary.answers(to: name) {
                    primary.aliases.append(name)
                }
            }
            let secondaryIDs = Set(secondaries.map(\.id))
            try updateRefs { ref in
                if secondaryIDs.contains(ref.profileID) { ref = PlayerRef(profile: primary) }
            }
            secondaries.forEach(context.delete)
        }
    }

    /// Deletes profiles that no game refers to. Throws `playerInUse` (and deletes nothing) if any do.
    func delete(_ profiles: [PersonProfile]) throws {
        let counts = try gameCounts()
        if let used = profiles.first(where: { counts[$0.id, default: 0] > 0 }) {
            throw PlayerProfileError.playerInUse(name: used.name, games: counts[used.id, default: 0])
        }
        try commit {
            profiles.forEach(context.delete)
        }
    }

    // MARK: - Helpers

    private func requireNameAvailable(_ name: String, for profile: PersonProfile) throws {
        let others = try context.fetch(FetchDescriptor<PersonProfile>()).filter { $0.id != profile.id }
        if let owner = others.first(where: { $0.answers(to: name) }) {
            throw PlayerProfileError.nameInUse(requested: name, owner: owner.name)
        }
    }

    private func updateRefs(_ update: (inout PlayerRef) -> Void) throws {
        for module in modules {
            try module.updatePlayerRefs(in: context) { refs in
                for i in refs.indices { update(&refs[i]) }
            }
        }
    }

    private func commit(_ work: () throws -> Void) throws {
        do {
            try work()
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
