import SwiftUI
import SwiftData

struct NewMilleBornesGame: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PersonProfile.name) private var roster: [PersonProfile]

    @State private var playerCount = 2
    @State private var t1p1 = PlayerSlot()
    @State private var t1p2 = PlayerSlot()
    @State private var t2p1 = PlayerSlot()
    @State private var t2p2 = PlayerSlot()
    @State private var saveError: String?

    var onSave: ((MilleBornesGame.ID) -> Void)?

    init(onSave: ((MilleBornesGame.ID) -> Void)? = nil) {
        self.onSave = onSave
    }

    private var team1: [PlayerSlot] { playerCount == 4 ? [t1p1, t1p2] : [t1p1] }
    private var team2: [PlayerSlot] { playerCount == 4 ? [t2p1, t2p2] : [t2p1] }

    private var problem: String? {
        PlayerSlot.problem(with: team1 + team2, roster: roster)
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
                        PlayerPickerField("Player 1", slot: $t1p1)
                        if playerCount == 4 {
                            PlayerPickerField("Player 2", slot: $t1p2)
                        }
                    }
                    Divider()
                        .frame(height: playerCount == 4 ? 120 : 80)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Team 2")
                            .font(.title2).bold()
                        PlayerPickerField("Player 1", slot: $t2p1)
                        if playerCount == 4 {
                            PlayerPickerField("Player 2", slot: $t2p2)
                        }
                    }
                }

                if let problem {
                    Text(problem)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                        .disabled(problem != nil)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
#else
                ToolbarItem { Button("Save") { save() }.disabled(problem != nil) }
                ToolbarItem { Button("Cancel") { dismiss() } }
#endif
            }
            .errorAlert($saveError)
        }
        .presentationDetents([.medium])
        .edgesIgnoringSafeArea(.all)
    }

    private func save() {
        guard problem == nil else { return }
        do {
            let refs = try PlayerSlot.resolve(team1 + team2, in: modelContext).map(PlayerRef.init(profile:))
            let game = MilleBornesGame(team1Players: Array(refs.prefix(team1.count)),
                                       team2Players: Array(refs.dropFirst(team1.count)))
            modelContext.insert(game)
            onSave?(game.id)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}

struct NewMilleBornesGame_Previews: PreviewProvider {
    static var previews: some View {
        NewMilleBornesGame()
            .modelContainer(for: [MilleBornesGame.self, PersonProfile.self], inMemory: true)
    }
}
