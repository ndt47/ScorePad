import SwiftUI
import SwiftData

// MARK: - Configuration

struct PlayerPickerConfig {
    var prompt: String = "Enter name"
    var maxSuggestions: Int = 5
}

private struct PlayerPickerConfigKey: EnvironmentKey {
    static let defaultValue = PlayerPickerConfig()
}

extension EnvironmentValues {
    var playerPickerConfig: PlayerPickerConfig {
        get { self[PlayerPickerConfigKey.self] }
        set { self[PlayerPickerConfigKey.self] = newValue }
    }
}

extension View {
    func playerPickerPrompt(_ prompt: String) -> some View {
        transformEnvironment(\.playerPickerConfig) { $0.prompt = prompt }
    }

    func playerPickerMaxSuggestions(_ max: Int) -> some View {
        transformEnvironment(\.playerPickerConfig) { $0.maxSuggestions = max }
    }
}

// MARK: - PlayerSlot

/// One seat in a new-game form: the name as typed, plus what the user chose from the
/// suggestions. Nothing touches the roster until the form commits and calls
/// `PlayerSlot.resolve`, so typos and cancelled forms never create profiles.
struct PlayerSlot: Identifiable, Equatable {
    enum Choice: Equatable {
        /// Use the typed name: the one roster player it matches, or a new player if none.
        case automatic
        /// This roster player, picked from the suggestions.
        case existing(PersonProfile)
        /// A new player, even though the name may match someone already on the roster.
        case new
    }

    /// Who the seat refers to, given the current roster.
    enum Resolution: Equatable {
        case empty
        case existing(PersonProfile)
        case new
        /// The typed name matches several players; the user must pick one.
        case ambiguous([PersonProfile])
    }

    let id = UUID()
    var text = ""
    var choice = Choice.automatic

    var name: String { text.normalizedName }

    func resolution(in roster: [PersonProfile]) -> Resolution {
        guard !name.isEmpty else { return .empty }
        switch choice {
        case .existing(let picked) where roster.contains(where: { $0.id == picked.id }):
            return .existing(picked)
        case .new:
            return .new
        case .existing, .automatic:
            let candidates = PersonProfile.candidates(for: name, in: roster)
            switch candidates.count {
            case 0: return .new
            case 1: return .existing(candidates[0])
            default: return .ambiguous(candidates)
            }
        }
    }

    /// Why these seats can't start a game yet, or nil when every seat is a distinct player.
    static func problem(with slots: [PlayerSlot], roster: [PersonProfile]) -> String? {
        var seen: [String: String] = [:]  // identity → name as typed
        for slot in slots {
            let identity: String
            switch slot.resolution(in: roster) {
            case .empty:
                return String(localized: "Enter a name for every player.")
            case .ambiguous:
                return String(localized: "More than one player is called \(slot.name). Choose one from the suggestions.")
            case .existing(let profile):
                identity = profile.id.uuidString
            case .new:
                // An explicit "new player" is its own person; the same typed name twice is not.
                identity = slot.choice == .new ? slot.id.uuidString : "new:" + slot.name.nameKey
            }
            if let earlier = seen[identity] {
                return earlier.isSameName(as: slot.name)
                    ? String(localized: "\(slot.name) is entered more than once.")
                    : String(localized: "\(earlier) and \(slot.name) are the same player.")
            }
            seen[identity] = slot.name
        }
        return nil
    }

    /// The profile for each seat, inserting a new profile into `context` for each new player.
    /// Call only once `problem(with:roster:)` is nil, with the same roster, so both agree on
    /// every identity.
    @MainActor
    static func resolve(_ slots: [PlayerSlot], roster: [PersonProfile], in context: ModelContext) -> [PersonProfile] {
        var created: [String: PersonProfile] = [:]
        return slots.map { slot in
            if case .existing(let profile) = slot.resolution(in: roster) { return profile }
            let key = slot.choice == .new ? slot.id.uuidString : slot.name.nameKey
            if let made = created[key] { return made }
            let profile = PersonProfile(name: slot.name)
            context.insert(profile)
            created[key] = profile
            return profile
        }
    }
}

// MARK: - PlayerPickerField

/// A text field with type-ahead suggestions from the shared roster. Suggestions show full
/// names and aliases so same-named players can be told apart, plus a "New player" row for
/// someone not on the roster yet. The slot's text is always current, so a form can save while
/// this field still has focus.
struct PlayerPickerField: View {
    let label: String
    @Binding var slot: PlayerSlot

    init(_ label: String, slot: Binding<PlayerSlot>) {
        self.label = label
        self._slot = slot
    }

    @Environment(\.playerPickerConfig) private var config
    @Query(sort: \PersonProfile.name) private var roster: [PersonProfile]

    @FocusState private var focused: Bool
    @State private var showSuggestions = false

    private var suggestions: [PersonProfile] {
        PersonProfile.suggestions(for: slot.name, in: roster, limit: config.maxSuggestions)
    }

    var body: some View {
        TextField(config.prompt.isEmpty ? label : config.prompt, text: $slot.text)
            .focused($focused)
            .onChange(of: slot.text) { _, newValue in
                // Any edit other than the one a pick just made returns the seat to automatic.
                if case .existing(let picked) = slot.choice, picked.fullName == newValue { return }
                slot.choice = .automatic
                showSuggestions = focused && !slot.name.isEmpty
            }
            .onChange(of: focused) { _, isFocused in
                showSuggestions = isFocused && !slot.name.isEmpty
            }
            .popover(isPresented: $showSuggestions, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
                suggestionsPopover
            }
    }

    @ViewBuilder
    private var suggestionsPopover: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions) { suggestion in
                suggestionRow {
                    slot.text = suggestion.fullName
                    slot.choice = .existing(suggestion)
                } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(suggestion.fullName)
                        if !suggestion.aliases.isEmpty {
                            Text(suggestion.aliases.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Divider()
            }
            suggestionRow {
                slot.choice = .new
            } label: {
                Label("New player “\(slot.name)”", systemImage: "person.badge.plus")
                    .foregroundStyle(.tint)
            }
        }
        .fixedSize()
        .presentationCompactAdaptation(.popover)
    }

    private func suggestionRow(_ action: @escaping () -> Void,
                               @ViewBuilder label: () -> some View) -> some View {
        Button {
            action()
            showSuggestions = false
            focused = false
        } label: {
            label()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
