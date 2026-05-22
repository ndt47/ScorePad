import SwiftUI
import SwiftData

// MARK: - View-Slot Protocols

/// A view that presents the detail for a single recorded session.
protocol GameDetailView: View {
    init(selectedSessionID: String?)
}

/// A compact card representing a game type, shown in the top-level game picker grid.
protocol GameGridCard: View {
    init()
}

// MARK: - GameModule

/// Enumerates every game type the app supports.
/// To add a new game: add a case, provide the required switch branches, and add the
/// game's model types to the ModelContainer in ScorePadApp.
enum GameModule: String, CaseIterable, Identifiable, Hashable {
    case bridge

    var id: String { rawValue }

    var name: String {
        switch self {
        case .bridge: "Bridge"
        }
    }

    var systemImage: String {
        switch self {
        case .bridge: "suit.spade.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .bridge: "Rubber Bridge"
        }
    }

    var modelTypes: [any PersistentModel.Type] {
        switch self {
        case .bridge: [Rubber.self, Auction.self]
        }
    }

    // MARK: View Builders

    @ViewBuilder
    func sessionListView(selectedSessionID: Binding<String?>) -> some View {
        switch self {
        case .bridge:
            GameSessionList(
                fetchDescriptor: FetchDescriptor(sortBy: [SortDescriptor(\Rubber.dateCreated, order: .reverse)]),
                openSectionTitle: "Open Rubbers",
                closedSectionTitle: "Completed Rubbers",
                navigationTitle: "Rubbers",
                newButtonTitle: "New Rubber",
                selectedSessionID: selectedSessionID
            ) { rubber in
                RubberListCell(rubber: rubber)
            } makeNewSessionView: { selectedID in
                NewRubber(onSave: { id in selectedID.wrappedValue = id.uuidString })
                    .presentationDetents([.medium])
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }

    @ViewBuilder
    func detailView(selectedSessionID: String?) -> some View {
        switch self {
        case .bridge: BridgeDetailView(selectedSessionID: selectedSessionID)
        }
    }

    @ViewBuilder
    func gridCardView() -> some View {
        switch self {
        case .bridge: BridgeGridCard()
        }
    }
}
