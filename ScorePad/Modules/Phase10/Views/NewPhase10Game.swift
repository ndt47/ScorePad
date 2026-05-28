import SwiftUI
import SwiftData

struct NewPhase10Game: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PersonProfile.name) private var roster: [PersonProfile]

    @State private var playerNames:      [String]          = ["", ""]
    @State private var playerSelections: [PersonProfile?]  = [nil, nil]

    var onSave: ((Phase10Game.ID) -> Void)?

    init(onSave: ((Phase10Game.ID) -> Void)? = nil) {
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(playerNames.indices, id: \.self) { i in
                        playerRow(at: i)
                    }
                    if playerNames.count < 8 {
                        Button {
                            playerNames.append("")
                            playerSelections.append(nil)
                        } label: {
                            Label("Add Player", systemImage: "person.badge.plus")
                        }
                    }
                } header: {
                    Text("Players (\(playerNames.count))")
                }
            }
#if os(macOS)
            .formStyle(.grouped)
#endif
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

    @ViewBuilder
    private func playerRow(at i: Int) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Phase10Game.playerColor(for: i))
                .frame(width: 12, height: 12)
            PlayerPickerField("Player \(i + 1)", text: $playerNames[i], selection: $playerSelections[i])
            if playerNames.count > 2 {
                Button {
                    playerNames.remove(at: i)
                    playerSelections.remove(at: i)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func save() {
        let playerRefs: [PlayerRef] = playerNames.enumerated().map { (i, name) in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let selection = i < playerSelections.count ? playerSelections[i] : nil
            if !trimmed.isEmpty, let profile = selection {
                return PlayerRef(profile: profile)
            }
            guard !trimmed.isEmpty else { return PlayerRef(cachedName: "Player \(i + 1)") }
            let profile = roster.first(where: { $0.name.lowercased() == trimmed.lowercased() })
                ?? { let p = PersonProfile(name: trimmed); modelContext.insert(p); return p }()
            return PlayerRef(profile: profile)
        }
        let game = Phase10Game(players: playerRefs)
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
