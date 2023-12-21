import SwiftUI
import SwiftData

struct RubberList: View {
    @Environment(\.modelContext) private var modelContext
    @Query(FetchDescriptor(sortBy: [SortDescriptor(\Rubber.dateCreated, order: .reverse)]))
    private var rubbers: [Rubber]
    
    @State private var creatingRubber = false
    @State private var selection: Rubber.ID?
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(rubbers, id: \.id) { item in
                    NavigationLink {
                        RubberView(rubber: item)
                    } label: {
                        RubberListCell(rubber: item)
                    }
                }
                .onDelete {
                    deleteRubbers(offsets: $0)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Rubbers")
            .onAppear {
                if rubbers.isEmpty {
                    creatingRubber = true
                } else {
                    selection = rubbers.first?.id
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        creatingRubber = true
                    }, label: {
                        Label("New Rubber", systemImage: "plus")
                    })
                    .labelStyle(.titleOnly)
                }
            }
        } detail: {
            RubberView(rubber: rubbers.first(where: { $0.id == selection }))
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $creatingRubber) {
            NewRubber()
                .presentationDetents([.medium])
                .edgesIgnoringSafeArea(.all)
        }
    }
    
    private func deleteRubbers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(rubbers[index])
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RubberList()
    }
}
