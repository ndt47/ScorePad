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

    /// True if `candidate` is this player's name or one of their aliases.
    func answers(to candidate: String) -> Bool {
        name.isSameName(as: candidate) || aliases.contains { $0.isSameName(as: candidate) }
    }

    /// The roster profile a typed name refers to. An exact name match wins over an alias match,
    /// so a player named "Zed" is found even when someone else has "Zed" as an alias.
    static func matching(_ name: String, in roster: [PersonProfile]) -> PersonProfile? {
        roster.first { $0.name.isSameName(as: name) }
            ?? roster.first { $0.aliases.contains { $0.isSameName(as: name) } }
    }
}

extension String {
    /// The form in which player names are stored and compared.
    var normalizedName: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func isSameName(as other: String) -> Bool {
        normalizedName.caseInsensitiveCompare(other.normalizedName) == .orderedSame
    }
}
