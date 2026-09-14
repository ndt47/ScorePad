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

/// One seat in a new-game form: the name as typed, plus the roster profile the user picked
/// from the suggestions, if any. Nothing touches the roster until the form commits and calls
/// `PlayerSlot.resolve`, so typos and cancelled forms never create profiles.
struct PlayerSlot: Identifiable, Equatable {
    let id = UUID()
    var text = ""
    var profile: PersonProfile?

    var name: String { text.normalizedName }

    /// Why these seats can't start a game yet, or nil when every seat names a different player.
    static func problem(with slots: [PlayerSlot], roster: [PersonProfile]) -> String? {
        if slots.contains(where: { $0.name.isEmpty }) {
            return String(localized: "Enter a name for every player.")
        }
        var seen: [String: String] = [:]  // identity → name as typed
        for slot in slots {
            let identity = (slot.profile ?? PersonProfile.matching(slot.name, in: roster))?.id.uuidString
                ?? slot.name.lowercased()
            if let earlier = seen[identity] {
                return earlier.isSameName(as: slot.name)
                    ? String(localized: "\(slot.name) is entered more than once.")
                    : String(localized: "\(earlier) and \(slot.name) are the same player.")
            }
            seen[identity] = slot.name
        }
        return nil
    }

    /// The profile for each seat: the picked suggestion, else the roster match for the typed
    /// name, else a new profile inserted into `context`. Call only when committing the form.
    @MainActor
    static func resolve(_ slots: [PlayerSlot], in context: ModelContext) throws -> [PersonProfile] {
        var roster = try context.fetch(FetchDescriptor<PersonProfile>())
        return slots.map { slot in
            if let picked = slot.profile { return picked }
            if let existing = PersonProfile.matching(slot.name, in: roster) { return existing }
            let created = PersonProfile(name: slot.name)
            context.insert(created)
            roster.append(created)
            return created
        }
    }
}

// MARK: - PlayerPickerField

/// A text field with type-ahead suggestions drawn from the shared PersonProfile roster.
/// Choosing a suggestion links the seat to that profile; typing clears the link. The slot's
/// text is always current, so a form can save while this field still has focus.
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
        let typed = slot.name
        guard !typed.isEmpty else { return [] }
        return Array(
            roster
                .filter {
                    $0.name.localizedCaseInsensitiveContains(typed)
                        || $0.aliases.contains { $0.localizedCaseInsensitiveContains(typed) }
                }
                .prefix(config.maxSuggestions)
        )
    }

    var body: some View {
        TextField(config.prompt.isEmpty ? label : config.prompt, text: $slot.text)
            .focused($focused)
            .onChange(of: slot.text) { _, newValue in
                if let picked = slot.profile, picked.name != newValue { slot.profile = nil }
                showSuggestions = focused && !suggestions.isEmpty
            }
            .onChange(of: focused) { _, isFocused in
                showSuggestions = isFocused && !suggestions.isEmpty
            }
            .popover(isPresented: $showSuggestions, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
                suggestionsPopover
            }
    }

    @ViewBuilder
    private var suggestionsPopover: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions) { suggestion in
                Button {
                    slot.text = suggestion.name
                    slot.profile = suggestion
                    showSuggestions = false
                    focused = false
                } label: {
                    Text(suggestion.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if suggestion.id != suggestions.last?.id {
                    Divider()
                }
            }
        }
        .fixedSize()
        .presentationCompactAdaptation(.popover)
    }
}
