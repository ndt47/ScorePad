import SwiftUI
import SwiftData

struct NewPhase10Game: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var profiles: [PersonProfile?] = [nil, nil]
    @State private var startingDealerIndex: Int = 0

    var onSave: ((Phase10Game.ID) -> Void)?

    init(onSave: ((Phase10Game.ID) -> Void)? = nil) {
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(profiles.indices, id: \.self) { i in
                        playerRow(at: i)
                    }
                    .onMove(perform: movePlayers)
                    if profiles.count < 8 {
                        Button {
                            profiles.append(nil)
                        } label: {
                            Label("Add Player", systemImage: "person.badge.plus")
                        }
                    }
                } header: {
                    Text("Players (\(profiles.count))")
                }

                Section("Dealer") {
                    Picker("Starting Dealer", selection: $startingDealerIndex) {
                        ForEach(profiles.indices, id: \.self) { i in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Phase10Game.playerColor(for: i))
                                    .frame(width: 10, height: 10)
                                Text(profiles[i]?.name ?? "Player \(i + 1)")
                            }
                            .tag(i)
                        }
                    }
                    Button("Randomize") {
                        startingDealerIndex = Int.random(in: 0..<profiles.count)
                    }
                }
            }
#if os(iOS)
            .environment(\.editMode, .constant(.active))
#endif
#if os(macOS)
            .formStyle(.grouped)
#endif
            .navigationTitle("New Game")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start") {
                        // Resign first responder so PlayerPickerField's blur-based
                        // resolveIfNeeded() fires before save() reads profiles.
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                        DispatchQueue.main.async { save() }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
#else
                ToolbarItem { Button("Start") { save() } }
                ToolbarItem { Button("Cancel") { dismiss() } }
#endif
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func playerRow(at i: Int) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Phase10Game.playerColor(for: i))
                .frame(width: 12, height: 12)
            PlayerPickerField("Player \(i + 1)", profile: $profiles[i])
            if profiles.count > 2 {
                Button {
                    profiles.remove(at: i)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func movePlayers(from source: IndexSet, to destination: Int) {
        profiles.move(fromOffsets: source, toOffset: destination)
        startingDealerIndex = 0
    }

    private func save() {
        let refs: [PlayerRef] = profiles.enumerated().map { i, profile in
            profile.map { PlayerRef(profile: $0) } ?? PlayerRef(cachedName: "Player \(i + 1)")
        }
        let game = Phase10Game(players: refs, startingDealerIndex: startingDealerIndex)
        modelContext.insert(game)
        onSave?(game.id)
        dismiss()
    }
}

struct NewPhase10Game_Previews: PreviewProvider {
    static var previews: some View {
        NewPhase10Game()
            .modelContainer(for: Phase10Game.self, inMemory: true)
    }
}
