//
//  BiddingView.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/2/22.
//

import SwiftUI

struct BiddingView: View {
    @EnvironmentObject var auction: Auction
    @State var selectedLevel: Int = 1
    @State var selectedSuit: Suit = .clubs
    
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
        if selectedLevel > minimumLevel {
            return .clubs
        } else if let next = suit.next {
            return next
        }
        return suit
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Picker(selection: $selectedLevel) {
                let levels = Array(1...7)
                ForEach(levels, id: \.self) { level in
                    Text(String(level))
                }
            }
            label: {
                Text("Level")
            }
            .pickerStyle(.inline)
            .disabled(auction.closed)
            
            Picker(selection: $selectedSuit) {
                ForEach(Suit.allCases, id: \.self) { suit in
                    suit
                }
            }
            label: {
                Text("Suit")
            }
            .pickerStyle(.inline)
            .disabled(auction.closed)
            
            VStack(alignment: .leading, spacing: 20) {
                Button {
                    auction.pass()
                } label: {
                    Label(Action.pass.label, systemImage: Action.pass.systemImage)
                }
                .labelStyle(.titleOnly)
                
                Button {
                    auction.bid(level: selectedLevel, suit: selectedSuit)
                } label: {
                    Label(Action.bid.label, systemImage: Action.bid.systemImage)
                }
                .disabled(selectedLevel < minimumLevel || selectedSuit < minimumSuit)
                .labelStyle(.titleOnly)
                
                Button {
                    auction.double()
                } label: {
                    Label(Action.double.label, systemImage: Action.double.systemImage)
                }
                .labelStyle(.titleOnly)
                .disabled(!auction.canDouble(by: auction.currentBidder))
                
                Button {
                    auction.redouble()
                } label: {
                    Label(Action.redouble.label, systemImage: Action.redouble.systemImage)
                }
                .labelStyle(.titleOnly)
                .disabled(!auction.canRedouble(by: auction.currentBidder))
                
                Button {
                    auction.close()
                } label: {
                    Label(Action.close.label, systemImage: Action.close.systemImage)
                }
                .labelStyle(.titleOnly)
            }
            .disabled(auction.closed)
        }
    }
}

struct BiddingView_Previews: PreviewProvider {
    static var previews: some View {
        BiddingView()
            .environmentObject(Auction.mock)
    }
}
