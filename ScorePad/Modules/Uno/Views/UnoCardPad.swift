import SwiftUI

/// Counts one player's hand card by card: tap each card as they lay it down, and Done writes
/// the total back. The keys come from the edition's card-value table for the side the hand
/// ended on, so the pad always shows exactly the cards that can be in that hand.
struct UnoCardPad: View {
    let playerName: String
    let edition: UnoEdition
    let side: UnoSide
    var onDone: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var tally: [UnoCard] = []

    private var cards: [UnoCard] { edition.cards(side: side) }
    private var numberCards: [UnoCard] { cards.filter(\.isNumber) }
    private var actionCards: [UnoCard] { cards.filter { !$0.isNumber } }
    private var total: Int { tally.reduce(0) { $0 + $1.points } }
    private var isDarkSide: Bool { edition.hasSides && side == .dark }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Total")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(total.formatted(.number.grouping(.never)))
                            .font(.largeTitle.bold())
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.snappy, value: total)
                    }

                    tray

                    padSection("Number Cards") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                            ForEach(numberCards) { card in key(for: card) }
                        }
                    }

                    padSection(edition.hasSides ? "\(side.name) Side Action Cards" : "Action Cards") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(actionCards) { card in key(for: card) }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("\(playerName)’s Cards")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone(total)
                        dismiss()
                    }
                }
            }
        }
        // The dark side of a Flip deck is literally dark; the pad follows it.
        .preferredColorScheme(isDarkSide ? .dark : nil)
    }

    private var tray: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("In Hand (\(tally.count))")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if !tally.isEmpty {
                    Button("Clear") { tally.removeAll() }
                        .font(.footnote)
                }
            }
            Group {
                if tally.isEmpty {
                    Text("Tap each card \(playerName) is holding. Tap a card here to remove it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    UnoFlowLayout(spacing: 6) {
                        ForEach(Array(tally.enumerated()), id: \.offset) { offset, card in
                            Button {
                                tally.remove(at: offset)
                            } label: {
                                Text(card.symbol)
                                    .font(.caption.bold())
                                    .foregroundStyle(UnoStyle.textColor(on: card.color))
                                    .padding(.horizontal, 8)
                                    .frame(minWidth: 30, minHeight: 24)
                                    .background(UnoStyle.color(for: card.color), in: RoundedRectangle(cornerRadius: 5))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove \(card.name)")
                        }
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func padSection(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func key(for card: UnoCard) -> some View {
        Button {
            tally.append(card)
        } label: {
            VStack(spacing: 2) {
                Text(card.symbol)
                    .font(card.isNumber ? .title3.weight(.semibold) : .headline)
                if !card.isNumber {
                    Text("\(card.name) · \(card.points)")
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .foregroundStyle(UnoStyle.textColor(on: card.color))
            .frame(maxWidth: .infinity, minHeight: card.isNumber ? 44 : 54)
            .padding(.horizontal, 4)
            .background(UnoStyle.color(for: card.color), in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                // Wild cards carry all four colours, which also sets them apart on the dark side.
                if card.color == .wild {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(AngularGradient(colors: UnoStyle.wildRing, center: .center), lineWidth: 2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add \(card.name), \(card.points) points")
    }
}

#Preview("Classic") {
    UnoCardPad(playerName: "Bob", edition: .classic, side: .light) { _ in }
}

#Preview("Flip, dark side") {
    UnoCardPad(playerName: "Cara", edition: .flip, side: .dark) { _ in }
}
