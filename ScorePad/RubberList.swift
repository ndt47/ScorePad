import SwiftUI
import SwiftData

struct RubberList: View {
    @Environment(\.modelContext) private var modelContext
    @Query(FetchDescriptor(sortBy: [SortDescriptor(\Rubber.dateCreated, order: .reverse)]))
    private var rubbers: [Rubber]
    
    private var openRubbers: [Rubber] {
        rubbers.filter({ !$0.isFinished })
    }
    
    private var completedRubbers: [Rubber] {
        rubbers.filter(\.isFinished)
    }
    
    @State private var creatingRubber = false
    @State private var selection: Rubber.ID?
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                if !openRubbers.isEmpty {
                    Section("Open Rubbers") {
                        ForEach(openRubbers, id: \.id) { rubber in
                            NavigationLink {
                                RubberView(rubber: rubber)
                            } label: {
                                RubberListCell(rubber: rubber)
                            }
                        }
                        .onDelete {
                            deleteRubbers(offsets: $0)
                        }
                    }
                }
                if !completedRubbers.isEmpty {
                    Section("Completed Rubbers") {
                        ForEach(completedRubbers, id: \.id) { rubber in
                            NavigationLink {
                                RubberView(rubber: rubber)
                            } label: {
                                RubberListCell(rubber: rubber)
                            }
                        }
                        .onDelete {
                            deleteRubbers(offsets: $0)
                        }
                    }
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
