//
//  ScorePadApp.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/28/22.
//

import SwiftUI
import SwiftData

@main
struct ScorePadApp: App {
    static let modules: [any GameModule] = [BridgeModule(), MilleBornesModule(), Phase10Module()]

    let registry = GameRegistry(modules: ScorePadApp.modules)

    var sharedModelContainer: ModelContainer = {
        let modelTypes = ScorePadApp.modules.flatMap(\.modelTypes) + [PersonProfile.self]
        let schema = Schema(modelTypes)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(sharedModelContainer)
        .environment(registry)
    }
}
