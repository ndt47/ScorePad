import SwiftUI
import SwiftData

struct MilleBornesModule: GameModule {
    let id = "millebornes"
    var name: String { "Mille Bornes" }
    var systemImage: String { "car.fill" }
    var subtitle: String { "The Classic Road Race Card Game" }
    var modelTypes: [any PersistentModel.Type] { [MilleBornesGame.self] }

    @MainActor
    func updatePlayerRefs(in context: ModelContext, _ body: (inout [PlayerRef]) -> Void) throws {
        for game in try context.fetch(FetchDescriptor<MilleBornesGame>()) {
            let split = game.team1Players.count
            let original = game.team1Players + game.team2Players
            var refs = original
            body(&refs)
            precondition(refs.count == original.count, "updatePlayerRefs must not add or remove players")
            guard refs != original else { continue }
            game.team1Players = Array(refs[..<split])
            game.team2Players = Array(refs[split...])
        }
    }

    func sessionListView(selectedSessionID: Binding<String?>) -> GameSessionList<MilleBornesGame> {
        GameSessionList<MilleBornesGame>(selectedSessionID: selectedSessionID)
    }

    func detailView(selectedSessionID: String?) -> MilleBornesDetailView {
        MilleBornesDetailView(selectedSessionID: selectedSessionID)
    }
}
