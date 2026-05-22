import SwiftUI
import SwiftData

// MARK: - Supporting Protocols

/// A view that renders a single game session row. Modules provide a concrete type
/// that GameSessionList instantiates directly — no closure parameter needed.
protocol GameSessionCellView: View {
    associatedtype S
    init(session: S)
}

/// A view presented as a sheet for creating a new game session. The onSave callback
/// receives the new session's stable string ID so navigation can follow the save.
protocol NewGameSessionView: View {
    init(onSave: @escaping (String) -> Void)
}

// MARK: - GameSession

/// A SwiftData model type that represents one recorded session of a game.
/// Conforming types provide their own fetch ordering, section/nav titles, and
/// associated cell and new-session views — so GameSessionList needs no configuration.
protocol GameSession: PersistentModel {
    associatedtype CellView: GameSessionCellView where CellView.S == Self
    associatedtype NewSessionView: NewGameSessionView

    static var fetchDescriptor: FetchDescriptor<Self> { get }
    static var openSectionTitle: String { get }
    static var closedSectionTitle: String { get }
    static var navigationTitle: String { get }
    static var newButtonTitle: String { get }

    var sessionID: String { get }
    var isFinished: Bool { get }
    var dateCreated: Date { get }
}

// Default section and button titles — override in a conformance to customise.
extension GameSession {
    static var openSectionTitle: String { "Open" }
    static var closedSectionTitle: String { "Finished" }
    static var navigationTitle: String { "Sessions" }
    static var newButtonTitle: String { "New" }
}
