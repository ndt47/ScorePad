import SwiftUI
import SwiftData

struct Phase10Module: GameModule {
    let id = "phase10"
    var name: String { "Phase 10" }
    var systemImage: String { "10.circle.fill" }
    var subtitle: String { "The Classic Phase Card Game" }
    var modelTypes: [any PersistentModel.Type] { [Phase10Game.self] }

    func sessionListView(selectedSessionID: Binding<String?>) -> GameSessionList<Phase10Game> {
        GameSessionList<Phase10Game>(selectedSessionID: selectedSessionID)
    }

    func detailView(selectedSessionID: String?) -> Phase10DetailView {
        Phase10DetailView(selectedSessionID: selectedSessionID)
    }
}
