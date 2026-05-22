import Observation

/// Lightweight value type exposing only the display metadata of a registered module.
/// Used by UI that iterates over modules without needing associated-type dispatch.
struct GameModuleInfo: Identifiable {
    let id: String
    let name: String
    let systemImage: String
    let subtitle: String
}

@Observable
final class GameRegistry {
    let modules: [any GameModule]

    /// Display-only snapshots of each module, safe to use in `ForEach`.
    var moduleInfos: [GameModuleInfo] {
        modules.map { GameModuleInfo(id: $0.id, name: $0.name, systemImage: $0.systemImage, subtitle: $0.subtitle) }
    }

    init(modules: [any GameModule]) {
        self.modules = modules
    }

    func module(id: String) -> (any GameModule)? {
        modules.first { $0.id == id }
    }
}
