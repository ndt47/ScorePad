//
//  CallView.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/2/22.
//

import SwiftUI

struct CallView: View {
    @EnvironmentObject var rubber: Rubber
    let call: Call
    var onUndo: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            PlayerView(position: call.position)
            Spacer()
            BidView(call.call)
            if let onUndo {
                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 6)
    }
}

struct BidView: View {
    var call: Call.Call
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            switch call {
            case let .bid(b):
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(b.level)")
                    b.suit
                }
            case .pending:
                Text("PENDING")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
           case .pass:
                Text("PASS")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
            case .double:
                Text("DOUBLE")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
            case .redouble:
                Text("REDOUBLE")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
            }
        }
    }
    
    init(_ call: Call.Call) {
        self.call = call
    }
}

struct CallView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ForEach (Auction.mock.calls) { call in
                CallView(call: call)
            }
        }
        .padding()
        .rubber(.mock)
    }
}
