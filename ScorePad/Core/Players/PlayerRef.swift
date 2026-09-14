import Foundation

/// A game's reference to a player: the PersonProfile identity plus a display-name cache.
/// `profileID` is the identity; `cachedName` mirrors the profile's current name so game views
/// can render without fetching profiles. PlayerProfileService keeps it in sync on rename/merge.
/// Stored as a Codable struct (not a SwiftData relationship) to preserve seat order.
struct PlayerRef: Codable, Hashable {
    var profileID: UUID
    var cachedName: String

    init(profile: PersonProfile) {
        self.profileID = profile.id
        self.cachedName = profile.name
    }

    init(profileID: UUID, cachedName: String) {
        self.profileID = profileID
        self.cachedName = cachedName
    }

    func refers(to profile: PersonProfile) -> Bool {
        profileID == profile.id
    }

    /// Refs for one game's seats, in order. Players who share a first name are shown with their
    /// last initial ("Bob S.", "Bob J.") so the game can tell them apart.
    static func seats(for profiles: [PersonProfile]) -> [PlayerRef] {
        profiles.map { PlayerRef(profileID: $0.id, cachedName: displayName(for: $0, among: profiles)) }
    }

    /// `profile`'s name as shown in a game alongside `others`.
    static func displayName(for profile: PersonProfile, among others: [PersonProfile]) -> String {
        let sharesName = others.contains { $0.id != profile.id && $0.name.isSameName(as: profile.name) }
        guard sharesName, let initial = profile.lastName.normalizedName.first else { return profile.name }
        return "\(profile.name) \(initial)."
    }

    /// The name part of a cached display name, without a disambiguating " S." initial.
    var cachedBaseName: String {
        let parts = cachedName.split(separator: " ")
        if parts.count > 1, let last = parts.last, last.count == 2, last.hasSuffix(".") {
            return parts.dropLast().joined(separator: " ")
        }
        return cachedName
    }
}

extension PlayerRef {
    /// A ref with a fresh identity, for previews, mocks and tests only.
    static func preview(_ name: String) -> PlayerRef {
        PlayerRef(profileID: UUID(), cachedName: name)
    }
}
