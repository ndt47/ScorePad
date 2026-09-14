import SwiftUI

/// The game screen. Winner-collects games show a race toward the target plus a hand log;
/// points-against games show a Phase 10 style ledger, since every player scores every hand.
struct UnoGameView: View {
    let game: UnoGame?
    @State private var creatingHand = false
    @State private var editingHand: UnoHand?

    var body: some View {
        if let game {
            Group {
                switch game.scoring {
                case .winnerCollects:
                    UnoRaceSheet { editingHand = $0 }
                case .pointsAgainst:
                    UnoLedgerSheet { editingHand = $0 }
                }
            }
            .environmentObject(game)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        creatingHand = true
                    } label: {
                        Label("Add Hand", systemImage: "plus")
                    }
                    .disabled(game.isFinished)
                }
            }
            .sheet(isPresented: $creatingHand) {
                UnoHandView()
                    .environmentObject(game)
            }
            .sheet(item: $editingHand) { hand in
                UnoHandView(editingHand: hand)
                    .environmentObject(game)
            }
            .navigationTitle("\(game.edition.name) · to \(game.targetScore.formatted(.number.grouping(.never)))")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        } else {
            Text("Select a game")
                .font(.largeTitle)
        }
    }
}

// MARK: - Winner collects: race + hand log

struct UnoRaceSheet: View {
    @EnvironmentObject var game: UnoGame
    var onSelectHand: (UnoHand) -> Void

    private var standings: [Int] {
        game.players.indices.sorted { game.cumulativeScore(for: $0) > game.cumulativeScore(for: $1) }
    }

    var body: some View {
        List {
            Section {
                ForEach(standings, id: \.self) { i in
                    raceRow(i)
                }
            } footer: {
                if game.isFinished {
                    Text("Game over.")
                }
            }

            Section("Hands") {
                if game.hands.isEmpty {
                    Text("No hands yet. Tap + to record the first one.")
                        .foregroundStyle(.secondary)
                }
                ForEach(game.hands.indices.reversed(), id: \.self) { n in
                    Button {
                        onSelectHand(game.hands[n])
                    } label: {
                        handRow(game.hands[n], number: n + 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func raceRow(_ i: Int) -> some View {
        let score = game.cumulativeScore(for: i)
        let color = UnoStyle.playerColor(for: i)
        return HStack(spacing: 10) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(game.players[i].cachedName)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                if i == game.currentDealerIndex && !game.isFinished {
                    UnoDealerBadge(playerIndex: i)
                }
                if game.isWinner(i) {
                    WinnerBadge(showLabel: false)
                }
            }
            .frame(width: 120, alignment: .leading)

            UnoProgressBar(fraction: Double(score) / Double(max(game.targetScore, 1)), color: color)
                .frame(height: 14)

            Text(score.formatted(.number.grouping(.never)))
                .fontWeight(.bold)
                .monospacedDigit()
                .frame(minWidth: 40, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private func handRow(_ hand: UnoHand, number: Int) -> some View {
        let out = hand.wentOutIndex
        let breakdown = game.players.indices
            .filter { $0 != out }
            .map { "\(game.players[$0].cachedName) \(hand.pointsLeft(for: $0))" }
            .joined(separator: " · ")
        return HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 22, alignment: .leading)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Circle().fill(UnoStyle.playerColor(for: out)).frame(width: 8, height: 8)
                    Text("\(game.players.indices.contains(out) ? game.players[out].cachedName : "?") went out")
                        .fontWeight(.semibold)
                    if game.edition.hasSides {
                        UnoSideMarker(side: hand.side)
                    }
                }
                Text(breakdown)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("+\(hand.handValue)")
                .fontWeight(.bold)
                .monospacedDigit()
        }
        .contentShape(Rectangle())
    }
}

/// A bar filling toward the target, with a dashed line marking the target itself.
struct UnoProgressBar: View {
    let fraction: Double
    let color: Color
    var showsTarget = true

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geometry.size.width * min(max(fraction, 0), 1))
            }
            .overlay(alignment: .trailing) {
                if showsTarget {
                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [3, 2]))
                        .foregroundStyle(.secondary)
                        .frame(width: 1)
                        .padding(.vertical, -3)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// The "D" capsule marking the current dealer.
struct UnoDealerBadge: View {
    let playerIndex: Int

    var body: some View {
        Text("D")
            .font(.caption2.bold())
            .foregroundStyle(UnoStyle.textColor(onPlayer: playerIndex))
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(Capsule().fill(UnoStyle.playerColor(for: playerIndex)))
            .accessibilityLabel("Dealer")
    }
}

// MARK: - Points against: ledger grid

struct UnoLedgerSheet: View {
    @EnvironmentObject var game: UnoGame
    var onSelectHand: (UnoHand) -> Void

    private let labelWidth: CGFloat = 44
    private let columnWidth: CGFloat = 84

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                Section {
                    if game.hands.isEmpty {
                        Text("No hands yet. Tap + to record the first one.")
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    ForEach(game.hands.indices.reversed(), id: \.self) { n in
                        Button {
                            onSelectHand(game.hands[n])
                        } label: {
                            handRow(game.hands[n], number: n + 1)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                } header: {
                    VStack(spacing: 0) {
                        header
                        Divider()
                    }
                    .background(.background)
                }
            }
        }
        .defaultScrollAnchor(.topLeading)
        .scrollBounceBehavior(.basedOnSize)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 3) {
                Rectangle().fill(Color.primary).frame(height: 4)
                Text("Hand")
                    .font(.subheadline.bold())
            }
            .frame(width: labelWidth)

            ForEach(game.players.indices, id: \.self) { i in
                Divider()
                headerColumn(i)
            }
        }
        .padding(.vertical, 8)
    }

    private func headerColumn(_ i: Int) -> some View {
        let color = UnoStyle.playerColor(for: i)
        let score = game.cumulativeScore(for: i)
        return VStack(spacing: 3) {
            Rectangle().fill(color).frame(height: 4)
            Text(game.players[i].cachedName)
                .font(.subheadline.bold())
                .lineLimit(1)
                .padding(.horizontal, 6)
            // Reserve the badge's space in every column so all columns stay the same height.
            ZStack {
                UnoDealerBadge(playerIndex: i)
                    .opacity(i == game.currentDealerIndex && !game.isFinished ? 1 : 0)
                    .accessibilityHidden(!(i == game.currentDealerIndex && !game.isFinished))
                if game.isWinner(i) {
                    WinnerBadge()
                }
            }
            Text(score.formatted(.number.grouping(.never)))
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            UnoProgressBar(fraction: Double(score) / Double(max(game.targetScore, 1)), color: color, showsTarget: false)
                .frame(height: 4)
                .padding(.horizontal, 8)
        }
        .frame(width: columnWidth)
    }

    private func handRow(_ hand: UnoHand, number: Int) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 2) {
                Text("\(number)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if game.edition.hasSides {
                    UnoSideMarker(side: hand.side)
                }
            }
            .frame(width: labelWidth)

            ForEach(game.players.indices, id: \.self) { i in
                Divider()
                Group {
                    if i == hand.wentOutIndex {
                        Text("Out")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(UnoStyle.textColor(onPlayer: i))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(UnoStyle.playerColor(for: i)))
                    } else {
                        Text(hand.pointsLeft(for: i).formatted(.number.grouping(.never)))
                            .font(.subheadline)
                            .monospacedDigit()
                    }
                }
                .frame(width: columnWidth)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview("Winner collects") {
    NavigationStack {
        UnoGameView(game: .mock)
    }
}

#Preview("Points against") {
    let game = UnoGame.mock
    game.scoring = .pointsAgainst
    return NavigationStack {
        UnoGameView(game: game)
    }
}
