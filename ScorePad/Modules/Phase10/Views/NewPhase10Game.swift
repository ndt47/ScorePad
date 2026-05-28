import SwiftUI
import SwiftData

struct NewPhase10Game: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var profiles: [PersonProfile?] = [nil, nil]

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

    private func save() {
        let refs: [PlayerRef] = profiles.enumerated().map { i, profile in
            profile.map { PlayerRef(profile: $0) } ?? PlayerRef(cachedName: "Player \(i + 1)")
        }
        let game = Phase10Game(players: refs)
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
