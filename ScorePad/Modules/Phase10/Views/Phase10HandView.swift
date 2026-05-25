import SwiftUI

struct Phase10HandView: View {
    @EnvironmentObject var game: Phase10Game
    @Environment(\.dismiss) private var dismiss

    var editingHand: Phase10Hand?

    @State private var results: [Phase10PlayerResult] = []

    var body: some View {
        NavigationStack {
            Form {
                ForEach(game.players.indices, id: \.self) { i in
                    playerSection(index: i)
                }
            }
#if os(macOS)
            .formStyle(.grouped)
#endif
            .navigationTitle(editingHand == nil ? "New Hand" : "Edit Hand")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
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
        .interactiveDismissDisabled()
        .onAppear { loadResults() }
    }

    @ViewBuilder
    private func playerSection(index i: Int) -> some View {
        let phase = currentPhase(for: i)
        let color = Phase10Game.playerColor(for: i)
        Section {
            HStack(spacing: 6) {
                Text(Phase10Game.phaseIcon(for: phase))
                    .font(.caption)
                Text(Phase10Game.phaseDescription(for: phase))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack {
                Text("Score")
                Spacer()
                if !results.isEmpty {
                    TextField("0", value: $results[i].score, format: .number)
#if os(iOS)
                        .keyboardType(.numberPad)
#endif
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
            if !results.isEmpty {
                Toggle("Completed Phase \(phase)", isOn: $results[i].completedPhase)
                    .tint(color)
            }
        } header: {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(game.players[i])
            }
        }
    }

    // When editing an existing hand, compute the phase at that hand's position in history
    private func currentPhase(for playerIndex: Int) -> Int {
        if let hand = editingHand,
           let handIndex = game.hands.firstIndex(where: { $0.id == hand.id }) {
            return game.phase(for: playerIndex, atHandIndex: handIndex)
        }
        return game.currentPhase(for: playerIndex)
    }

    private func loadResults() {
        if let hand = editingHand {
            results = hand.playerResults
        } else {
            results = Array(repeating: Phase10PlayerResult(), count: game.players.count)
        }
    }

    private func save() {
        guard !results.isEmpty else { return }
        if var hand = editingHand {
            hand.playerResults = results
            game.replaceHand(hand)
        } else {
            var hand = Phase10Hand(playerCount: game.players.count)
            hand.playerResults = results
            game.addHand(hand)
        }
        dismiss()
    }
}

struct Phase10HandView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Phase10HandView()
                .environmentObject(Phase10Game.mock)
                .previewDisplayName("New Hand")
            Phase10HandView(editingHand: Phase10Game.mock.hands[0])
                .environmentObject(Phase10Game.mock)
                .previewDisplayName("Edit Hand")
        }
        .modelContainer(for: Phase10Game.self, inMemory: true)
    }
}
