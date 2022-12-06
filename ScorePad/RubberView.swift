import SwiftUI


struct RubberView: View {
    @StateObject var rubber: Rubber
    @State private var creatingAuction = false
    @State private var detailContract: Contract?
    
    var body: some View {
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    creatingAuction = true
                }, label: {
                    Label("Add", systemImage: "plus")
                })
                .disabled(rubber.isFinished)
            }
        }
        .sheet(isPresented: $creatingAuction) {
            AuctionView(auction: Auction(dealer: rubber.currentDealer))
                .navigationTitle("New Auction")
                .navigationBarTitleDisplayMode(.inline)
        
        }
        .sheet(item: $detailContract) { contract in
            AuctionView(auction: contract.auction,
                        honors: contract.honors,
                        tricksTaken: contract.tricksTaken,
                        editingContract: contract)
            .navigationTitle("Edit Contract")
            .navigationBarTitleDisplayMode(.inline)
        }
        .environmentObject(rubber)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
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
                    let scores = rubber.scores.overTheLine()
                    let we = scores.forTeam(.we)
                    let they = scores.forTeam(.they)
                    Spacer()
                        .frame(minHeight: geo.size.height)
                        .id(topID)
                    HStack(alignment: .bottom) {
                        ScoreList(scores: we.reversed())
                        ScoreList(scores: they.reversed())
                    }
                    .id(bottomID)
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
