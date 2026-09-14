import SwiftUI

/// Records or edits one hand: who went out, the side a Flip hand ended on, and the points left
/// in every other hand. Each "points left" field has a Count button that opens the Card Pad.
/// The rules about what can be saved live in `UnoHandEntry`.
struct UnoHandView: View {
    @EnvironmentObject var game: UnoGame
    @Environment(\.dismiss) private var dismiss

    var editingHand: UnoHand?

    @State private var entry: UnoHandEntry?
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

    private func name(_ player: Int) -> String {
        game.players[player].cachedName
    }

    var body: some View {
        NavigationStack {
            Form {
                if let entry {
                    Section("Went Out") {
                        UnoFlowLayout(spacing: 8) {
                            ForEach(game.players.indices, id: \.self) { i in
                                playerChip(i, selected: entry.wentOut == i)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    if game.edition.hasSides {
                        Section("Hand Ended On") {
                            Picker("Hand ended on", selection: binding(\.side)) {
                                Label("Light Side", systemImage: "sun.max.fill").tag(UnoSide.light)
                                Label("Dark Side", systemImage: "moon.fill").tag(UnoSide.dark)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                    }

                    Section {
                        ForEach(entry.opponents, id: \.self) { i in
                            pointsRow(i, entry: entry)
                        }
                    } header: {
                        Text("Points Left in Hand")
                    } footer: {
                        Text("If the last card played was a draw card, the next player draws those cards before anyone counts.")
                    }
                }
            }
#if os(macOS)
            .formStyle(.grouped)
            .frame(minWidth: 460, minHeight: 560)
#endif
            .safeAreaInset(edge: .bottom) {
                if let entry { totalBar(entry) }
            }
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
                        .disabled(entry?.problem != nil)
                }
            }
            .sheet(item: $counting) { target in
                if let entry {
                    UnoCardPad(playerName: name(target.player),
                               edition: game.edition,
                               side: entry.countingSide,
                               initialCards: entry.cardsToRecount(for: target.player)) { cards in
                        self.entry?.setCounted(cards, for: target.player)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .onAppear(perform: load)
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<UnoHandEntry, Value>) -> Binding<Value> {
        Binding(
            get: { entry![keyPath: keyPath] },
            set: { entry?[keyPath: keyPath] = $0 }
        )
    }

    private func playerChip(_ i: Int, selected: Bool) -> some View {
        let color = UnoStyle.playerColor(for: i)
        return Button {
            entry?.wentOut = i
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(selected ? UnoStyle.textColor(onPlayer: i) : color)
                    .frame(width: 8, height: 8)
                Text(name(i))
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

    private func pointsRow(_ i: Int, entry: UnoHandEntry) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(UnoStyle.playerColor(for: i))
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(name(i))
                if entry.isStale(i), let counted = entry.counts[i]?.side {
                    Label("Counted on the \(counted.name.lowercased()) side", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if let count = entry.counts[i] {
                    Text("\(count.cards.count) card(s) counted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            TextField("–", text: pointsText(for: i))
                .focused($focusedField, equals: i)
#if os(iOS)
                .keyboardType(.numberPad)
#endif
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 70)
                .accessibilityLabel("\(name(i)), points left")
            Button(entry.isStale(i) ? "Recount" : "Count") {
                focusedField = nil
                counting = CountTarget(player: i)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Count \(name(i))’s cards")
        }
    }

    private func totalBar(_ entry: UnoHandEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if game.scoring == .winnerCollects, let out = entry.wentOut {
                    Text("\(Text(name(out)).bold()) collects")
                } else {
                    Text("Hand total")
                }
                Spacer()
                Text(entry.total.formatted(.number.grouping(.never)))
                    .font(.title2.bold())
                    .monospacedDigit()
            }
            if let problem = entry.problem {
                Text(problem)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    // Text-backed so a value typed just before Save is never lost to a pending commit.
    private func pointsText(for player: Int) -> Binding<String> {
        Binding(
            get: { entry?.points(for: player).map(String.init) ?? "" },
            set: { text in
                let digits = String(text.filter { $0.isASCII && $0.isNumber }.prefix(4))
                entry?.setTyped(digits.isEmpty ? nil : Int(digits), for: player)
            }
        )
    }

    private func load() {
        guard entry == nil else { return }
        let names = game.players.map(\.cachedName)
        if let editingHand {
            entry = UnoHandEntry(editing: editingHand, edition: game.edition, playerNames: names)
        } else {
            entry = UnoHandEntry(edition: game.edition, playerNames: names)
        }
    }

    private func save() {
        guard let hand = entry?.makeHand(updating: editingHand) else { return }
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
