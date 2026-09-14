import SwiftUI
import SwiftData

struct NewPhase10Game: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PersonProfile.name) private var roster: [PersonProfile]

    @State private var slots: [PlayerSlot]
    // Tracked by seat identity so the dealer stays with the same player through reordering.
    @State private var dealerID: PlayerSlot.ID

    var onSave: ((Phase10Game.ID) -> Void)?

    init(onSave: ((Phase10Game.ID) -> Void)? = nil) {
        let initial = [PlayerSlot(), PlayerSlot()]
        self._slots = State(initialValue: initial)
        self._dealerID = State(initialValue: initial[0].id)
        self.onSave = onSave
    }

    private var problem: String? {
        PlayerSlot.problem(with: slots, roster: roster)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(slots) { slot in
                        playerRow(binding(for: slot.id))
                    }
                    .onMove { slots.move(fromOffsets: $0, toOffset: $1) }
                    if slots.count < 8 {
                        Button {
                            slots.append(PlayerSlot())
                        } label: {
                            Label("Add Player", systemImage: "person.badge.plus")
                        }
                    }
                } header: {
                    Text("Players (\(slots.count))")
                } footer: {
                    if let problem {
                        Text(problem)
                    }
                }

                Section("Dealer") {
                    Picker("Starting Dealer", selection: $dealerID) {
                        ForEach(slots.indices, id: \.self) { i in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Phase10Game.playerColor(for: i))
                                    .frame(width: 10, height: 10)
                                Text(slots[i].name.isEmpty ? "Player \(i + 1)" : slots[i].name)
                            }
                            .tag(slots[i].id)
                        }
                    }
                    Button("Randomize") {
                        dealerID = slots.randomElement()?.id ?? dealerID
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
                    Button("Start") { save() }
                        .disabled(problem != nil)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
#else
                ToolbarItem { Button("Start") { save() }.disabled(problem != nil) }
                ToolbarItem { Button("Cancel") { dismiss() } }
#endif
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func playerRow(_ slot: Binding<PlayerSlot>) -> some View {
        let i = slots.firstIndex { $0.id == slot.wrappedValue.id } ?? 0
        HStack(spacing: 12) {
            Circle()
                .fill(Phase10Game.playerColor(for: i))
                .frame(width: 12, height: 12)
            PlayerPickerField("Player \(i + 1)", slot: slot)
            if slots.count > 2 {
                Button {
                    remove(slot.wrappedValue)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove Player \(i + 1)")
            }
        }
    }

    // Looks the seat up by id on every access, so a row being torn down after its seat was
    // removed (e.g. a focused field resigning) never writes through a stale index.
    private func binding(for id: PlayerSlot.ID) -> Binding<PlayerSlot> {
        Binding(
            get: { slots.first { $0.id == id } ?? PlayerSlot() },
            set: { newValue in
                if let i = slots.firstIndex(where: { $0.id == id }) { slots[i] = newValue }
            }
        )
    }

    private func remove(_ slot: PlayerSlot) {
        slots.removeAll { $0.id == slot.id }
        if dealerID == slot.id, let first = slots.first {
            dealerID = first.id
        }
    }

    private func save() {
        guard problem == nil else { return }
        let profiles = PlayerSlot.resolve(slots, roster: roster, in: modelContext)
        let dealerIndex = slots.firstIndex { $0.id == dealerID } ?? 0
        let game = Phase10Game(players: profiles.map(PlayerRef.init(profile:)),
                               startingDealerIndex: dealerIndex)
        modelContext.insert(game)
        onSave?(game.id)
        dismiss()
    }
}

struct NewPhase10Game_Previews: PreviewProvider {
    static var previews: some View {
        NewPhase10Game()
            .modelContainer(for: [Phase10Game.self, PersonProfile.self], inMemory: true)
    }
}
