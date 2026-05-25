import SwiftUI

struct Phase10GameView: View {
    let game: Phase10Game?
    @State private var creatingHand = false
    @State private var editingHand: Phase10Hand?

    var body: some View {
        if let game {
            scoreSheet(game: game)
                .environment(\.phase10PlayerColumnWidth, Phase10Game.playerColumnWidth)
                .environment(\.presentPhase10Hand) { hand in editingHand = hand }
                .environmentObject(game)
                .ignoresSafeArea(.keyboard)
                .toolbar {
#if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        addButton.disabled(game.isFinished)
                    }
#else
                    ToolbarItem {
                        addButton.disabled(game.isFinished)
                    }
#endif
                }
                .sheet(isPresented: $creatingHand) {
                    Phase10HandView()
                        .environmentObject(game)
                }
                .sheet(item: $editingHand) { hand in
                    Phase10HandView(editingHand: hand)
                        .environmentObject(game)
                }
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
                .navigationTitle("")
        } else {
            Text("Select a game")
                .font(.largeTitle)
        }
    }

    @ViewBuilder
    private func scoreSheet(game: Phase10Game) -> some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                Section {
                    ForEach(game.hands.indices.reversed(), id: \.self) { i in
                        Phase10HandRow(hand: game.hands[i], handIndex: i)
                        Divider()
                    }
                } header: {
                    VStack(spacing: 0) {
                        Phase10Header()
                        Divider()
                    }
                    .background(.background)
                }
            }
        }
        .defaultScrollAnchor(.top)
        .scrollBounceBehavior(.basedOnSize)
    }

    private var addButton: some View {
        Button {
            creatingHand = true
        } label: {
            Label("Add Hand", systemImage: "plus")
        }
    }
}

struct Phase10GameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Phase10GameView(game: .mock)
        }
    }
}
