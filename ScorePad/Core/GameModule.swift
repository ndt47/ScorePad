import SwiftUI
import SwiftData

/// A concrete descriptor that each game module registers with the GameRegistry.
/// Uses closure-based view factories to avoid associated-type complexity with Swift existentials.
struct GameModuleDescriptor: Identifiable {
    /// Stable, lowercase string used as a UserDefaults key. Never change after shipping.
    let id: String
    let name: String
    /// SF Symbol name shown in the sidebar and grid card.
    let systemImage: String
    /// Short phrase shown in the grid card, e.g. "Rubber Bridge".
    let subtitle: String

    // MARK: SwiftData
    /// The PersistentModel types this module owns — merged into the shared ModelContainer schema.
    let modelTypes: [any PersistentModel.Type]

    // MARK: View Factories
    /// The session list for this game type. Receives a binding for the selected session ID
    /// (as a String so AppRootView can hold it without knowing the concrete model type).
    let makeSessionListView: (_ selectedSessionID: Binding<String?>) -> AnyView

    /// The detail view for a selected session. Returns its own empty-state when selectedSessionID is nil.
    let makeDetailView: (_ selectedSessionID: String?) -> AnyView

    /// The new-session creation sheet.
    let makeNewSessionView: (
        _ onSave: @escaping (String) -> Void,
        _ onCancel: @escaping () -> Void
    ) -> AnyView

    /// Compact card shown in the top-level GameTypeGridView.
    let makeGridCardView: () -> AnyView
}
