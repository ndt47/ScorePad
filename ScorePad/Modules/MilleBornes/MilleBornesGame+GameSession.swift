import SwiftUI
import SwiftData

extension MilleBornesGame: GameSession {
    typealias CellView = MilleBornesListCell
    typealias NewSessionView = NewMilleBornesGame

    static var fetchDescriptor: FetchDescriptor<MilleBornesGame> {
        FetchDescriptor(sortBy: [SortDescriptor(\MilleBornesGame.dateCreated, order: .reverse)])
    }
    static var openSectionTitle: String  { "In Progress" }
    static var closedSectionTitle: String { "Completed Games" }
    static var navigationTitle: String   { "Mille Bornes" }
    static var newButtonTitle: String    { "New Game" }

    var sessionID: String { id.uuidString }
}

extension MilleBornesListCell: GameSessionCellView {
    init(session: MilleBornesGame) {
        self.init(game: session)
    }
}

extension NewMilleBornesGame: NewGameSessionView {
    init(onSave: @escaping (String) -> Void) {
        self.init(onSave: { onSave($0.uuidString) })
    }
}
