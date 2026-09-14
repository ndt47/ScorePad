import SwiftUI
import SwiftData

struct UnoDetailView: GameDetailView {
    var selectedSessionID: String?

    init(selectedSessionID: String?) {
        self.selectedSessionID = selectedSessionID
    }

    @Query(UnoGame.fetchDescriptor)
    private var games: [UnoGame]

    private var selectedGame: UnoGame? {
        guard let id = selectedSessionID.flatMap({ UUID(uuidString: $0) }) else { return nil }
        return games.first { $0.id == id }
    }

    var body: some View {
        UnoGameView(game: selectedGame)
    }
}
