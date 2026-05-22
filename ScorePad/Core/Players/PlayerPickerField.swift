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
/// Drop-in replacement for TextField in game creation flows.
struct PlayerPickerField: View {
    let label: String
    @Binding var text: String

    init(_ label: String, text: Binding<String>) {
        self.label = label
        self._text = text
    }

    @Environment(\.playerPickerConfig) private var config
    @Query(sort: \PersonProfile.name) private var roster: [PersonProfile]

    @FocusState private var focused: Bool
    @State private var showSuggestions = false

    private var suggestions: [PersonProfile] {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        return Array(
            roster
                .filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
                .prefix(config.maxSuggestions)
        )
    }

    var body: some View {
        TextField(config.prompt.isEmpty ? label : config.prompt, text: $text)
            .focused($focused)
            .onChange(of: text) { _, _ in
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
            ForEach(suggestions) { profile in
                Button {
                    text = profile.name
                    showSuggestions = false
                    focused = false
                } label: {
                    Text(profile.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if profile.id != suggestions.last?.id {
                    Divider()
                }
            }
        }
        .fixedSize()
        .presentationCompactAdaptation(.popover)
    }
}
