import SwiftUI
import SwiftData

struct Phase10DetailView: GameDetailView {
    var selectedSessionID: String?

    init(selectedSessionID: String?) {
        self.selectedSessionID = selectedSessionID
    }

    @Query(FetchDescriptor(sortBy: [SortDescriptor(\Phase10Game.dateCreated, order: .reverse)]))
    private var games: [Phase10Game]

    private var selectedGame: Phase10Game? {
        guard let id = selectedSessionID.flatMap({ UUID(uuidString: $0) }) else { return nil }
        return games.first { $0.id == id }
    }

    var body: some View {
        Phase10GameView(game: selectedGame)
    }
}
