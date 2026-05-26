import Foundation

struct Player: Codable {
    var ref: PlayerRef
    var position: Position

    var name: String { ref.name }
    var profileID: UUID? {
        get { ref.profileID }
        set { ref.profileID = newValue }
    }

    init(ref: PlayerRef, position: Position) {
        self.ref = ref
        self.position = position
    }

    // Convenience init for mocks and tests
    init(name: String, position: Position) {
        self.ref = PlayerRef(name: name)
        self.position = position
    }

    // Backwards-compatible: old records were stored as {name, position, profileID?}
    enum CodingKeys: String, CodingKey { case ref, position, name, profileID }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        position = try c.decode(Position.self, forKey: .position)
        if c.contains(.ref) {
            ref = try c.decode(PlayerRef.self, forKey: .ref)
        } else {
            let name = try c.decode(String.self, forKey: .name)
            let pid = try c.decodeIfPresent(UUID.self, forKey: .profileID)
            ref = PlayerRef(name: name)
            ref.profileID = pid
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(ref, forKey: .ref)
        try c.encode(position, forKey: .position)
    }
}
