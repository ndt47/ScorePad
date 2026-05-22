import SwiftUI

struct GameTypeGridView: View {
    @Environment(GameRegistry.self) private var registry
    var onSelect: (GameModule) -> Void

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(registry.modules) { module in
                    Button { onSelect(module) } label: {
                        module.gridCardView()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("ScorePad")
    }
}
