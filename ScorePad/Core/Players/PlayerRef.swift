import Foundation

/// Stable reference to a player by PersonProfile identity, with a cached display name.
/// `profileID` is the sole identity; `cachedName` is a display cache set at game-creation
/// time and refreshed by migratePlayerProfiles() when a PersonProfile is renamed.
/// Stored as a Codable struct (not a SwiftData relationship) to preserve ordering and CloudKit compatibility.
struct PlayerRef: Codable, Equatable {
    var profileID: UUID?    // PersonProfile.id; nil only on pre-migration records
    var cachedName: String  // display cache — never use for identity or lookup

    /// The only public constructor. Always prefer this over any name-only path.
    init(profile: PersonProfile) {
        self.profileID = profile.id
        self.cachedName = profile.name
    }

    /// Internal: for migration code and mocks only. Sets cachedName without a profile link.
    internal init(cachedName: String) {
        self.profileID = nil
        self.cachedName = cachedName
    }

    // "name" retained as a decode-only key for backward compatibility with stored records.
    // Never written by encode(to:).
    enum CodingKeys: String, CodingKey {
        case profileID
        case cachedName
        case name  // legacy decode key
    }

    // Handles three historical formats:
    //   • Old bare-string element ("Alice") from early binary-plist migration
    //   • Old keyed format {"name":"Alice"} from initial PlayerRef storage
    //   • Current keyed format {"cachedName":"Alice","profileID":"..."}
    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            profileID  = try container.decodeIfPresent(UUID.self,   forKey: .profileID)
            cachedName = try container.decodeIfPresent(String.self, forKey: .cachedName)
                      ?? container.decode(String.self,              forKey: .name)
        } else {
            cachedName = try decoder.singleValueContainer().decode(String.self)
            profileID  = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(profileID,  forKey: .profileID)
        try container.encode(cachedName,          forKey: .cachedName)
        // "name" key is intentionally omitted; decoders still accept it for old records.
    }

    // Identity is the profileID when both refs have one; fall back to field equality
    // for legacy/migration records that haven't been linked yet.
    static func == (lhs: PlayerRef, rhs: PlayerRef) -> Bool {
        if let l = lhs.profileID, let r = rhs.profileID { return l == r }
        return lhs.profileID == rhs.profileID && lhs.cachedName == rhs.cachedName
    }
}
