//
//  ContentView.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/28/22.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedRubberId: Rubber.ID?
    let rubbers = [Rubber.mock, Rubber.mock, Rubber.mock]
    
    var body: some View {
        NavigationSplitView {
            List(rubbers, selection: $selectedRubberId) { item in
                RubberHeader()
                    .environmentObject(item)
            }
        } detail: {
            if let selectedRubberId,
               let rubber = rubbers.first(where: { $0.id == selectedRubberId }) {
                RubberView(rubber: rubber)
            } else {
                EmptyView()
            }
        }
//        NavigationView {
//            let rubber = Rubber(
//                players: [
//                    Player(name: "Nathan", position: .south),
//                    Player(name: "Larisa", position: .north),
//                    Player(name: "Sharon", position: .west),
//                    Player(name: "Caty", position: .east)
//                ]
//            )
//            RubberView(rubber: rubber)
//        }
//        .navigationViewStyle(.automatic)

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
