import SwiftUI
import SwiftData

struct NewPhase10Game: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var playerNames: [String] = ["", ""]

    var onSave: ((Phase10Game.ID) -> Void)?

    init(onSave: ((Phase10Game.ID) -> Void)? = nil) {
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(playerNames.indices, id: \.self) { i in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Phase10Game.playerColor(for: i))
                                .frame(width: 12, height: 12)
                            TextField("Player \(i + 1)", text: $playerNames[i])
                            if playerNames.count > 2 {
                                Button {
                                    playerNames.remove(at: i)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    if playerNames.count < 8 {
                        Button {
                            playerNames.append("")
                        } label: {
                            Label("Add Player", systemImage: "person.badge.plus")
                        }
                    }
                } header: {
                    Text("Players (\(playerNames.count))")
                }
            }
            .navigationTitle("New Game")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start") { save() }
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

    private func save() {
        let names = playerNames.enumerated().map { (i, name) in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Player \(i + 1)" : trimmed
        }
        let game = Phase10Game(players: names)
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
