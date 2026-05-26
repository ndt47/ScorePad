import Foundation

/// Stable reference to a player by PersonProfile identity, with a cached name for resilient display.
/// Stored as a Codable struct (not a SwiftData relationship) to preserve ordering and CloudKit compatibility.
struct PlayerRef: Codable, Equatable {
    var profileID: UUID?  // PersonProfile.id; nil on pre-migration records
    var name: String      // cached at game creation; fallback if profile is deleted

    init(profile: PersonProfile) {
        self.profileID = profile.id
        self.name = profile.name
    }

    init(name: String) {
        self.profileID = nil
        self.name = name
    }

    // Backwards-compatible: handles old bare-string encoding ("Alice") and new keyed encoding.
    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            profileID = try container.decodeIfPresent(UUID.self, forKey: .profileID)
            name = try container.decode(String.self, forKey: .name)
        } else {
            name = try decoder.singleValueContainer().decode(String.self)
            profileID = nil
        }
    }
}
