import SwiftUI
import SwiftData

// MARK: - Rubber: GameSession

extension Rubber: GameSession {
    typealias CellView = RubberListCell
    typealias NewSessionView = NewRubber

    static var fetchDescriptor: FetchDescriptor<Rubber> {
        FetchDescriptor(sortBy: [SortDescriptor(\Rubber.dateCreated, order: .reverse)])
    }
    static var openSectionTitle: String  { "Open Rubbers" }
    static var closedSectionTitle: String { "Completed Rubbers" }
    static var navigationTitle: String   { "Rubbers" }
    static var newButtonTitle: String    { "New Rubber" }

    var sessionID: String { id.uuidString }
}

// MARK: - RubberListCell: GameSessionCellView

extension RubberListCell: GameSessionCellView {
    init(session: Rubber) {
        self.init(rubber: session)
    }
}

// MARK: - NewRubber: NewGameSessionView

extension NewRubber: NewGameSessionView {
    init(onSave: @escaping (String) -> Void) {
        self.init(onSave: { onSave($0.uuidString) })
    }
}
