import SwiftUI
import SwiftData

struct BridgeModule: GameModule {
    let id = "bridge"
    var name: String { "Bridge" }
    var systemImage: String { "suit.spade.fill" }
    var subtitle: String { "Rubber Bridge" }
    var modelTypes: [any PersistentModel.Type] { [Rubber.self, Auction.self] }

    @MainActor
    func updatePlayerRefs(in context: ModelContext, _ body: (inout [PlayerRef]) -> Void) throws {
        for rubber in try context.fetch(FetchDescriptor<Rubber>()) {
            let original = rubber.players.map(\.ref)
            var refs = original
            body(&refs)
            precondition(refs.count == original.count, "updatePlayerRefs must not add or remove players")
            guard refs != original else { continue }
            rubber.players = zip(rubber.players, refs).map { Player(ref: $1, position: $0.position) }
        }
    }

    func sessionListView(selectedSessionID: Binding<String?>) -> GameSessionList<Rubber> {
        GameSessionList<Rubber>(selectedSessionID: selectedSessionID)
    }

    func detailView(selectedSessionID: String?) -> BridgeDetailView {
        BridgeDetailView(selectedSessionID: selectedSessionID)
    }
}
