import Foundation
import SwiftData

enum PlayerProfileError: LocalizedError, Equatable {
    /// The profile appears in saved games, so deleting it would orphan them.
    case playerInUse(name: String, games: Int)
    /// Two of the profiles being merged sat in the same game, so they can't be one person.
    case playedTogether(first: String, second: String)

    var errorDescription: String? {
        switch self {
        case let .playerInUse(name, games):
            return String(localized: "\(name) appears in \(games) game(s). Merge them into another player instead.")
        case let .playedTogether(first, second):
            return String(localized: "\(first) and \(second) played in the same game, so they can't be the same player.")
        }
    }
}

/// Roster operations that must stay consistent with every game's PlayerRefs. Game data is
/// reached through each module's `updatePlayerRefs` hook, so a new module is covered as soon
/// as it is registered.
///
/// Every mutating operation first saves the context (committing the user's pending edits, as
/// autosave would), then checks its preconditions without changing anything, then applies
/// and saves. So a refused operation changes nothing, and a failed save rolls back only the
/// operation itself.
@MainActor
struct PlayerProfileService {
    let context: ModelContext
    let modules: [any GameModule]

    // MARK: - Queries

    /// Number of saved games each profile appears in, keyed by profile ID.
    func gameCounts() throws -> [UUID: Int] {
        var counts: [UUID: Int] = [:]
        try forEachGame { ids in
            for id in ids { counts[id, default: 0] += 1 }
        }
        return counts
    }

    // MARK: - Mutations

    /// Renames a profile, keeps the old name as an alias, and updates every game's display name.
    /// Names need not be unique; `lastName` tells same-named players apart.
    func rename(_ profile: PersonProfile, to newName: String) throws {
        let name = newName.normalizedName
        guard !name.isEmpty, name != profile.name else { return }
        try perform {
            let oldName = profile.name
            profile.aliases.removeAll { $0.isSameName(as: name) }
            if !oldName.isSameName(as: name) && !profile.aliases.contains(where: { $0.isSameName(as: oldName) }) {
                profile.aliases.append(oldName)
            }
            profile.name = name
            try resyncDisplayNames(inGamesWith: [profile.id])
        }
    }

    /// Sets the last name, which games use to tell apart players who share a first name.
    func setLastName(_ lastName: String, for profile: PersonProfile) throws {
        let lastName = lastName.normalizedName
        guard lastName != profile.lastName else { return }
        try perform {
            profile.lastName = lastName
            try resyncDisplayNames(inGamesWith: [profile.id])
        }
    }

    /// Adds a nickname. Aliases need not be unique: several people can share one.
    func addAlias(_ alias: String, to profile: PersonProfile) throws {
        let alias = alias.normalizedName
        guard !alias.isEmpty, !profile.answers(to: alias) else { return }
        try perform {
            profile.aliases.append(alias)
        }
    }

    func removeAlias(_ alias: String, from profile: PersonProfile) throws {
        try perform {
            profile.aliases.removeAll { $0.isSameName(as: alias) }
        }
    }

    /// Folds each secondary into `primary`: their names become aliases of `primary`, every game
    /// seat they held now refers to `primary`, and the secondary profiles are deleted. Refused
    /// if any two of them sat in the same game, since one person can't hold two seats.
    func merge(_ secondaries: [PersonProfile], into primary: PersonProfile) throws {
        let secondaries = secondaries.filter { $0.id != primary.id }
        guard !secondaries.isEmpty else { return }
        let merging = [primary] + secondaries
        try perform(check: { try requireNeverPlayedTogether(merging) }) {
            for secondary in secondaries {
                for name in [secondary.name] + secondary.aliases where !primary.answers(to: name) {
                    primary.aliases.append(name)
                }
                if primary.lastName.isEmpty { primary.lastName = secondary.lastName }
            }
            let secondaryIDs = Set(secondaries.map(\.id))
            for module in modules {
                try module.updatePlayerRefs(in: context) { refs in
                    for i in refs.indices where secondaryIDs.contains(refs[i].profileID) {
                        refs[i].profileID = primary.id
                    }
                }
            }
            secondaries.forEach(context.delete)
            try resyncDisplayNames(inGamesWith: [primary.id])
        }
    }

    /// Deletes profiles that no game refers to. Throws `playerInUse` (and deletes nothing) if any do.
    func delete(_ profiles: [PersonProfile]) throws {
        try perform(check: {
            let counts = try gameCounts()
            if let used = profiles.first(where: { counts[$0.id, default: 0] > 0 }) {
                throw PlayerProfileError.playerInUse(name: used.fullName, games: counts[used.id, default: 0])
            }
        }) {
            profiles.forEach(context.delete)
        }
    }

    /// Brings every game's display names up to date with the roster, by profile ID only.
    /// Catches renames that raced a game created on another device. A seat is only rewritten
    /// when its current name is one the player is known by, so a device still holding an
    /// out-of-date profile never undoes a newer rename synced from elsewhere. Never creates
    /// or relinks profiles.
    func refreshCachedNames() throws {
        try resyncDisplayNames(onlyKnownNames: true)
        if context.hasChanges { try context.save() }
    }

    // MARK: - Helpers

    /// Recomputes display names for each game containing any of `ids` (all games when nil).
    /// Seats whose profile isn't on this device keep their cached name.
    private func resyncDisplayNames(inGamesWith ids: Set<UUID>? = nil, onlyKnownNames: Bool = false) throws {
        let byID = Dictionary(try context.fetch(FetchDescriptor<PersonProfile>()).map { ($0.id, $0) },
                              uniquingKeysWith: { first, _ in first })
        for module in modules {
            try module.updatePlayerRefs(in: context) { refs in
                if let ids, !refs.contains(where: { ids.contains($0.profileID) }) { return }
                let seated = refs.compactMap { byID[$0.profileID] }
                for i in refs.indices {
                    guard let profile = byID[refs[i].profileID] else { continue }
                    if onlyKnownNames && !profile.answers(to: refs[i].cachedBaseName) { continue }
                    refs[i].cachedName = PlayerRef.displayName(for: profile, among: seated)
                }
            }
        }
    }

    private func requireNeverPlayedTogether(_ profiles: [PersonProfile]) throws {
        var clash: (PersonProfile, PersonProfile)?
        try forEachGame { ids in
            guard clash == nil else { return }
            let present = profiles.filter { ids.contains($0.id) }
            if present.count > 1 { clash = (present[0], present[1]) }
        }
        if let (a, b) = clash { throw PlayerProfileError.playedTogether(first: a.fullName, second: b.fullName) }
    }

    /// Calls `body` with the set of profile IDs seated in each saved game. Changes nothing.
    private func forEachGame(_ body: (Set<UUID>) -> Void) throws {
        for module in modules {
            try module.updatePlayerRefs(in: context) { refs in body(Set(refs.map(\.profileID))) }
        }
    }

    private func perform(check: () throws -> Void = {}, _ change: () throws -> Void) throws {
        // Commit the user's pending edits first, so the rollback below can only undo this operation.
        if context.hasChanges { try context.save() }
        try check()
        do {
            try change()
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
