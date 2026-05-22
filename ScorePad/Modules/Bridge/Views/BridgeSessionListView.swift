import SwiftUI
import SwiftData

struct BridgeSessionListView: View {
    var selectedSessionID: Binding<String?>

    @Environment(\.modelContext) private var modelContext
    @Query(FetchDescriptor(sortBy: [SortDescriptor(\Rubber.dateCreated, order: .reverse)]))
    private var rubbers: [Rubber]

    @State private var creatingRubber = false

    private var openRubbers: [Rubber] { rubbers.filter { !$0.isFinished } }
    private var completedRubbers: [Rubber] { rubbers.filter(\.isFinished) }

    /// Converts String? ↔ Rubber.ID? at the module boundary.
    private var selectedRubberID: Binding<Rubber.ID?> {
        Binding(
            get: { selectedSessionID.wrappedValue.flatMap { UUID(uuidString: $0) } },
            set: { selectedSessionID.wrappedValue = $0?.uuidString }
        )
    }

    var body: some View {
        List(selection: selectedRubberID) {
            if !openRubbers.isEmpty {
                Section("Open Rubbers") {
                    ForEach(openRubbers, id: \.id) { rubber in
                        RubberListCell(rubber: rubber)
                            .tag(rubber.id)
                    }
                    .onDelete { offsets in deleteRubbers(from: openRubbers, offsets: offsets) }
                }
            }
            if !completedRubbers.isEmpty {
                Section("Completed Rubbers") {
                    ForEach(completedRubbers, id: \.id) { rubber in
                        RubberListCell(rubber: rubber)
                            .tag(rubber.id)
                    }
                    .onDelete { offsets in deleteRubbers(from: completedRubbers, offsets: offsets) }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Rubbers")
        .onAppear {
            if rubbers.isEmpty { creatingRubber = true }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    creatingRubber = true
                } label: {
                    Label("New Rubber", systemImage: "plus")
                }
                .labelStyle(.titleOnly)
            }
        }
        .sheet(isPresented: $creatingRubber) {
            NewRubber(onSave: { id in selectedRubberID.wrappedValue = id })
                .presentationDetents([.medium])
                .edgesIgnoringSafeArea(.all)
        }
    }

    private func deleteRubbers(from source: [Rubber], offsets: IndexSet) {
        withAnimation {
            for index in offsets { modelContext.delete(source[index]) }
        }
    }
}
