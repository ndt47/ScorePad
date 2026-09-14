import SwiftUI
import SwiftData

struct UnoModule: GameModule {
    let id = "uno"
    var name: String { "Uno" }
    var systemImage: String { "rectangle.stack.fill" }
    var subtitle: String { "Uno and Uno Flip" }
    var modelTypes: [any PersistentModel.Type] { [UnoGame.self] }

    @MainActor
    func updatePlayerRefs(in context: ModelContext, _ body: (inout [PlayerRef]) -> Void) throws {
        for game in try context.fetch(FetchDescriptor<UnoGame>()) {
            var refs = game.players
            body(&refs)
            precondition(refs.count == game.players.count, "updatePlayerRefs must not add or remove players")
            if refs != game.players { game.players = refs }
        }
    }

    func sessionListView(selectedSessionID: Binding<String?>) -> GameSessionList<UnoGame> {
        GameSessionList<UnoGame>(selectedSessionID: selectedSessionID)
    }

    func detailView(selectedSessionID: String?) -> UnoDetailView {
        UnoDetailView(selectedSessionID: selectedSessionID)
    }
}
