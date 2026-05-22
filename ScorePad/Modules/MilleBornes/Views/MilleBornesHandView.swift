import SwiftUI

struct MilleBornesHandView: View {
    @EnvironmentObject var game: MilleBornesGame
    @Environment(\.dismiss) private var dismiss

    var editingHand: MilleBornesHand?

    @State private var team1 = MilleBornesTeamScore()
    @State private var team2 = MilleBornesTeamScore()

    var body: some View {
        NavigationStack {
            Form {
                Section(game.team1Label) {
                    TeamScoreEditor(score: $team1)
                }
                Section(game.team2Label) {
                    TeamScoreEditor(score: $team2)
                }
            }
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
        .onAppear {
            if let hand = editingHand {
                team1 = hand.team1
                team2 = hand.team2
            }
        }
    }

    private func save() {
        if var hand = editingHand {
            hand.team1 = team1
            hand.team2 = team2
            game.replaceHand(hand)
        } else {
            var hand = MilleBornesHand()
            hand.team1 = team1
            hand.team2 = team2
            game.addHand(hand)
        }
        dismiss()
    }
}

// MARK: - Team Score Editor

struct TeamScoreEditor: View {
    @Binding var score: MilleBornesTeamScore

    var body: some View {
        // Miles
        HStack {
            Text("Total Miles")
                .fontWeight(.semibold)
            Spacer()
            Text("\(score.totalMiles) mi")
                .fontDesign(.monospaced)
                .foregroundColor(score.totalMiles > 0 ? .primary : .secondary)
        }

        DenominationRow(label: "25 mi", count: $score.cards25, max: 40)
        DenominationRow(label: "50 mi", count: $score.cards50, max: 20)
        DenominationRow(label: "75 mi", count: $score.cards75, max: 14)
        DenominationRow(label: "100 mi", count: $score.cards100, max: 12)
        DenominationRow(label: "200 mi", count: $score.cards200, max: 2)

        // Safeties
        Stepper(value: $score.safeties, in: 0...4) {
            HStack {
                Text("Safeties")
                Spacer()
                Text("×\(score.safeties)")
                    .fontDesign(.monospaced)
                    .foregroundColor(.secondary)
            }
        }
        .onChange(of: score.safeties) {
            if score.coupsFourres > score.safeties {
                score.coupsFourres = score.safeties
            }
        }

        if score.safeties > 0 {
            Stepper(value: $score.coupsFourres, in: 0...score.safeties) {
                HStack {
                    Text("Coups Fourrés")
                    Spacer()
                    Text("×\(score.coupsFourres)")
                        .fontDesign(.monospaced)
                        .foregroundColor(.secondary)
                }
            }
        }

        // Bonuses
        Toggle("Trip Completed", isOn: $score.tripCompleted)
            .onChange(of: score.tripCompleted) {
                if !score.tripCompleted {
                    score.usedExtension = false
                    score.shutOut = false
                    score.delayedAction = false
                }
            }

        Toggle("All 4 Safeties", isOn: $score.allFourSafeties)

        if score.tripCompleted {
            if score.safeTrip {
                HStack {
                    Text("Safe Trip")
                    Spacer()
                    Text("(auto)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
            }
            Toggle("Extension", isOn: $score.usedExtension)
            Toggle("Shut Out", isOn: $score.shutOut)
            Toggle("Delayed Action", isOn: $score.delayedAction)
        }

        // Hand total
        HStack {
            Text("Hand Total")
                .fontWeight(.semibold)
            Spacer()
            Text(score.handScore.formatted(.number.grouping(.never)))
                .fontDesign(.monospaced)
                .fontWeight(.bold)
        }
    }
}

// MARK: - Denomination Row

struct DenominationRow: View {
    let label: String
    @Binding var count: Int
    let max: Int

    var value: Int {
        let miles = Int(label.components(separatedBy: " ").first ?? "0") ?? 0
        return count * miles
    }

    var body: some View {
        Stepper(value: $count, in: 0...max) {
            HStack {
                Text(label)
                    .foregroundColor(.secondary)
                Spacer()
                if count > 0 {
                    Text("×\(count) = \(value)")
                        .fontDesign(.monospaced)
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    Text("×0")
                        .fontDesign(.monospaced)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }
}

struct MilleBornesHandView_Previews: PreviewProvider {
    static var hand: MilleBornesHand {
        var h = MilleBornesHand()
        h.team1.cards100 = 6; h.team1.cards50 = 2
        h.team1.safeties = 2; h.team1.coupsFourres = 1
        h.team1.tripCompleted = true
        h.team2.cards100 = 3; h.team2.cards50 = 2
        h.team2.safeties = 1
        return h
    }

    static var previews: some View {
        Group {
            MilleBornesHandView()
                .environmentObject(MilleBornesGame.mock)
                .previewDisplayName("New Hand")
            MilleBornesHandView(editingHand: hand)
                .environmentObject(MilleBornesGame.mock)
                .previewDisplayName("Edit Hand")
        }
    }
}
