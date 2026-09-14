import SwiftUI

/// Records or edits one hand: who went out, the side a Flip hand ended on, and the points left
/// in every other hand. Each "points left" field has a Count button that opens the Card Pad.
struct UnoHandView: View {
    @EnvironmentObject var game: UnoGame
    @Environment(\.dismiss) private var dismiss

    var editingHand: UnoHand?

    @State private var wentOut: Int?
    @State private var side: UnoSide = .light
    /// Points left per player; nil until entered, so a forgotten row can't save as 0.
    @State private var points: [Int?] = []
    /// Cards counted with the Card Pad, per player, and the side they were counted on.
    @State private var counts: [Int: Count] = [:]
    @State private var counting: CountTarget?
    @State private var loaded = false
    @FocusState private var focusedField: Int?

    private struct Count {
        let side: UnoSide
        let cards: [UnoCard]
    }

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
        opponents.reduce(0) { $0 + (points(for: $1) ?? 0) }
    }

    private func points(for player: Int) -> Int? {
        points.indices.contains(player) ? points[player] : nil
    }

    private func name(_ player: Int) -> String {
        game.players[player].cachedName
    }

    /// A count made on the other side no longer matches the hand: Flip cards are worth
    /// different points on each face.
    private func isStale(_ player: Int) -> Bool {
        guard game.edition.hasSides, let count = counts[player] else { return false }
        return count.side != side
    }

    /// Why the hand can't be saved yet, or nil.
    private var problem: String? {
        guard wentOut != nil else { return String(localized: "Choose who went out.") }
        for player in opponents {
            guard let value = points(for: player) else {
                return String(localized: "Enter the points left in \(name(player))’s hand.")
            }
            if isStale(player) {
                let counted = counts[player]?.side.name.lowercased() ?? ""
                return String(localized: "Count \(name(player))’s cards again: they were counted on the \(counted) side.")
            }
            if game.edition == .flip && value == 0 {
                return String(localized: "\(name(player)) can’t have 0 points: Uno Flip has no zero cards.")
            }
        }
        return nil
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
                    if loaded {
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
            .frame(minWidth: 460, minHeight: 560)
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
                        .disabled(problem != nil)
                }
            }
            .sheet(item: $counting) { target in
                let countSide = game.edition.hasSides ? side : .light
                UnoCardPad(playerName: name(target.player),
                           edition: game.edition,
                           side: countSide,
                           initialCards: counts[target.player].flatMap { $0.side == countSide ? $0.cards : nil } ?? []) { cards in
                    counts[target.player] = Count(side: countSide, cards: cards)
                    points[target.player] = cards.reduce(0) { $0 + $1.points }
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

    private func pointsRow(_ i: Int) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(UnoStyle.playerColor(for: i))
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(name(i))
                if isStale(i), let counted = counts[i]?.side {
                    Label("Counted on the \(counted.name.lowercased()) side", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if let count = counts[i] {
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
            Button(isStale(i) ? "Recount" : "Count") {
                focusedField = nil
                counting = CountTarget(player: i)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Count \(name(i))’s cards")
        }
    }

    private var totalBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                switch (game.scoring, wentOut) {
                case (_, nil):
                    Text("Hand total")
                case (.winnerCollects, let out?):
                    Text("\(Text(name(out)).bold()) collects")
                case (.pointsAgainst, _):
                    Text("Hand total")
                }
                Spacer()
                Text(handTotal.formatted(.number.grouping(.never)))
                    .font(.title2.bold())
                    .monospacedDigit()
            }
            if let problem {
                Text(problem)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    // Text-backed so a value typed just before Save is never lost to a pending commit. Typing
    // replaces any Card Pad count for that player, since the number no longer comes from it.
    private func pointsText(for player: Int) -> Binding<String> {
        Binding(
            get: { points(for: player).map(String.init) ?? "" },
            set: { text in
                let digits = String(text.filter { $0.isASCII && $0.isNumber }.prefix(4))
                let value = digits.isEmpty ? nil : Int(digits)
                guard value != points[player] else { return }
                points[player] = value
                counts[player] = nil
            }
        )
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let hand = editingHand {
            wentOut = hand.wentOutIndex
            side = hand.side
            points = game.players.indices.map { $0 == hand.wentOutIndex ? nil : hand.pointsLeft(for: $0) }
        } else {
            points = Array(repeating: nil, count: game.players.count)
        }
    }

    private func save() {
        guard problem == nil, let wentOut else { return }
        var hand = editingHand ?? UnoHand(playerCount: game.players.count)
        hand.wentOutIndex = wentOut
        hand.side = game.edition.hasSides ? side : .light
        hand.pointsLeft = points.map { $0 ?? 0 }
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
