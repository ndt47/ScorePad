import SwiftUI

extension GameModuleDescriptor {
    static var bridge: GameModuleDescriptor {
        GameModuleDescriptor(
            id: "bridge",
            name: "Bridge",
            systemImage: "suit.spade.fill",
            subtitle: "Rubber Bridge",
            modelTypes: [Rubber.self, Auction.self],
            makeSessionListView: { selectedID in
                BridgeSessionListView(selectedSessionID: selectedID)
                    .eraseToAnyView()
            },
            makeDetailView: { selectedID in
                BridgeDetailView(selectedSessionID: selectedID)
                    .eraseToAnyView()
            },
            makeNewSessionView: { onSave, onCancel in
                NewRubber(
                    onSave: { rubberID in onSave(rubberID.uuidString) },
                    onCancel: onCancel
                )
                .eraseToAnyView()
            },
            makeGridCardView: {
                BridgeGridCard().eraseToAnyView()
            }
        )
    }
}
