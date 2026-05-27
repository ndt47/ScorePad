import Foundation
import SQLite3
import SwiftData

// Converts legacy binary-plist [String] player columns to JSON [PlayerRef] in the
// local SQLite store before ModelContainer opens. SwiftData uses `try!` to JSON-decode
// Codable attributes, so any row still holding binary plist crashes the app.
enum SQLitePlayerMigration {
    private static let migratedKey  = "playerArraysBplistToJSONMigrated"
    private static let touchKey     = "playerArraysCloudKitTouchNeeded"

    // Call before ModelContainer creation. Safe to call if the store doesn't exist yet.
    static func migrateIfNeeded(at storeURL: URL) {
        guard !UserDefaults.standard.bool(forKey: migratedKey) else { return }
        defer { UserDefaults.standard.set(true, forKey: migratedKey) }
        guard FileManager.default.fileExists(atPath: storeURL.path) else { return }

        var db: OpaquePointer?
        guard sqlite3_open(storeURL.path, &db) == SQLITE_OK, let db else { return }
        defer { sqlite3_close(db) }

        let targets: [(table: String, column: String)] = [
            ("ZPHASE10GAME",      "ZPLAYERS"),
            ("ZMILLEBORNESGAME",  "ZTEAM1PLAYERS"),
            ("ZMILLEBORNESGAME",  "ZTEAM2PLAYERS"),
        ]

        var anyMigrated = false
        for (table, column) in targets {
            if migrateColumn(db: db, table: table, column: column) { anyMigrated = true }
        }

        if anyMigrated { UserDefaults.standard.set(true, forKey: touchKey) }
    }

    // Call after ModelContainer opens. Re-saves migrated games so SwiftData uploads the
    // new JSON format to CloudKit, preventing old binary-plist server records from
    // overwriting the migrated local data on the next sync.
    static func touchForCloudKitIfNeeded(in container: ModelContainer) {
        guard UserDefaults.standard.bool(forKey: touchKey) else { return }
        UserDefaults.standard.removeObject(forKey: touchKey)

        let ctx = ModelContext(container)
        var dirty = false
        if let games = try? ctx.fetch(FetchDescriptor<Phase10Game>()) {
            for g in games { g.lastModified = .now; dirty = true }
        }
        if let games = try? ctx.fetch(FetchDescriptor<MilleBornesGame>()) {
            for g in games { g.lastModified = .now; dirty = true }
        }
        if dirty { try? ctx.save() }
    }

    // Returns true if any rows were converted. Silently skips missing tables/columns.
    @discardableResult
    private static func migrateColumn(db: OpaquePointer, table: String, column: String) -> Bool {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT Z_PK, \(column) FROM \(table)", -1, &stmt, nil) == SQLITE_OK,
              let stmt else { return false }
        defer { sqlite3_finalize(stmt) }

        var updates: [(pk: Int64, json: Data)] = []

        while sqlite3_step(stmt) == SQLITE_ROW {
            let pk = sqlite3_column_int64(stmt, 0)
            guard let blob = sqlite3_column_blob(stmt, 1) else { continue }
            let raw = Data(bytes: blob, count: Int(sqlite3_column_bytes(stmt, 1)))

            // Only process binary plist ("bplist" magic bytes).
            guard raw.count > 6,
                  raw[0] == 0x62, raw[1] == 0x70, raw[2] == 0x6C,
                  raw[3] == 0x69, raw[4] == 0x73, raw[5] == 0x74
            else { continue }

            // Decode old [String] — try secure unarchiving first, fall back to legacy.
            var names: [String]?
            names = (try? NSKeyedUnarchiver.unarchivedObject(
                ofClasses: [NSArray.self, NSString.self], from: raw)) as? [String]
            if names == nil {
                names = NSKeyedUnarchiver.unarchiveObject(with: raw) as? [String]
            }
            guard let names else { continue }

            guard let json = try? JSONEncoder().encode(names.map { PlayerRef(name: $0) })
            else { continue }

            updates.append((pk, json))
        }

        for (pk, json) in updates {
            var up: OpaquePointer?
            guard sqlite3_prepare_v2(db, "UPDATE \(table) SET \(column) = ? WHERE Z_PK = ?",
                                     -1, &up, nil) == SQLITE_OK, let up else { continue }
            defer { sqlite3_finalize(up) }
            json.withUnsafeBytes { _ = sqlite3_bind_blob(up, 1, $0.baseAddress, Int32(json.count), nil) }
            sqlite3_bind_int64(up, 2, pk)
            sqlite3_step(up)
        }

        return !updates.isEmpty
    }
}
