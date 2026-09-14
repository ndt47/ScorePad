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
}

extension PlayerRef {
    /// A ref with a fresh identity, for previews, mocks and tests only.
    static func preview(_ name: String) -> PlayerRef {
        PlayerRef(profileID: UUID(), cachedName: name)
    }
}
