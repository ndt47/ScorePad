import SwiftUI
import SwiftData

struct MilleBornesModule: GameModule {
    let id = "millebornes"
    var name: String { "Mille Bornes" }
    var systemImage: String { "car.fill" }
    var subtitle: String { "The Classic Road Race Card Game" }
    var modelTypes: [any PersistentModel.Type] { [MilleBornesGame.self] }

    func sessionListView(selectedSessionID: Binding<String?>) -> GameSessionList<MilleBornesGame> {
        GameSessionList<MilleBornesGame>(selectedSessionID: selectedSessionID)
    }

    func detailView(selectedSessionID: String?) -> MilleBornesDetailView {
        MilleBornesDetailView(selectedSessionID: selectedSessionID)
    }
}
