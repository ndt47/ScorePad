import SwiftUI
import SwiftData

// MARK: - View-Slot Protocol

/// A view that presents the detail for a single recorded session.
protocol GameDetailView: View {
    init(selectedSessionID: String?)
}

// MARK: - GameModule

/// Describes a game type the app supports. Concrete implementations live in each
/// game's module — Core has no knowledge of specific games. Adding a game means
/// conforming to this protocol and registering an instance in ScorePadApp; no
/// Core files need to change.
///
/// View factories use associated types so call sites remain strongly typed.
/// AppRootView dispatches to them via SE-0352 implicitly opened existentials.
protocol GameModule: Identifiable where ID == String {
    var name: String { get }
    var systemImage: String { get }
    var subtitle: String { get }
    var modelTypes: [any PersistentModel.Type] { get }

    associatedtype SessionListView: View
    associatedtype DetailView: GameDetailView

    @ViewBuilder func sessionListView(selectedSessionID: Binding<String?>) -> SessionListView
    @ViewBuilder func detailView(selectedSessionID: String?) -> DetailView
}

// MARK: - Existential-compatible dispatch
//
// `any GameModule` cannot call the associated-type methods directly; Swift can't
// determine the concrete return type at the call site. These extension methods wrap
// the concrete views in AnyView so they can be called on `any GameModule` from
// AppRootView's navigation infrastructure. Module authors only implement the
// strongly-typed associated-type methods above.
extension GameModule {
    func makeSessionListView(selectedSessionID: Binding<String?>) -> AnyView {
        AnyView(sessionListView(selectedSessionID: selectedSessionID))
    }

    func makeDetailView(selectedSessionID: String?) -> AnyView {
        AnyView(detailView(selectedSessionID: selectedSessionID))
    }
}
