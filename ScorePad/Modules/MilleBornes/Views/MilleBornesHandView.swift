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
                    TeamScoreEditor(score: $team1, otherScore: team2)
                }
                Section(game.team2Label) {
                    TeamScoreEditor(score: $team2, otherScore: team1)
                }
            }
            .navigationTitle(editingHand == nil ? "New Hand" : "Edit Hand")
#if os(macOS)
            .formStyle(.grouped)
#endif
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
        .environment(\.isTwoPlayerGame, game.isTwoPlayerGame)
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
    var otherScore: MilleBornesTeamScore
    @Environment(\.isTwoPlayerGame) var isTwoPlayerGame

    private var tripTarget: Int { isTwoPlayerGame ? (score.usedExtension ? 1000 : 700) : 1000 }
    private var shutOut: Bool { score.tripCompleted(isTwoPlayerGame: isTwoPlayerGame) && otherScore.totalMiles == 0 }
    private var totalHandScore: Int { score.handScore(isTwoPlayerGame: isTwoPlayerGame) + (shutOut ? 500 : 0) }

    private func cardRange(denomination: Int, current: Int, hardCap: Int) -> ClosedRange<Int> {
        let additionalAllowed = max(0, (tripTarget - score.totalMiles) / denomination)
        return 0...min(hardCap, current + additionalAllowed)
    }

    @ViewBuilder
    private func autoRow(_ label: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("auto")
                .font(.caption)
                .foregroundColor(.secondary)
            Image(systemName: "checkmark")
                .foregroundColor(.green)
        }
    }

    var body: some View {
        // Miles — all five denominations in one compact row
        VStack(spacing: 6) {
            HStack {
                Text("Miles")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(score.totalMiles)")
                    .fontDesign(.monospaced)
                    .fontWeight(.semibold)
                    .foregroundColor(score.totalMiles > 0 ? .primary : .secondary)
            }
            HStack(spacing: 0) {
                VerticalStepper(icon: "🐌", label: "25",  value: $score.cards25,  range: cardRange(denomination: 25,  current: score.cards25,  hardCap: 10))
                VerticalStepper(icon: "🐢", label: "50",  value: $score.cards50,  range: cardRange(denomination: 50,  current: score.cards50,  hardCap: 10))
                VerticalStepper(icon: "🦋", label: "75",  value: $score.cards75,  range: cardRange(denomination: 75,  current: score.cards75,  hardCap: 10))
                VerticalStepper(icon: "🐇", label: "100", value: $score.cards100, range: cardRange(denomination: 100, current: score.cards100, hardCap: 12))
                VerticalStepper(icon: "🦅", label: "200", value: $score.cards200, range: cardRange(denomination: 200, current: score.cards200, hardCap: 2))
            }
        }
        .padding(.vertical, 4)

        // Safeties — one button per card, coup fourré checkbox beneath each
        VStack(spacing: 4) {
            HStack {
                Text("Safeties")
                    .fontWeight(.semibold)
                Spacer()
            }
            HStack(spacing: 4) {
                SafetyButton(icon: "🚒", state: $score.rightOfWay,
                             isUnavailable: otherScore.rightOfWay.played)
                SafetyButton(icon: "🛞", state: $score.punctureProof,
                             isUnavailable: otherScore.punctureProof.played)
                SafetyButton(icon: "🏎️", state: $score.drivingAce,
                             isUnavailable: otherScore.drivingAce.played)
                SafetyButton(icon: "⛽", state: $score.extraTank,
                             isUnavailable: otherScore.extraTank.played)
            }
        }
        .padding(.vertical, 4)

        // Auto-detected bonuses
        if score.tripCompleted(isTwoPlayerGame: isTwoPlayerGame) { autoRow("Trip Completed") }
        if score.allFourSafeties { autoRow("All 4 Safeties") }
        if score.safeTrip(isTwoPlayerGame: isTwoPlayerGame) { autoRow("Safe Trip") }

        // Called Extension — 2-player only; enabled only at exactly 700 miles
        if isTwoPlayerGame {
            Toggle("Called Extension", isOn: $score.usedExtension)
                .disabled(score.totalMiles != 700 || otherScore.usedExtension)
        }

        // Trip-completion bonuses
        if score.tripCompleted(isTwoPlayerGame: isTwoPlayerGame) {
            if shutOut { autoRow("Shut Out") }
            Toggle("Delayed Action", isOn: $score.delayedAction)
        }

        // Hand total
        HStack {
            Text("Hand Total")
                .fontWeight(.semibold)
            Spacer()
            Text(totalHandScore.formatted(.number.grouping(.never)))
                .fontDesign(.monospaced)
                .fontWeight(.bold)
        }
    }
}

// MARK: - Safety Button

struct SafetyButton: View {
    let icon: String
    @Binding var state: MilleBornesSafetyState
    let isUnavailable: Bool

    var body: some View {
        VStack(spacing: 6) {
            Button {
                state.played.toggle()
                if !state.played { state.coupFourre = false }
            } label: {
                Text(icon)
                    .font(.title2)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(state.played ? Color.accentColor.opacity(0.15) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                state.played ? Color.accentColor : Color.secondary.opacity(0.3),
                                lineWidth: 1.5
                            )
                    )
            }
            .buttonStyle(.borderless)
            .disabled(isUnavailable)
            .opacity(isUnavailable ? 0.35 : 1)

            Button {
                state.coupFourre.toggle()
            } label: {
                Image(systemName: state.coupFourre ? "checkmark.square.fill" : "square")
                    .font(.body)
                    .foregroundColor(state.coupFourre ? .accentColor : .secondary)
            }
            .buttonStyle(.borderless)
            .disabled(!state.played || isUnavailable)
            .opacity(!state.played || isUnavailable ? 0.3 : 1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Vertical Stepper

struct VerticalStepper: View {
    let icon: String
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(spacing: 2) {
            Text(icon)
                .font(.title3)

            Button {
                if value < range.upperBound { value += 1 }
            } label: {
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .disabled(value >= range.upperBound)

            Text("\(value)")
                .font(.body.monospacedDigit())
                .fontWeight(value > 0 ? .semibold : .regular)
                .foregroundColor(value > 0 ? .primary : .secondary)
                .frame(maxWidth: .infinity)

            Button {
                if value > range.lowerBound { value -= 1 }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .disabled(value <= range.lowerBound)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MilleBornesHandView_Previews: PreviewProvider {
    static var hand: MilleBornesHand {
        var h = MilleBornesHand()
        h.team1.cards100 = 6; h.team1.cards50 = 2  // 700 miles → tripCompleted auto
        h.team1.rightOfWay.played = true
        h.team1.punctureProof = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team2.cards100 = 3; h.team2.cards50 = 2
        h.team2.drivingAce.played = true
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
