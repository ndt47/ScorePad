import SwiftUI
import SwiftData

struct NewMilleBornesGame: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PersonProfile.name) private var roster: [PersonProfile]

    @State private var playerCount = 2
    @State private var t1p1 = "";  @State private var t1p1Selection: PersonProfile? = nil
    @State private var t1p2 = "";  @State private var t1p2Selection: PersonProfile? = nil
    @State private var t2p1 = "";  @State private var t2p1Selection: PersonProfile? = nil
    @State private var t2p2 = "";  @State private var t2p2Selection: PersonProfile? = nil

    var onSave: ((MilleBornesGame.ID) -> Void)?

    init(onSave: ((MilleBornesGame.ID) -> Void)? = nil) {
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Players", selection: $playerCount) {
                    Text("2 Players").tag(2)
                    Text("4 Players").tag(4)
                }
                .pickerStyle(.segmented)

                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Team 1")
                            .font(.title2).bold()
                        PlayerPickerField("Player 1", text: $t1p1, selection: $t1p1Selection)
                        if playerCount == 4 {
                            PlayerPickerField("Player 2", text: $t1p2, selection: $t1p2Selection)
                        }
                    }
                    Divider()
                        .frame(height: playerCount == 4 ? 120 : 80)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Team 2")
                            .font(.title2).bold()
                        PlayerPickerField("Player 1", text: $t2p1, selection: $t2p1Selection)
                        if playerCount == 4 {
                            PlayerPickerField("Player 2", text: $t2p2, selection: $t2p2Selection)
                        }
                    }
                }

                Spacer()
            }
            .textFieldStyle(.roundedBorder)
            .padding()
            .navigationTitle("New Game")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
#else
                ToolbarItem { Button("Save") { save() } }
                ToolbarItem { Button("Cancel") { dismiss() } }
#endif
            }
        }
        .presentationDetents([.medium])
        .edgesIgnoringSafeArea(.all)
    }

    private func save() {
        // If the user selected from the suggestion list, use the captured profile directly.
        // If they typed a name without selecting, fall back to roster lookup / creation.
        func makeRef(_ name: String, _ selection: PersonProfile?) -> PlayerRef? {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            if let profile = selection { return PlayerRef(profile: profile) }
            let profile = roster.first(where: { $0.name.lowercased() == trimmed.lowercased() })
                ?? { let p = PersonProfile(name: trimmed); modelContext.insert(p); return p }()
            return PlayerRef(profile: profile)
        }

        let t1 = [makeRef(t1p1, t1p1Selection),
                  playerCount == 4 ? makeRef(t1p2, t1p2Selection) : nil].compactMap { $0 }
        let t2 = [makeRef(t2p1, t2p1Selection),
                  playerCount == 4 ? makeRef(t2p2, t2p2Selection) : nil].compactMap { $0 }

        let game = MilleBornesGame(team1Players: t1, team2Players: t2)
        modelContext.insert(game)
        onSave?(game.id)
        dismiss()
    }
}

struct NewMilleBornesGame_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NewMilleBornesGame()
                .previewDisplayName("2 Players")
            NewMilleBornesGame()
                .previewDisplayName("4 Players")
        }
    }
}
