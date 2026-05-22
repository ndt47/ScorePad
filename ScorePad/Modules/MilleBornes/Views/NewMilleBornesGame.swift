import SwiftUI
import SwiftData

struct NewMilleBornesGame: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var playerCount = 2
    @State private var t1p1 = ""
    @State private var t1p2 = ""
    @State private var t2p1 = ""
    @State private var t2p2 = ""

    var onSave: ((MilleBornesGame.ID) -> Void)?

    init(onSave: ((MilleBornesGame.ID) -> Void)? = nil) {
        self.onSave = onSave
    }

    private var team1Players: [String] {
        [t1p1, playerCount == 4 ? t1p2 : ""]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var team2Players: [String] {
        [t2p1, playerCount == 4 ? t2p2 : ""]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
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
                        TextField("Player 1", text: $t1p1)
                        if playerCount == 4 {
                            TextField("Player 2", text: $t1p2)
                        }
                    }
                    Divider()
                        .frame(height: playerCount == 4 ? 120 : 80)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Team 2")
                            .font(.title2).bold()
                        TextField("Player 1", text: $t2p1)
                        if playerCount == 4 {
                            TextField("Player 2", text: $t2p2)
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
        let game = MilleBornesGame(team1Players: team1Players, team2Players: team2Players)
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
