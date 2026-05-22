import SwiftUI

struct GameTypeGridView: View {
    @Environment(GameRegistry.self) private var registry
    var onSelect: (String) -> Void

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(registry.moduleInfos) { info in
                    Button { onSelect(info.id) } label: {
                        GameModuleCard(info: info)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("ScorePad")
    }
}

private struct GameModuleCard: View {
    let info: GameModuleInfo

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: info.systemImage)
                    .font(.system(size: 30))
                    .foregroundStyle(.tint)
            }
            VStack(spacing: 4) {
                Text(info.name)
                    .font(.headline)
                Text(info.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.separator, lineWidth: 0.5)
        }
    }
}
