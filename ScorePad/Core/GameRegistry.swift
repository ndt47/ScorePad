import SwiftData
import Observation

@Observable
final class GameRegistry {
    let modules: [GameModuleDescriptor]

    init(modules: [GameModuleDescriptor]) {
        self.modules = modules
    }

    func module(id: String) -> GameModuleDescriptor? {
        modules.first { $0.id == id }
    }

    /// All PersistentModel types across all modules, merged with the provided shared types.
    func allModelTypes(adding shared: [any PersistentModel.Type]) -> [any PersistentModel.Type] {
        modules.flatMap(\.modelTypes) + shared
    }
}
