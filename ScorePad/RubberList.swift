import SwiftUI

struct RubberList: View {
    @StateObject var store: Store
    @State private var selectedRubberId: Rubber.ID?
    @State private var creatingRubber = false
    @State var currentRubber: Rubber? = nil
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedRubberId) {
                ForEach(store.rubbers) { item in
                    RubberCell(rubber: item)
                }
                .onDelete {
                    store.deleteRubbers(at: $0)
                    Task {
                        try await store.save()
                    }
                }
            }
            .onAppear {
                do {
                    try store.load()
                } catch {
                    print(String(describing: error))
                }
                if store.rubbers.isEmpty {
                    creatingRubber = true
                }
                if Self.isIPhone {
                    selectedRubberId = nil
                } else if selectedRubberId == nil {
                    selectedRubberId = store.rubbers.first?.id
                }
                if !store.rubbers.isEmpty {
                    Task {
                        do {
                            try await store.save()
                        } catch {
                            print(String(describing: error))
                        }
                    }
                }
            }
            .onChange(of: selectedRubberId) { _ in
                if let id = selectedRubberId {
                    currentRubber = store.rubber(with: id)
                } else {
                    currentRubber = nil
                }
            }
            .navigationTitle("Rubbers")
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
            .navigationSplitViewStyle(.balanced)
            .navigationSplitViewColumnWidth(min: 280, ideal: 400, max: 500)
            .sheet(isPresented: $creatingRubber) {
                NewRubber(store: store)
            }
        } detail: {
            ZStack {
                if let selectedRubberId,
                   let rubber = store.rubber(with: selectedRubberId) {
                    RubberView(rubber: rubber)
                } else {
                    EmptyView()
                }
            }
        }
    }
}

struct RubberCell: View {
    let rubber: Rubber
    var body: some View {
        VStack {
            RubberHeader()
            HStack {
                HStack(alignment: .firstTextBaseline) {
                    Text("Created")
                        .bold()
                    Text(rubber.dateCreated.formatted(date: .numeric, time: .shortened))
                }
                    .frame(maxWidth: .infinity)
                HStack(alignment: .firstTextBaseline) {
                    Text("Updated")
                        .bold()
                    Text(rubber.lastModified.formatted(date: .numeric, time: .shortened))

                }
                    .frame(maxWidth: .infinity)

            }
                .font(.caption)
        }
        .environmentObject(rubber)

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RubberList(store: Store.mock)
    }
}
