import SwiftUI


struct RubberView: View {
    @State var rubber: Rubber?
    @State private var creatingAuction = false
    @State private var detailContract: Contract?
    
    var body: some View {
        if let rubber {
            ZStack {
                Rule(.vertical)
                VStack(spacing: 4) {
                    RubberHeader()
                    Spacer()
                    OverTheLine()
                    Rule(.horizontal)
                        .frame(height: 2)
                    UnderTheLine()
                    Spacer()
                }
                .environment(\.presentContract, { contract in
                    detailContract = contract
                })
            }
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing)
                {
                    createButton
                        .disabled(rubber.isFinished)
                }
#else
                ToolbarItem
                {
                    createButton
                        .disabled(rubber.isFinished)
                }
#endif
            }
            .sheet(isPresented: $creatingAuction) {
                AuctionView(auction: Auction(dealer: rubber.currentDealer))
                    .navigationTitle("New Auction")
#if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
#endif
                    .interactiveDismissDisabled()
            }
            .sheet(item: $detailContract) { contract in
                AuctionView(auction: contract.auction,
                            honors: contract.honors,
                            tricksTaken: contract.tricksTaken,
                            editingContract: contract)
                .navigationTitle("Edit Contract")
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
            }
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .navigationTitle("")
            .environmentObject(rubber)
        } else {
            Text("Select a rubber")
                .font(.largeTitle)
        }
    }
    
    var createButton: some View {
        Button(action: {
            creatingAuction = true
        }, label: {
            Label("Add", systemImage: "plus")
        })
    }
}

struct RubberView_Previews: PreviewProvider {
    static var previews: some View {
        RubberView(rubber: .mock)
    }
}

struct ScoreList: View {
    var scores: [Score]
    @Environment(\.presentContract) var present

    var body: some View {
        VStack {
            ForEach (scores) { score in
                score
                    .allowsHitTesting(true)
                    .onTapGesture {
                        guard let contract = score.contract else { return }
                        present(contract)
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct OverTheLine: View {
    @EnvironmentObject var rubber: Rubber
    @Namespace var topID
    @Namespace var bottomID
    
    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { scroll in
                ScrollView {
                    ZStack {
                        let scores = rubber.scores.overTheLine()
                        let we = scores.forTeam(.we)
                        let they = scores.forTeam(.they)
                        Spacer()
                            .frame(minHeight: geo.size.height)
                            .id(topID)
                        VStack {
                            Spacer()
                            HStack(alignment: .bottom) {
                                ScoreList(scores: we.reversed())
                                ScoreList(scores: they.reversed())
                            }
                        }
                        .id(bottomID)
                    }
                }
                .onAppear {
                    scroll.scrollTo(bottomID, anchor: .bottom)
                }
            }
        }
    }
}

struct UnderTheLine: View {
    @EnvironmentObject var rubber: Rubber
    var body: some View {
        ScrollView {
            ForEach(rubber.games) { game in
                GameView(game: game)
            }
        }
    }
}

struct GameView: View {
    @EnvironmentObject var rubber: Rubber
    var game: Game

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .top) {
                let scores = rubber.scoresForGame(game).underTheLine()
                ScoreList(scores: scores.forTeam(.we))
                ScoreList(scores: scores.forTeam(.they))
            }
            switch game {
            case .complete:
                Rule(.horizontal)
                    .frame(height: 2)
            case .rubber:
                Rule(.horizontal)
                    .frame(height: 4)
                Rule(.horizontal)
                    .frame(height: 2)
            default:
                EmptyView()
            }
        }
    }
}
