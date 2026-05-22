import SwiftUI
import SwiftData

struct MilleBornesDetailView: GameDetailView {
    var selectedSessionID: String?

    init(selectedSessionID: String?) {
        self.selectedSessionID = selectedSessionID
    }

    @Query(FetchDescriptor(sortBy: [SortDescriptor(\MilleBornesGame.dateCreated, order: .reverse)]))
    private var games: [MilleBornesGame]

    private var selectedGame: MilleBornesGame? {
        guard let id = selectedSessionID.flatMap({ UUID(uuidString: $0) }) else { return nil }
        return games.first { $0.id == id }
    }

    var body: some View {
        MilleBornesGameView(game: selectedGame)
    }
}
