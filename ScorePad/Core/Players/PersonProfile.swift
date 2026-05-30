import Foundation
import SwiftData

@Model
final class PersonProfile {
    var id: UUID = UUID()
    var name: String = ""
    var aliases: [String] = []
    var dateCreated: Date = Date.now

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.aliases = []
        self.dateCreated = .now
    }
}
