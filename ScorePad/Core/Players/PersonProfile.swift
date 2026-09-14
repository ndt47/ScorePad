import Foundation
import SwiftData

/// One real person on the shared roster. Names are not unique: two people can share a first
/// name or a nickname, and `lastName` is how the roster and pickers tell them apart.
@Model
final class PersonProfile {
    var id: UUID = UUID()
    /// The name games display, e.g. "Bob".
    var name: String = ""
    /// Optional; shown wherever same-named players need telling apart.
    var lastName: String = ""
    var aliases: [String] = []
    var dateCreated: Date = Date.now

    init(name: String, lastName: String = "") {
        self.id = UUID()
        self.name = name
        self.lastName = lastName
        self.aliases = []
        self.dateCreated = .now
    }

    /// "Bob Smith", or just "Bob" when there is no last name.
    var fullName: String {
        lastName.normalizedName.isEmpty ? name : "\(name) \(lastName.normalizedName)"
    }

    /// True if `candidate` is this player's name, full name, or one of their aliases.
    func answers(to candidate: String) -> Bool {
        name.isSameName(as: candidate)
            || fullName.isSameName(as: candidate)
            || aliases.contains { $0.isSameName(as: candidate) }
    }

    /// Every roster profile a typed name could mean.
    static func candidates(for name: String, in roster: [PersonProfile]) -> [PersonProfile] {
        roster.filter { $0.answers(to: name) }
    }

    /// Type-ahead suggestions for `typed`. Every player the name could mean comes first and is
    /// never cut, so an ambiguous name always lists its candidates; partial matches on a name
    /// or alias fill the rest, up to `limit`.
    static func suggestions(for typed: String, in roster: [PersonProfile], limit: Int) -> [PersonProfile] {
        let typed = typed.normalizedName
        guard !typed.isEmpty else { return [] }
        let exact = candidates(for: typed, in: roster)
        let partial = roster.filter { profile in
            !exact.contains(profile)
                && (profile.fullName.localizedCaseInsensitiveContains(typed)
                    || profile.aliases.contains { $0.localizedCaseInsensitiveContains(typed) })
        }
        return exact + partial.prefix(max(0, limit - exact.count))
    }
}

extension String {
    /// The form in which player names are stored.
    var normalizedName: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The form in which player names are compared. Every name comparison goes through this,
    /// so form validation and profile resolution always agree on who a name refers to.
    var nameKey: String {
        normalizedName.lowercased()
    }

    func isSameName(as other: String) -> Bool {
        nameKey == other.nameKey
    }
}
