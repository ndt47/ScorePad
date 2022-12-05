//
//  CallView.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/2/22.
//

import SwiftUI

struct CallView: View {
    var rubber: Rubber
    let call: Call
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            PlayerView(rubber: rubber, position: call.position)
            Spacer()
            BidView(call.call)
        }
        .frame(height: 20)
    }
}

struct BidView: View {
    var call: Call.Call
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            switch call {
            case let .bid(level, suit):
                Text("\(level)")
                suit
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
                CallView(rubber: .mock, call: call)
            }
        }
        .padding()
    }
}
