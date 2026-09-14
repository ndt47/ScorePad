import SwiftUI
import SwiftData

extension UnoGame: GameSession {
    typealias CellView = UnoListCell
    typealias NewSessionView = NewUnoGame

    static var fetchDescriptor: FetchDescriptor<UnoGame> {
        FetchDescriptor(sortBy: [SortDescriptor(\UnoGame.dateCreated, order: .reverse)])
    }
    static var openSectionTitle: String   { "In Progress" }
    static var closedSectionTitle: String { "Completed Games" }
    static var navigationTitle: String    { "Uno" }
    static var newButtonTitle: String     { "New Game" }

    var sessionID: String { id.uuidString }
}

extension UnoListCell: GameSessionCellView {
    init(session: UnoGame) {
        self.init(game: session)
    }
}

extension NewUnoGame: NewGameSessionView {
    init(onSave: @escaping (String) -> Void) {
        self.init(onSave: { onSave($0.uuidString) })
    }
}
