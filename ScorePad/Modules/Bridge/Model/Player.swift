import Foundation

struct Player: Codable {
    var ref: PlayerRef
    var position: Position

    var name: String { ref.cachedName }

    init(ref: PlayerRef, position: Position) {
        self.ref = ref
        self.position = position
    }
}
