import Foundation
import SwiftData

// MARK: - PlayerRef traversal

/// Walks every PlayerRef across all game models, applies `update` to refs matching `predicate`,
/// and writes changed objects back. Does NOT save — callers must call context.save() after.
@MainActor
func updateAllPlayerRefs(
    in context: ModelContext,
    matching predicate: (PlayerRef) -> Bool,
    update: (inout PlayerRef) -> Void
) throws {
    let milleGames   = try context.fetch(FetchDescriptor<MilleBornesGame>())
    let phase10Games = try context.fetch(FetchDescriptor<Phase10Game>())
    let rubbers      = try context.fetch(FetchDescriptor<Rubber>())

    func apply(_ ref: inout PlayerRef) -> Bool {
        guard predicate(ref) else { return false }
        update(&ref)
        return true
    }

    for game in milleGames {
        var t1 = game.team1Players; var t2 = game.team2Players; var changed = false
        for i in t1.indices { if apply(&t1[i]) { changed = true } }
        for i in t2.indices { if apply(&t2[i]) { changed = true } }
        if changed { game.team1Players = t1; game.team2Players = t2 }
    }
    for game in phase10Games {
        var refs = game.players; var changed = false
        for i in refs.indices { if apply(&refs[i]) { changed = true } }
        if changed { game.players = refs }
    }
    for rubber in rubbers {
        var players = rubber.players; var changed = false
        for i in players.indices { if apply(&players[i].ref) { changed = true } }
        if changed { rubber.players = players }
    }
}

// MARK: - Profile operations

/// Renames a PersonProfile, adding the old name as an alias.
/// cachedName propagation is handled by migratePlayerProfiles() on the next foreground activation.
func renameProfile(_ profile: PersonProfile, to newName: String) {
    let trimmed = newName.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty, trimmed != profile.name else { return }
    let oldName = profile.name
    if !profile.aliases.contains(where: { $0.lowercased() == oldName.lowercased() }) {
        profile.aliases.append(oldName)
    }
    profile.aliases.removeAll { $0.lowercased() == trimmed.lowercased() }
    profile.name = trimmed
}

/// Merges `secondary` into `primary`: redirects all PlayerRefs to `primary`, adds `secondary`'s
/// name and aliases onto `primary`, then deletes `secondary`.
/// cachedNames in game records are intentionally preserved (they keep the secondary's name as
/// a historical display value, now backed by the primary profile).
@MainActor
func mergeProfile(
    _ secondary: PersonProfile,
    into primary: PersonProfile,
    context: ModelContext
) throws {
    let namesToAdd = ([secondary.name] + secondary.aliases)
        .filter { candidate in
            candidate.lowercased() != primary.name.lowercased()
                && !primary.aliases.contains(where: { $0.lowercased() == candidate.lowercased() })
        }
    primary.aliases.append(contentsOf: namesToAdd)

    try updateAllPlayerRefs(in: context, matching: { $0.profileID == secondary.id }) { ref in
        ref.profileID = primary.id
    }

    context.delete(secondary)
    try context.save()
}

/// Merges multiple secondaries into primary in one pass, saving once at the end.
@MainActor
func mergeProfiles(
    _ secondaries: [PersonProfile],
    into primary: PersonProfile,
    context: ModelContext
) throws {
    for secondary in secondaries {
        let namesToAdd = ([secondary.name] + secondary.aliases)
            .filter { candidate in
                candidate.lowercased() != primary.name.lowercased()
                    && !primary.aliases.contains(where: { $0.lowercased() == candidate.lowercased() })
            }
        primary.aliases.append(contentsOf: namesToAdd)
        try updateAllPlayerRefs(in: context, matching: { $0.profileID == secondary.id }) { ref in
            ref.profileID = primary.id
        }
        context.delete(secondary)
    }
    try context.save()
}

/// Removes an alias from a PersonProfile and updates any game records whose cachedName matched
/// that alias (under this profile) to the profile's current primary name.
@MainActor
func deleteAlias(
    _ alias: String,
    from profile: PersonProfile,
    context: ModelContext
) throws {
    let aliasLower = alias.lowercased()
    try updateAllPlayerRefs(
        in: context,
        matching: { $0.profileID == profile.id && $0.cachedName.lowercased() == aliasLower }
    ) { ref in
        ref.cachedName = profile.name
    }
    profile.aliases.removeAll { $0.lowercased() == aliasLower }
    try context.save()
}
