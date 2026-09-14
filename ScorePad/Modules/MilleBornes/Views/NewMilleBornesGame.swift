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
    /// Index into the seating order (Team 1, Team 2, Team 1, Team 2) of the first dealer.
    @State private var dealerSeat = 0

    var onSave: ((MilleBornesGame.ID) -> Void)?

    init(onSave: ((MilleBornesGame.ID) -> Void)? = nil) {
        self.onSave = onSave
    }

    private var team1: [PlayerSlot] { playerCount == 4 ? [t1p1, t1p2] : [t1p1] }
    private var team2: [PlayerSlot] { playerCount == 4 ? [t2p1, t2p2] : [t2p1] }

    private var problem: String? {
        PlayerSlot.problem(with: team1 + team2, roster: roster)
    }

    /// Seats in the order the deal passes, labelled with the typed name or the seat.
    private var seats: [String] {
        let label = { (slot: PlayerSlot, team: Int, player: Int) in
            slot.name.isEmpty ? String(localized: "Team \(team) · Player \(player)") : slot.name
        }
        let team1Labels = team1.enumerated().map { label($1, 1, $0 + 1) }
        let team2Labels = team2.enumerated().map { label($1, 2, $0 + 1) }
        return MilleBornesGame.seatingOrder(team1: team1Labels, team2: team2Labels)
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

                HStack {
                    Text("Dealer:")
                    Picker("Dealer", selection: $dealerSeat) {
                        ForEach(seats.indices, id: \.self) { Text(seats[$0]).tag($0) }
                    }
                    .labelsHidden()
                    Spacer()
                    Button {
                        dealerSeat = Int.random(in: seats.indices)
                    } label: {
                        Label("Random Dealer", systemImage: "dice.fill")
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
        }
        .presentationDetents([.medium, .large])
        .edgesIgnoringSafeArea(.all)
        .onChange(of: playerCount) { _, _ in
            if !seats.indices.contains(dealerSeat) { dealerSeat = 0 }
        }
    }

    private func save() {
        guard problem == nil else { return }
        let refs = PlayerRef.seats(for: PlayerSlot.resolve(team1 + team2, roster: roster, in: modelContext))
        let game = MilleBornesGame(team1Players: Array(refs.prefix(team1.count)),
                                   team2Players: Array(refs.dropFirst(team1.count)),
                                   startingDealerIndex: dealerSeat)
        modelContext.insert(game)
        onSave?(game.id)
        dismiss()
    }
}

struct NewMilleBornesGame_Previews: PreviewProvider {
    static var previews: some View {
        NewMilleBornesGame()
            .modelContainer(for: [MilleBornesGame.self, PersonProfile.self], inMemory: true)
    }
}
