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
            let moved = ScorePadApp.moveStoreAside(at: config.url, logger: logger)
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                // An empty store failing too means the problem isn't the data (e.g. an invalid
                // schema), so restore the original files for a fixed build to open. Clear what the
                // empty store created first, or SQLite could replay a stray -wal into them.
                for file in ScorePadApp.storeFiles(at: config.url) {
                    try? FileManager.default.removeItem(at: file)
                }
                for (original, backup) in moved {
                    try? FileManager.default.moveItem(at: backup, to: original)
                }
                fatalError("Could not create an empty data store: \(error)")
            }
        }
    }()

    /// Renames the store's files with an ".unreadable-<timestamp>" suffix and returns the
    /// (original, backup) pairs that were moved.
    private static func moveStoreAside(at url: URL, logger: Logger) -> [(URL, URL)] {
        let stamp = Date.now.formatted(.iso8601.dateSeparator(.omitted).timeSeparator(.omitted))
        var moved: [(URL, URL)] = []
        for original in storeFiles(at: url) where FileManager.default.fileExists(atPath: original.path) {
            let backup = original.deletingLastPathComponent()
                .appending(path: "\(original.lastPathComponent).unreadable-\(stamp)")
            do {
                try FileManager.default.moveItem(at: original, to: backup)
                moved.append((original, backup))
            } catch {
                logger.error("Could not move \(original.lastPathComponent, privacy: .public) aside: \(error, privacy: .public)")
            }
        }
        return moved
    }

    /// The store file, its SQLite side files, and the directory SwiftData keeps external data in.
    private static func storeFiles(at url: URL) -> [URL] {
        let directory = url.deletingLastPathComponent()
        return ["", "-shm", "-wal"].map { directory.appending(path: url.lastPathComponent + $0) }
            + [directory.appending(path: ".\(url.deletingPathExtension().lastPathComponent)_SUPPORT")]
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(sharedModelContainer)
        .environment(registry)
    }
}
