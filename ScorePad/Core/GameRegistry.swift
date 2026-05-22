import Observation

@Observable
final class GameRegistry {
    let modules: [GameModule] = GameModule.allCases
}
