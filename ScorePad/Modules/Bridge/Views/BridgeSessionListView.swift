import SwiftUI
import SwiftData

struct BridgeSessionListView: GameSessionListView {
    var selectedSessionID: Binding<String?>

    init(selectedSessionID: Binding<String?>) {
        self.selectedSessionID = selectedSessionID
    }

    @Environment(\.modelContext) private var modelContext
    @Query(FetchDescriptor(sortBy: [SortDescriptor(\Rubber.dateCreated, order: .reverse)]))
    private var rubbers: [Rubber]

    @State private var creatingRubber = false

    var body: some View {
        GameSessionList(
            open: rubbers.filter { !$0.isFinished },
            closed: rubbers.filter(\.isFinished),
            openSectionTitle: "Open Rubbers",
            closedSectionTitle: "Completed Rubbers",
            navigationTitle: "Rubbers",
            newButtonTitle: "New Rubber",
            selectedSessionID: selectedSessionID,
            onNew: { creatingRubber = true },
            onDelete: { offsets, source in
                for index in offsets { modelContext.delete(source[index]) }
            }
        ) { rubber in
            RubberListCell(rubber: rubber)
        }
        .sheet(isPresented: $creatingRubber) {
            NewRubber(onSave: { id in selectedSessionID.wrappedValue = id.uuidString })
                .presentationDetents([.medium])
                .edgesIgnoringSafeArea(.all)
        }
    }
}
