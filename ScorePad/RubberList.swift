import SwiftUI

struct RubberList: View {
    @StateObject var store: Store
    @State private var selectedRubberId: Rubber.ID? = Self.savedSelection
    @State private var creatingRubber = false
    
    var currentRubber: Rubber? {
        guard let id = selectedRubberId, let rubber = store.rubber(with: id) else { return nil }
        return rubber
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedRubberId) {
                ForEach(store.rubbers) { item in
                    NavigationLink(value: item) {
                        RubberCell(rubber: item)
                    }
                    .selected(selectedRubberId == item.id)

                }
                .onDelete {
                    store.deleteRubbers(at: $0)
                    Task {
                        try await store.save()
                    }
                }
            }
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
                } else {
                    Text("Select a rubber")
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: selectedRubberId) { newValue in
            if let value = newValue  {
                UserDefaults.standard.set(value.uuidString, forKey: DefaultsKey.selectedRubberID.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: DefaultsKey.selectedRubberID.rawValue)
            }
        }
        .environmentObject(store)

    }
    
    static var savedSelection: Rubber.ID? {
        guard let stored = UserDefaults.standard.string(forKey: DefaultsKey.selectedRubberID.rawValue) else { return nil }
        
        return UUID(uuidString: stored)
    }
}

struct RubberCell: View {
    @StateObject var rubber: Rubber
    @Environment(\.selected) var selected
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading) {
                    ForEach(Team.allCases, id: \.self) {
                        Text($0.label)
                    }
                }
                .fontWeight(.heavy)
                .frame(alignment: .leading)
                .lineLimit(1)
                .allowsTightening(true)

                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Team.allCases, id: \.self) { team in
                        let player1 = rubber.player(at: team.positions[0]) ?? team.positions[0].label
                        let player2 = rubber.player(at: team.positions[1]) ?? team.positions[1].label
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("\(player1) & \(player2)")
                            if rubber.winningTeam == team {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.orange)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .fontWeight(.light)
                .font(.subheadline)
                .lineLimit(1)
                .allowsTightening(true)

                Spacer()
                
                VStack(alignment: .trailing) {
                    ForEach(Team.allCases, id: \.self) {
                        Text("\(rubber.points(for: $0).total.formatted(.number.grouping(.never)))")
                    }
                }
                .fontDesign(.monospaced)
                .frame(alignment: .trailing)
            }

            HStack(alignment: .firstTextBaseline) {
                Text("Last played").bold()
                Text(rubber.lastModified.formatted(date: .abbreviated, time: .shortened))
            }
            .font(.caption)
            .foregroundColor(selected ? .white : .gray)
        }
        .environmentObject(rubber)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RubberList(store: Store.mock)
    }
}
