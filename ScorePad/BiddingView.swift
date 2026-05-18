//
//  BiddingView.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/2/22.
//

import SwiftUI

struct BiddingView: View {
    @EnvironmentObject var auction: Auction
    @State var selectedBidID: Int = Bid(1, .clubs).id

    enum Action: CaseIterable {
        case pass
        case bid
        case double
        case redouble
        case close
        
        var label: String {
            switch self {
            case .pass: return "Pass"
            case .bid: return "Bid"
            case .double: return "Double"
            case .redouble: return "Redouble"
            case .close: return "Close"
            }
        }
        
        var systemImage: String {
            switch self {
            case .pass: return "hand.thumbsdown"
            case .bid: return "hand.thumbsup"
            case .double: return "exclamationmark"
            case .redouble: return "exclamationmark.2"
            case .close: return "xmark.cirlce"
            }
        }
    }
    
    var minimumBid: Bid {
        Bid(minimumLevel, minimumSuit)
    }

    var validBids: [Bid] {
        Bid.allBids.filter { $0 >= minimumBid }
    }
    
    var minimumLevel: Int {
        guard let level = auction.level else { return 1 }
        
        if let suit = auction.suit,  case .notrump = suit {
            return level + 1
        }
        return level
    }
    
    var minimumSuit: Suit {
        guard let suit = auction.suit, suit < .notrump else { return .clubs }
        // New level, so
        if let next = suit.next {
            return next
        } else { 
            return .clubs
        }
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Picker(selection: $selectedBidID) {
                ForEach(validBids.isEmpty ? [Bid(7, .notrump)] : validBids, id: \.id) { b in
                    HStack {
                        Text(String(b.level))
                        b.suit
                    }
                }
            }
            label: {
                Text("Level")
            }
            .pickerStyle(.inline)
            .disabled(auction.closed || validBids.isEmpty)
            .onAppear {
                selectedBidID = validBids.first?.id ?? Bid(7, .notrump).id
            }

            VStack(alignment: .leading, spacing: 8) {
                Button {
                    auction.pass()
                } label: {
                    Label(Action.pass.label, systemImage: Action.pass.systemImage)
                        .frame(maxWidth:.infinity)
                }
                .labelStyle(.titleOnly)
                .buttonStyle(.bordered)

                Button {
                    auction.bid(Bid(id: selectedBidID))
                    selectedBidID = validBids.first?.id ?? selectedBidID
                } label: {
                    Label(Action.bid.label, systemImage: Action.bid.systemImage)
                        .frame(maxWidth:.infinity)
                }
                .disabled(validBids.isEmpty || selectedBidID < minimumBid.value)
                .labelStyle(.titleOnly)
                .buttonStyle(.borderedProminent)

                Button {
                    auction.double()
                } label: {
                    Label(Action.double.label, systemImage: Action.double.systemImage)
                        .frame(maxWidth:.infinity)
                }
                .labelStyle(.titleOnly)
                .disabled(!auction.canDouble(by: auction.bidder))
                .buttonStyle(.bordered)

                Button {
                    auction.redouble()
                } label: {
                    Label(Action.redouble.label, systemImage: Action.redouble.systemImage)
                        .frame(maxWidth:.infinity)
                }
                .labelStyle(.titleOnly)
                .disabled(!auction.canRedouble(by: auction.bidder))
                .buttonStyle(.bordered)

                Button {
                    auction.close()
                } label: {
                    Label(Action.close.label, systemImage: Action.close.systemImage)
                        .frame(maxWidth:.infinity)
                }
                .labelStyle(.titleOnly)
                .buttonStyle(.bordered)
            }
            .disabled(auction.closed)
        }.padding()
    }
}

struct BiddingView_Previews: PreviewProvider {
    static var previews: some View {
        BiddingView()
            .environmentObject(Auction.mock)
    }
}
