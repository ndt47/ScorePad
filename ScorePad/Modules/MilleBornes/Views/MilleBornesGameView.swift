import SwiftUI

struct MilleBornesGameView: View {
    let game: MilleBornesGame?
    @State private var creatingHand = false
    @State private var editingHand: MilleBornesHand?

    var body: some View {
        if let game {
            ZStack {
                Rule(.vertical)
                VStack(spacing: 4) {
                    MilleBornesHeader()
                    Spacer()
                    handsScrollView(game: game)
                    Spacer()
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
                    MilleBornesHandRow(hand: hand, isTwoPlayerGame: game.isTwoPlayerGame)
                    Rule(.horizontal)
                        .frame(height: 2)
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
