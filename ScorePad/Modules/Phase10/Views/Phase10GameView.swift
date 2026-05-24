import SwiftUI

struct Phase10GameView: View {
    let game: Phase10Game?
    @State private var creatingHand = false
    @State private var editingHand: Phase10Hand?

    var body: some View {
        if let game {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView([.vertical, .horizontal]) {
                    VStack {
                        Phase10Header()
                        Divider()
                        ForEach(game.hands.indices, id: \.self) { i in
                            Phase10HandRow(hand: game.hands[i], handIndex: i)
                            Divider()
                        }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .environment(\.phase10PlayerColumnWidth, Phase10Game.playerColumnWidth)
            .environment(\.presentPhase10Hand) { hand in
                editingHand = hand
            }
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
