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
        // Must be registered before any ModelContainer touches the schema.
        PlayerRefArrayTransformer.register()

        let schema = Schema(ScorePadSchemaV2.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        // Convert any legacy binary-plist [String] player columns to JSON [PlayerRef]
        // before SwiftData opens the store. SwiftData uses `try!` internally to decode
        // Codable attributes, so old binary-plist rows crash the app without this step.
        SQLitePlayerMigration.migrateIfNeeded(at: config.url)

        // No SchemaMigrationPlan: existing stores predate versioned schemas and have no
        // version stamp, so staged migration always fails with "unknown model version".
        // Inferred migration handles schema changes.
        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            // Re-save migrated games so SwiftData uploads the new JSON format to CloudKit,
            // preventing old binary-plist server records from overwriting the local data.
            SQLitePlayerMigration.touchForCloudKitIfNeeded(in: container)
            return container
        }

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
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(sharedModelContainer)
        .environment(registry)
    }
}
