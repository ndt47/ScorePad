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
    let registry = GameRegistry(modules: [.bridge])

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Rubber.self,
            Auction.self,
            PersonProfile.self,
        ])
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
