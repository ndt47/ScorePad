import SwiftUI
import SwiftData

struct BridgeDetailView: GameDetailView {
    var selectedSessionID: String?

    init(selectedSessionID: String?) {
        self.selectedSessionID = selectedSessionID
    }

    @Query(FetchDescriptor(sortBy: [SortDescriptor(\Rubber.dateCreated, order: .reverse)]))
    private var rubbers: [Rubber]

    private var selectedRubber: Rubber? {
        guard let id = selectedSessionID.flatMap({ UUID(uuidString: $0) }) else { return nil }
        return rubbers.first { $0.id == id }
    }

    var body: some View {
        RubberView(rubber: selectedRubber)
    }
}
