//
//  ScorePadApp.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/28/22.
//

import SwiftUI
import SwiftData
import OSLog

@main
struct ScorePadApp: App {
    static let modules: [any GameModule] = [BridgeModule(), MilleBornesModule(), Phase10Module()]

    /// Every persisted type: the shared player roster plus each registered module's models.
    static let schema = Schema([PersonProfile.self] + modules.flatMap(\.modelTypes))

    let registry = GameRegistry(modules: ScorePadApp.modules)

    var sharedModelContainer: ModelContainer = {
        let schema = ScorePadApp.schema
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Keep the unreadable store for inspection rather than deleting it, then start an
            // empty one; CloudKit re-imports whatever it has already synced.
            let logger = Logger(subsystem: "com.nathan47.ScorePad", category: "Storage")
            logger.error("Could not open the data store: \(error, privacy: .public)")
            ScorePadApp.moveStoreAside(at: config.url, logger: logger)
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create an empty data store: \(error)")
            }
        }
    }()

    private static func moveStoreAside(at url: URL, logger: Logger) {
        let stamp = Date.now.formatted(.iso8601.dateSeparator(.omitted).timeSeparator(.omitted))
        for suffix in ["", "-shm", "-wal"] {
            let source = URL(filePath: url.path + suffix)
            guard FileManager.default.fileExists(atPath: source.path) else { continue }
            let backup = URL(filePath: url.path + ".unreadable-\(stamp)" + suffix)
            do {
                try FileManager.default.moveItem(at: source, to: backup)
            } catch {
                logger.error("Could not move \(source.lastPathComponent) aside: \(error, privacy: .public)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(sharedModelContainer)
        .environment(registry)
    }
}
