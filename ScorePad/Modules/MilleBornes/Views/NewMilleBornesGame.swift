import SwiftUI
import SwiftData

struct NewMilleBornesGame: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var playerCount = 2
    @State private var t1p1Profile: PersonProfile? = nil
    @State private var t1p2Profile: PersonProfile? = nil
    @State private var t2p1Profile: PersonProfile? = nil
    @State private var t2p2Profile: PersonProfile? = nil

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
                        PlayerPickerField("Player 1", profile: $t1p1Profile)
                        if playerCount == 4 {
                            PlayerPickerField("Player 2", profile: $t1p2Profile)
                        }
                    }
                    Divider()
                        .frame(height: playerCount == 4 ? 120 : 80)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Team 2")
                            .font(.title2).bold()
                        PlayerPickerField("Player 1", profile: $t2p1Profile)
                        if playerCount == 4 {
                            PlayerPickerField("Player 2", profile: $t2p2Profile)
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
        let t1 = [t1p1Profile, playerCount == 4 ? t1p2Profile : nil]
            .compactMap { $0.map { PlayerRef(profile: $0) } }
        let t2 = [t2p1Profile, playerCount == 4 ? t2p2Profile : nil]
            .compactMap { $0.map { PlayerRef(profile: $0) } }
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
