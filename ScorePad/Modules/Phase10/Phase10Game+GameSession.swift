import SwiftUI
import SwiftData

extension Phase10Game: GameSession {
    typealias CellView = Phase10ListCell
    typealias NewSessionView = NewPhase10Game

    static var fetchDescriptor: FetchDescriptor<Phase10Game> {
        FetchDescriptor(sortBy: [SortDescriptor(\Phase10Game.dateCreated, order: .reverse)])
    }
    static var openSectionTitle: String   { "In Progress" }
    static var closedSectionTitle: String { "Completed Games" }
    static var navigationTitle: String    { "Phase 10" }
    static var newButtonTitle: String     { "New Game" }

    var sessionID: String { id.uuidString }
}

extension Phase10ListCell: GameSessionCellView {
    init(session: Phase10Game) {
        self.init(game: session)
    }
}

extension NewPhase10Game: NewGameSessionView {
    init(onSave: @escaping (String) -> Void) {
        self.init(onSave: { onSave($0.uuidString) })
    }
}
