import Foundation
import GRDB

/// Manages the local SQLite database using GRDB
/// Handles database setup, migrations, and provides read/write access
public final class DatabaseManager {

    // MARK: - Properties

    private var dbQueue: DatabaseQueue?

    /// Read-only access to the database
    public var reader: DatabaseReader? { dbQueue }

    /// Read-write access to the database
    public var writer: DatabaseWriter? { dbQueue }

    // MARK: - Initialization

    public init() {
        // Database is initialized lazily via initialize()
    }

    /// Initialize the database connection and run migrations
    public func initialize() async throws {
        let fileManager = FileManager.default

        // Get application support directory
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        // Create database file path
        let dbURL = appSupport.appendingPathComponent("dietapp.sqlite")

        // Create database queue
        dbQueue = try DatabaseQueue(path: dbURL.path)

        // Configure database
        try await dbQueue?.write { db in
            // Enable foreign key constraints
            try db.execute(sql: "PRAGMA foreign_keys = ON")
            // Enable WAL mode for better concurrency
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }

        // Run migrations
        try runMigrations()
    }

    /// Initialize an in-memory database for testing
    public func initializeInMemory() throws {
        dbQueue = try DatabaseQueue()
        try runMigrations()
    }

    // MARK: - Migrations

    private func runMigrations() throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        var migrator = DatabaseMigrator()

        #if DEBUG
        // Erase database on schema change during development
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        // V1: Initial schema
        migrator.registerMigration("v1_initial") { db in
            // Users table
            try db.create(table: "users") { t in
                t.column("id", .text).primaryKey()
                t.column("email", .text).notNull()
                t.column("display_name", .text)
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
                t.column("tracking_mode", .text).notNull().defaults(to: "full")
                t.column("recovery_mode_enabled", .boolean).notNull().defaults(to: false)
                t.column("synced", .boolean).notNull().defaults(to: false)
            }

            // Foods table (cached food database)
            try db.create(table: "foods") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("brand", .text)
                t.column("barcode", .text).indexed()
                t.column("serving_size", .double).notNull()
                t.column("serving_unit", .text).notNull()
                t.column("calories", .double).notNull()
                t.column("protein", .double).notNull()
                t.column("carbs", .double).notNull()
                t.column("fat", .double).notNull()
                t.column("fiber", .double)
                t.column("sugar", .double)
                t.column("sodium", .double)
                t.column("source", .text).notNull() // usda, nutritionix, custom, ai
                t.column("verified", .boolean).notNull().defaults(to: false)
                t.column("is_custom", .boolean).notNull().defaults(to: false)
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
            }

            // FTS5 virtual table for food search
            try db.create(virtualTable: "foods_fts", using: FTS5()) { t in
                t.synchronize(withTable: "foods")
                t.tokenizer = .porter()
                t.column("name")
                t.column("brand")
            }

            // Food logs table
            try db.create(table: "food_logs") { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull()
                    .references("users", onDelete: .cascade)
                t.column("food_id", .text)
                    .references("foods", onDelete: .setNull)
                t.column("date", .date).notNull().indexed()
                t.column("meal_type", .text).notNull() // breakfast, lunch, dinner, snack
                t.column("quantity", .double).notNull()
                t.column("unit", .text).notNull()
                t.column("calories", .double).notNull()
                t.column("protein", .double).notNull()
                t.column("carbs", .double).notNull()
                t.column("fat", .double).notNull()
                t.column("fiber", .double)
                t.column("notes", .text)
                t.column("photo_url", .text)
                t.column("ai_confidence", .double)
                t.column("logged_at", .datetime).notNull()
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
                t.column("synced", .boolean).notNull().defaults(to: false)
            }

            // Weight logs table
            try db.create(table: "weight_logs") { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull()
                    .references("users", onDelete: .cascade)
                t.column("weight_kg", .double).notNull()
                t.column("body_fat_percent", .double)
                t.column("date", .date).notNull().indexed()
                t.column("source", .text).notNull() // manual, healthkit, scale
                t.column("notes", .text)
                t.column("created_at", .datetime).notNull()
                t.column("synced", .boolean).notNull().defaults(to: false)
            }

            // Create composite indexes for common queries
            try db.create(
                index: "idx_food_logs_user_date",
                on: "food_logs",
                columns: ["user_id", "date"]
            )
            try db.create(
                index: "idx_weight_logs_user_date",
                on: "weight_logs",
                columns: ["user_id", "date"]
            )
        }

        try migrator.migrate(dbQueue)
    }
}

// MARK: - Errors

public enum DatabaseError: Error, LocalizedError {
    case notInitialized
    case migrationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Database has not been initialized"
        case .migrationFailed(let message):
            return "Database migration failed: \(message)"
        }
    }
}
