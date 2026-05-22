import SwiftUI
import SwiftData

struct BridgeModule: GameModule {
    let id = "bridge"
    var name: String { "Bridge" }
    var systemImage: String { "suit.spade.fill" }
    var subtitle: String { "Rubber Bridge" }
    var modelTypes: [any PersistentModel.Type] { [Rubber.self, Auction.self] }

    func sessionListView(selectedSessionID: Binding<String?>) -> GameSessionList<Rubber> {
        GameSessionList<Rubber>(selectedSessionID: selectedSessionID)
    }

    func detailView(selectedSessionID: String?) -> BridgeDetailView {
        BridgeDetailView(selectedSessionID: selectedSessionID)
    }
}
