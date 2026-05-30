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

// MARK: - PlayerPickerField

/// A text field with type-ahead suggestions drawn from the shared PersonProfile roster.
/// Resolves the entered name to a PersonProfile on focus-loss or submit:
///   - Existing name → links to the matching PersonProfile (no duplicate created)
///   - New name      → creates and inserts a PersonProfile, then links to it
/// The `profile` binding is the sole output; callers need not touch the roster.
struct PlayerPickerField: View {
    let label: String
    @Binding var profile: PersonProfile?

    init(_ label: String, profile: Binding<PersonProfile?>) {
        self.label = label
        self._profile = profile
        self._text = State(initialValue: profile.wrappedValue?.name ?? "")
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.playerPickerConfig) private var config
    @Query(sort: \PersonProfile.name) private var roster: [PersonProfile]

    @State private var text: String
    @FocusState private var focused: Bool
    @State private var showSuggestions = false

    private var suggestions: [PersonProfile] {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        return Array(
            roster
                .filter {
                    $0.name.localizedCaseInsensitiveContains(trimmed)
                        || $0.aliases.contains { $0.localizedCaseInsensitiveContains(trimmed) }
                }
                .prefix(config.maxSuggestions)
        )
    }

    var body: some View {
        TextField(config.prompt.isEmpty ? label : config.prompt, text: $text)
            .focused($focused)
            .onSubmit { resolveIfNeeded() }
            .onChange(of: text) { _, newValue in
                if profile?.name != newValue { profile = nil }
                showSuggestions = focused && !suggestions.isEmpty
            }
            .onChange(of: focused) { _, isFocused in
                if !isFocused { resolveIfNeeded() }
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
                    text = suggestion.name
                    profile = suggestion
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

    private func resolveIfNeeded() {
        guard profile == nil else { return }
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let existing = roster.first(where: {
            $0.name.lowercased() == trimmed.lowercased()
                || $0.aliases.contains { $0.lowercased() == trimmed.lowercased() }
        }) {
            profile = existing
        } else {
            let p = PersonProfile(name: trimmed)
            modelContext.insert(p)
            profile = p
        }
    }
}
