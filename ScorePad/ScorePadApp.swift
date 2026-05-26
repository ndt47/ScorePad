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
        let schema = Schema(ScorePadSchemaV2.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        // Staged migration: handles stores that were created with a prior versioned schema.
        // SwiftData wraps the underlying NSCocoaError 134504 in a SwiftDataError, so we
        // catch broadly and fall through to inferred migration on any failure.
        if let container = try? ModelContainer(for: schema, migrationPlan: ScorePadMigrationPlan.self,
                                               configurations: [config]) {
            return container
        }

        // Inferred migration: handles stores created before we adopted SchemaMigrationPlan.
        // PlayerRef's backwards-compatible decoder handles old bare-string player data.
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema incompatible — destroy the store and start fresh.
            // AppRootView.migratePlayerProfiles() and CloudKit sync will restore data.
            let url = config.url
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(atPath: url.path + suffix)
            }
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer after store reset: \(error)")
            }
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
