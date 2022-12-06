//
//  NewContract.swift
import SwiftUI

extension Honors {
    var label: String {
        switch self {
        case .none: return "None"
        case .declarer100, .declarer150: return "Declarer\u{00a0}\(points)"
        case .defender100, .defender150: return "Defender\u{00a0}\(points)"
        }
    }
}

struct AuctionView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var rubber: Rubber
    @StateObject var auction: Auction
    @Environment(\.dismiss) var dismiss

    @State var honors: Honors = .none
    @State var tricksTaken: Int = 0
    @State var editingContract: Contract?

    enum Action {
        case save
        case cancel
        case missdeal
        case delete
        
        var label: String {
            switch self {
            case .save: return "Save"
            case .cancel: return "Cancel"
            case .missdeal: return "Miss Deal"
            case .delete: return "Delete"
            }
        }
        
        var systemImage: String {
            switch self {
            case .save: return "pencil"
            case .cancel: return "pencil.slash"
            case .missdeal: return "exclamationmark.questionmark"
            case .delete: return "trash.fill"
            }
        }
    }
        
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                RubberHeader()
                Rule(.horizontal)
                    .foregroundColor(.black)
                    .frame(height: 2)
                if !auction.closed {
                    BiddingView()
                }
                
                HStack {
                    Text("Calls")
                        .font(.title3)
                        .foregroundColor(.gray)
                    Spacer()
                    Button {
                        auction.undoLast()
                    } label: {
                        Label("Undo Last", systemImage: "arrow.uturn.backward.circle")
                    }
                    .disabled(!auction.canRemoveLast)
                }
                Rule(.horizontal)
                    .frame(height: 2)
                    .foregroundColor(.gray)
                List {
                    if !auction.closed {
                        CallView(call: .init(position: auction.bidder, call: .pending))
                    }
                    ForEach(auction.calls.reversed()) { call in
                        CallView(call: call)
                    }
                }
                    .listStyle(.plain)
                if auction.closed && !auction.isPassHand {
                    TricksView(tricksTaken: $tricksTaken,
                        honors: $honors
                    )
                }
            }
            .navigationTitle(editingContract != nil ? "Edit Contract" : "New Auction")
            .navigationBarTitleDisplayMode(.inline)
            .rubber(rubber)
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if editingContract != nil {
                            update()
                        } else {
                            save()
                        }
                    }, label: {
                        Label(Action.save.label, systemImage: Action.save.systemImage)
                    })
                    .labelStyle(.titleOnly)
                    .disabled(!auction.closed)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // TODO: Implement cancel, prompt for misdeal or delete depending on auction state
                        cancel()
                    }, label: {
                        Label(Action.cancel.label, systemImage: Action.cancel.systemImage)
                    })
                    .labelStyle(.titleOnly)
                }
            }
        }
        .environmentObject(auction)
    }
    
    func update() {
        guard let existing = editingContract else { return }
        if let contract = Contract(auction: auction, honors: honors, tricksTaken: tricksTaken, vulnerable: existing.vulnerable) {
            rubber.replaceContract(existing, with: .contract(auction, contract))
        } else {
            rubber.replaceContract(existing, with: .pass(auction))
        }
        dismiss()
    }
    
    func save() {
        let vulnerable = auction.declarer != nil ? rubber.isVulnerable(auction.declarer!.team) : false
        if let contract = Contract(auction: auction, honors: honors, tricksTaken: tricksTaken, vulnerable: vulnerable) {
            rubber.addAuctionResult(.contract(auction, contract))
        } else {
            rubber.addAuctionResult(.pass(auction))
        }
        Task {
            do {
                try await store.save()
            } catch {
                print(String(describing: error))
            }
        }
        dismiss()
    }
    
    func cancel() {
        dismiss()
    }
}


struct TricksView: View {
    @EnvironmentObject var rubber: Rubber
    @EnvironmentObject var auction: Auction
    @Binding var tricksTaken: Int
    @Binding var honors: Honors

    var result: Int {
        guard let level = auction.level else { return 0 }
        return tricksTaken - 6 - level
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("Tricks")
                    .font(.title3)
                    .foregroundColor(.gray)
                Spacer()
                AuctionSummaryView(result: result)
            }
            Rule(.horizontal)
                .frame(height: 2.0)
                .foregroundColor(.gray)
            HStack(alignment: .firstTextBaseline) {
                Picker(selection: $honors) {
                    ForEach(Honors.allCases, id: \.self) { honor in
                        Text(honor.label)
                    }
                }
                label: {
                    Text("Honors")
                }
                .pickerStyle(.menu)
                Spacer()
                Result(result, .long)
            }
            Picker(selection: $tricksTaken) {
                ForEach(Array(0...13), id: \.self) { value in
                    Text(String(value))
                }
            }
            label: {
                EmptyView()
            }
            .pickerStyle(.segmented)
        }
    }
}

struct AuctionSummaryView: View {
    @EnvironmentObject var rubber: Rubber
    @EnvironmentObject var auction: Auction
    var result: Int

    var player: String {
        guard let position = auction.declarer else { return "" }
        guard let player = rubber.player(at: position) else { return position.label }
        return player
    }
    
    var body: some View {
        guard let level = auction.level, let suit = auction.suit else { return EmptyView ().eraseToAnyView()
        }
        return HStack(alignment: .firstTextBaseline) {
            Text("\(player) is playing")
            BidView(.bid(level, suit))
            if auction.redoubled {
                Text("REDOUBLED")
                    .foregroundColor(.gray)
                    .font(.caption)

            } else if auction.doubled {
                Text("DOUBLED")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }.eraseToAnyView()
    }
}




struct Seats: View {
    @EnvironmentObject var rubber: Rubber
    @EnvironmentObject var auction: Auction

    func lastCall(for position: Position) -> Call.Call? {
        auction.calls.last { $0.position == position }?.call
    }
    
    var body: some View {
        VStack(alignment: .center) {
            HStack(alignment: .firstTextBaseline) {
                Seat(.north)
                if let call = lastCall(for: .north) {
                    BidView(call)
                } else {
                    EmptyView()
                }
            }
            HStack(alignment: .firstTextBaseline) {
                HStack(alignment: .firstTextBaseline) {
                    Seat(.west)
                    if let call = lastCall(for: .west) {
                        BidView(call)
                    } else {
                        EmptyView()
                    }
                }
                Spacer()
                HStack(alignment: .firstTextBaseline) {
                    if let call = lastCall(for: .east) {
                        BidView(call)
                    } else {
                        EmptyView()
                    }
                    Seat(.east)
                }
            }
            HStack(alignment: .firstTextBaseline) {
                Seat(.south)
                if let call = lastCall(for: .south) {
                    BidView(call)
                } else {
                    EmptyView()
                }
            }
        }
        .padding()
    }
}

struct Seat: View {
    @EnvironmentObject var rubber: Rubber
    var position: Position

    init(_ position: Position) {
        self.position = position
    }
    
    enum Stat {
        case dealer, vulnerable, none
        
        var label: String {
            switch self {
            case .dealer: return "DEALER"
            case .vulnerable: return "VULNERABLE"
            case .none: return ""
            }
        }
        
        var color: Color {
            switch self {
            case .dealer: return .gray
            case .vulnerable: return .red
            case .none: return .clear
            }
        }
    }
    
    var stats: [Stat] {
        var result = [Stat]()
        if rubber.currentDealer == position { result.append(.dealer) }
        if rubber.isVulnerable(position.team) { result.append(.vulnerable) }
        
        for _ in result.count...2 {
            result.append(.none)
        }
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            PlayerView(position: position)
            ForEach(stats, id: \.self) { stat in
                Text(stat.label)
                    .font(.caption)
                    .foregroundColor(stat.color)
            }
        }
    }
}

struct PlayerView: View {
    @EnvironmentObject var rubber: Rubber
    var position: Position
    
    var body: some View {
        let player = rubber.player(at: position) ?? position.label
        HStack(alignment: .firstTextBaseline) {
            Text(player)
                .allowsTightening(true)
                .fontWeight(.light)

            if !rubber.isFinished &&
                rubber.currentDealer == position {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
    }
}

struct AuctionView_Previews: PreviewProvider {
    static var previews: some View {
        AuctionView(auction: .mock)
            .environmentObject(Rubber.mock)
    }
}
