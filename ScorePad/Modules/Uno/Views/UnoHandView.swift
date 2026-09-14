import SwiftUI

/// Records or edits one hand: who went out, the side a Flip hand ended on, and the points left
/// in every other hand. Each "points left" field has a Count button that opens the Card Pad.
struct UnoHandView: View {
    @EnvironmentObject var game: UnoGame
    @Environment(\.dismiss) private var dismiss

    var editingHand: UnoHand?

    @State private var wentOut: Int?
    @State private var side: UnoSide = .light
    @State private var points: [Int] = []
    @State private var counting: CountTarget?
    @FocusState private var focusedField: Int?

    private struct CountTarget: Identifiable {
        let player: Int
        var id: Int { player }
    }

    private var handNumber: Int {
        if let editingHand, let index = game.hands.firstIndex(where: { $0.id == editingHand.id }) {
            return index + 1
        }
        return game.hands.count + 1
    }

    private var opponents: [Int] {
        game.players.indices.filter { $0 != wentOut }
    }

    private var handTotal: Int {
        opponents.reduce(0) { $0 + (points.indices.contains($1) ? points[$1] : 0) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Went Out") {
                    UnoFlowLayout(spacing: 8) {
                        ForEach(game.players.indices, id: \.self) { i in
                            playerChip(i)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if game.edition.hasSides {
                    Section("Hand Ended On") {
                        Picker("Hand ended on", selection: $side) {
                            Label("Light Side", systemImage: "sun.max.fill").tag(UnoSide.light)
                            Label("Dark Side", systemImage: "moon.fill").tag(UnoSide.dark)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }

                Section {
                    if !points.isEmpty {
                        ForEach(opponents, id: \.self) { i in
                            pointsRow(i)
                        }
                    }
                } header: {
                    Text("Points Left in Hand")
                } footer: {
                    Text("If the last card played was a draw card, the next player draws those cards before anyone counts.")
                }
            }
#if os(macOS)
            .formStyle(.grouped)
#endif
            .safeAreaInset(edge: .bottom) { totalBar }
            .onChange(of: focusedField) { _, newValue in
                guard newValue != nil else { return }
#if os(iOS)
                DispatchQueue.main.async {
                    UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                }
#endif
            }
            .navigationTitle("Hand \(handNumber)")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(wentOut == nil)
                }
            }
            .sheet(item: $counting) { target in
                UnoCardPad(playerName: game.players[target.player].cachedName,
                           edition: game.edition,
                           side: game.edition.hasSides ? side : .light) { total in
                    points[target.player] = total
                }
            }
        }
        .interactiveDismissDisabled()
        .onAppear(perform: load)
    }

    private func playerChip(_ i: Int) -> some View {
        let selected = wentOut == i
        let color = UnoStyle.playerColor(for: i)
        return Button {
            wentOut = i
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(selected ? UnoStyle.textColor(onPlayer: i) : color)
                    .frame(width: 8, height: 8)
                Text(game.players[i].cachedName)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundStyle(selected ? UnoStyle.textColor(onPlayer: i) : Color.primary)
            .background(Capsule().fill(selected ? color : Color.clear))
            .overlay(Capsule().strokeBorder(color, lineWidth: 1.5))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func pointsRow(_ i: Int) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(UnoStyle.playerColor(for: i))
                .frame(width: 10, height: 10)
            Text(game.players[i].cachedName)
            Spacer()
            TextField("0", text: pointsText(for: i))
                .focused($focusedField, equals: i)
#if os(iOS)
                .keyboardType(.numberPad)
#endif
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 70)
                .accessibilityLabel("\(game.players[i].cachedName), points left")
            Button("Count") {
                focusedField = nil
                counting = CountTarget(player: i)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Count \(game.players[i].cachedName)’s cards")
        }
    }

    private var totalBar: some View {
        HStack {
            switch (game.scoring, wentOut) {
            case (_, nil):
                Text("Choose who went out.")
                    .foregroundStyle(.secondary)
            case (.winnerCollects, let out?):
                Text("\(Text(game.players[out].cachedName).bold()) collects")
            case (.pointsAgainst, _):
                Text("Hand total")
            }
            Spacer()
            Text(handTotal.formatted(.number.grouping(.never)))
                .font(.title2.bold())
                .monospacedDigit()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    // Text-backed so a value typed just before Save is never lost to a pending commit.
    private func pointsText(for player: Int) -> Binding<String> {
        Binding(
            get: { points.indices.contains(player) ? String(points[player]) : "" },
            set: { points[player] = Int(String($0.filter { $0.isASCII && $0.isNumber }.prefix(4))) ?? 0 }
        )
    }

    private func load() {
        if let hand = editingHand {
            wentOut = hand.wentOutIndex
            side = hand.side
            points = game.players.indices.map { hand.pointsLeft(for: $0) }
        } else {
            points = Array(repeating: 0, count: game.players.count)
        }
    }

    private func save() {
        guard let wentOut else { return }
        var hand = editingHand ?? UnoHand(playerCount: game.players.count)
        hand.wentOutIndex = wentOut
        hand.side = game.edition.hasSides ? side : .light
        hand.pointsLeft = points
        hand.pointsLeft[wentOut] = 0  // whoever went out holds no cards
        if editingHand == nil {
            game.addHand(hand)
        } else {
            game.replaceHand(hand)
        }
        dismiss()
    }
}

#Preview("New hand") {
    UnoHandView()
        .environmentObject(UnoGame.mock)
}

#Preview("Edit hand") {
    let game = UnoGame.mock
    return UnoHandView(editingHand: game.hands[1])
        .environmentObject(game)
}
