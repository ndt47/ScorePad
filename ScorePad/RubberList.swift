import SwiftUI

struct RubberList: View {
    @StateObject var store: Store
    @SceneStorage("RubberList.selectedRubberId") private var selectedRubberId: Rubber.ID?
    @State private var creatingRubber = false
    @Environment(\.scenePhase) private var scenePhase

    var currentRubber: Rubber? {
        guard let id = selectedRubberId, let rubber = store.rubber(with: id) else { return nil }
        return rubber
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedRubberId) {
                ForEach(store.rubbers) { item in
                    let selected = selectedRubberId == item.id
                    NavigationLink(value: item) {
                        RubberListCell(rubber: item)
                    }
                    .selected(selected)
                }
                .onDelete {
                    store.deleteRubbers(at: $0)
                    Task {
                        try await store.save()
                    }
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: Rubber.self) { rubber in
                RubberView(rubber: rubber)
                    .environmentObject(rubber)
            }
            .navigationTitle("Rubbers")
            .onAppear {
                do {
                    try store.loadIfNecessary()
                } catch {
                    print(String(describing: error))
                }
                if store.rubbers.isEmpty {
                    creatingRubber = true
                }

                if Self.isIPhone {
                    selectedRubberId = nil
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        creatingRubber = true
                    }, label: {
                        Label("New Rubber", systemImage: "plus")
                    })
                    .labelStyle(.titleOnly)
                }
            }
            .sheet(isPresented: $creatingRubber) {
                NewRubber(store: store)
                    .presentationDetents([.medium])
                    .edgesIgnoringSafeArea(.all)
            }

        } detail: {
            ZStack {
                if let rubber = currentRubber {
                    RubberView(rubber: rubber)
                        .environmentObject(rubber)
                } else if store.rubbers.isEmpty {
                    Button {
                        creatingRubber = true
                    } label: {
                        Label("Create rubber", image: "pencil")
                            .labelStyle(.titleOnly)
                            .font(.largeTitle)
                    }
                } else {
                    Text("Select a rubber")
                        .font(.largeTitle)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: scenePhase) { newScenePhase in
            if newScenePhase == .background {
                Task {
                    try await store.save()
                }
            }
        }
        .environmentObject(store)

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RubberList(store: .mock)
    }
}
