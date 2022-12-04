import SwiftUI


struct RubberView: View {
    @State private var creatingAuction = false
    @StateObject var rubber: Rubber
    @State private var pushedContract: Contract?
    
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
        }
        .rubber(rubber)
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
            AuctionView(rubber: rubber, auction: Auction(dealer: rubber.currentDealer))
        }
        .environment(\.presentContract, { contract in
        })
    }
}

struct OverTheLine: View {
    @EnvironmentObject var rubber: Rubber
    var body: some View {
        HStack(alignment: .bottom) {
            let scores = rubber.scores.overTheLine()
            ScoreList(scores: scores.forTeam(.we).reversed())
            ScoreList(scores: scores.forTeam(.they).reversed())
        }
    }
}

struct RubberView_Previews: PreviewProvider {
    static var previews: some View {
        RubberView(rubber: .mock)
    }
}

struct Rule: View {
    enum Orientation {
        case horizontal
        case vertical
    }
    let orientation: Orientation
    
    init(_ orientation: Orientation) {
        self.orientation = orientation
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            Path() { path in
                var origin = CGPoint(x: 0, y: 0)
                var end = CGPoint(x: size.width, y: size.height)
                switch orientation {
                case .horizontal:
                    origin.y = floor(size.height / 2.0 - 1.0)
                    end.x = size.width
                    end.y = floor(size.height / 2.0 - 1.0)
                case .vertical:
                    origin.x = floor(size.width / 2.0 - 1.0)
                    end.x = origin.x
                    end.y = size.height
                }

                path.move(to: origin)
                path.addLine(to: end)
            }
            .strokedPath(StrokeStyle(lineWidth:2.0))
        }
    }
}


extension Rubber {
    static var mock: Rubber {
        Rubber(
            players: [
                Player(name: "Caty", position: .west),
                Player(name: "Nathan", position: .south),
                Player(name: "Sharon", position: .east),
                Player(name: "Larisa", position: .north)
            ],
            history: [
                .missDeal(.north),
                .contract(Auction(), Contract(level: 3, suit: .hearts, declarer: .north, tricksTaken: 11)), // made
                .contract(Auction(),Contract(level: 2, suit: .hearts, declarer: .west, tricksTaken: 9)), // made
                .contract(Auction(),Contract(level: 2, suit: .spades, declarer: .east, tricksTaken: 7)), // under
                .pass(Auction()),
                .contract(Auction(),Contract(level: 3, suit: .hearts, declarer: .south, tricksTaken: 8)), // under
                .contract(Auction(),Contract(level: 3, suit: .clubs, declarer: .west, tricksTaken: 8)), // under
                .contract(Auction(),Contract(level: 2, suit: .hearts, declarer: .west, tricksTaken: 6)), // under
                .pass(Auction()),
                .contract(Auction(),Contract(level: 2, suit: .hearts, declarer: .east, tricksTaken: 9)), // made, game
                .contract(Auction(),Contract(level: 2, suit: .notrump, declarer: .east, tricksTaken: 8, vulnerable: true)), // made
                .contract(Auction(),Contract(level: 3, suit: .spades, declarer: .north, tricksTaken: 9)), // made
//                .contract(Auction(),Contract(level: 1, suit: .notrump, declarer: .east, tricksTaken: 9, vulnerable: true)), // made, game
            ]
        )
    }
}

struct ScoreList: View {
    var scores: [Score]
    var body: some View {
        VStack {
            ForEach (scores) { score in
                score
                    .onTapGesture {
                        // TODO: Show contract detail
                        print("Show \(String(describing: score.contract))")
                    }
            }
        }.frame(maxWidth: .infinity)
    }
}

struct UnderTheLine: View {
    @EnvironmentObject var rubber: Rubber
    var body: some View {
        ForEach(rubber.games) { game in
            GameView(game: game)
        }
    }
}

struct GameView: View {
    var game: Game
    @EnvironmentObject var rubber: Rubber

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
