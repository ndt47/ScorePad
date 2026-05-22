import SwiftUI

struct MilleBornesGameView: View {
    let game: MilleBornesGame?
    @State private var creatingHand = false
    @State private var editingHand: MilleBornesHand?

    var body: some View {
        if let game {
            ZStack {
                Rectangle()
                    .fill(.separator)
                    .frame(width: 0.5)
                VStack(spacing: 0) {
                    MilleBornesHeader()
                    Divider()
                    handsScrollView(game: game)
                }
                .environment(\.presentHand) { hand in
                    editingHand = hand
                }
            }
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                        .disabled(game.isFinished)
                }
#else
                ToolbarItem {
                    addButton
                        .disabled(game.isFinished)
                }
#endif
            }
            .sheet(isPresented: $creatingHand) {
                MilleBornesHandView()
                    .navigationTitle("New Hand")
#if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
#endif
            }
            .sheet(item: $editingHand) { hand in
                MilleBornesHandView(editingHand: hand)
                    .navigationTitle("Edit Hand")
#if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
#endif
            }
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .navigationTitle("")
            .environmentObject(game)
            .environment(\.isTwoPlayerGame, game.isTwoPlayerGame)
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

    @ViewBuilder
    private func handsScrollView(game: MilleBornesGame) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(game.hands) { hand in
                    MilleBornesHandRow(hand: hand)
                    Divider()
                }
            }
        }
    }
}

struct MilleBornesGameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MilleBornesGameView(game: .mock)
        }
    }
}
