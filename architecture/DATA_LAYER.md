# Data Layer Design
## Diet App - GRDB Schema & Repository Pattern

---

## 1. GRDB Database Schema

### Database Setup

```swift
import GRDB

// MARK: - Database Manager
final class DatabaseManager {
    private let dbQueue: DatabaseQueue

    static let shared = DatabaseManager()

    init(inMemory: Bool = false) {
        do {
            if inMemory {
                dbQueue = try DatabaseQueue()
            } else {
                let fileManager = FileManager.default
                let appSupport = try fileManager.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
                let dbURL = appSupport.appendingPathComponent("dietapp.sqlite")
                dbQueue = try DatabaseQueue(path: dbURL.path)
            }

            // Enable SQLite protections
            try dbQueue.write { db in
                // Foreign keys
                try db.execute(sql: "PRAGMA foreign_keys = ON")
                // WAL mode for better concurrency
                try db.execute(sql: "PRAGMA journal_mode = WAL")
            }

            // Run migrations
            try MigrationRunner.run(dbQueue)

        } catch {
            fatalError("Database initialization failed: \(error)")
        }
    }

    var reader: DatabaseReader { dbQueue }
    var writer: DatabaseWriter { dbQueue }
}
```

### Migration System

```swift
// MARK: - Migration Runner
struct MigrationRunner {
    static func run(_ dbQueue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()

        // Development mode: wipe on schema change
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        // V1: Initial Schema
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
            }

            // User Goals table
            try db.create(table: "user_goals") { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull()
                    .references("users", onDelete: .cascade)
                t.column("calorie_target", .integer)
                t.column("protein_target", .double)
                t.column("carbs_target", .double)
                t.column("fat_target", .double)
                t.column("fiber_target", .double)
                t.column("water_target", .double)
                t.column("goal_type", .text).notNull() // lose, maintain, gain
                t.column("activity_level", .text).notNull()
                t.column("effective_from", .date).notNull()
                t.column("created_at", .datetime).notNull()
            }

            // Food Items (cached food database)
            try db.create(table: "food_items") { t in
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
                t.column("saturated_fat", .double)
                t.column("cholesterol", .double)
                t.column("source", .text).notNull() // usda, nutritionix, user, ai
                t.column("verified", .boolean).notNull().defaults(to: false)
                t.column("is_custom", .boolean).notNull().defaults(to: false)
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
            }

            // FTS5 index for food search
            try db.create(virtualTable: "food_items_fts", using: FTS5()) { t in
                t.synchronize(withTable: "food_items")
                t.tokenizer = .porter()
                t.column("name")
                t.column("brand")
            }

            // Food Logs (user's logged meals)
            try db.create(table: "food_logs") { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull()
                    .references("users", onDelete: .cascade)
                t.column("food_item_id", .text)
                    .references("food_items", onDelete: .setNull)
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

            // Favorites
            try db.create(table: "favorites") { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull()
                    .references("users", onDelete: .cascade)
                t.column("food_item_id", .text).notNull()
                    .references("food_items", onDelete: .cascade)
                t.column("default_quantity", .double).notNull()
                t.column("default_unit", .text).notNull()
                t.column("use_count", .integer).notNull().defaults(to: 0)
                t.column("last_used_at", .datetime)
                t.column("created_at", .datetime).notNull()

                t.uniqueKey(["user_id", "food_item_id"])
            }

            // Weight Logs
            try db.create(table: "weight_logs") { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull()
                    .references("users", onDelete: .cascade)
                t.column("weight", .double).notNull() // kg
                t.column("body_fat_percent", .double)
                t.column("date", .date).notNull().indexed()
                t.column("source", .text).notNull() // manual, healthkit, scale
                t.column("notes", .text)
                t.column("created_at", .datetime).notNull()
                t.column("synced", .boolean).notNull().defaults(to: false)
            }

            // Sync Queue (offline operations)
            try db.create(table: "sync_queue") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("entity_type", .text).notNull()
                t.column("entity_id", .text).notNull()
                t.column("operation", .text).notNull() // create, update, delete
                t.column("payload", .blob).notNull()
                t.column("created_at", .datetime).notNull()
                t.column("retry_count", .integer).notNull().defaults(to: 0)
                t.column("last_error", .text)
            }

            // Indices for common queries
            try db.create(index: "idx_food_logs_user_date",
                         on: "food_logs",
                         columns: ["user_id", "date"])
            try db.create(index: "idx_weight_logs_user_date",
                         on: "weight_logs",
                         columns: ["user_id", "date"])
        }

        try migrator.migrate(dbQueue)
    }
}
```

---

## 2. Record Types (GRDB Models)

```swift
import GRDB
import Foundation

// MARK: - User Record
struct UserRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "users"

    var id: String
    var email: String
    var displayName: String?
    var createdAt: Date
    var updatedAt: Date
    var trackingMode: TrackingMode
    var recoveryModeEnabled: Bool

    enum TrackingMode: String, Codable {
        case full
        case light
        case mindful // Recovery mode
    }
}

// MARK: - User Goals Record
struct UserGoalsRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "user_goals"

    var id: String
    var userId: String
    var calorieTarget: Int?
    var proteinTarget: Double?
    var carbsTarget: Double?
    var fatTarget: Double?
    var fiberTarget: Double?
    var waterTarget: Double?
    var goalType: GoalType
    var activityLevel: ActivityLevel
    var effectiveFrom: Date
    var createdAt: Date

    enum GoalType: String, Codable {
        case lose, maintain, gain
    }

    enum ActivityLevel: String, Codable {
        case sedentary, light, moderate, active, veryActive
    }
}

// MARK: - Food Item Record
struct FoodItemRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "food_items"

    var id: String
    var name: String
    var brand: String?
    var barcode: String?
    var servingSize: Double
    var servingUnit: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double?
    var sugar: Double?
    var sodium: Double?
    var saturatedFat: Double?
    var cholesterol: Double?
    var source: FoodSource
    var verified: Bool
    var isCustom: Bool
    var createdAt: Date
    var updatedAt: Date

    enum FoodSource: String, Codable {
        case usda, nutritionix, openFoodFacts, user, ai
    }

    // Column name mapping
    enum CodingKeys: String, CodingKey {
        case id, name, brand, barcode
        case servingSize = "serving_size"
        case servingUnit = "serving_unit"
        case calories, protein, carbs, fat, fiber, sugar, sodium
        case saturatedFat = "saturated_fat"
        case cholesterol, source, verified
        case isCustom = "is_custom"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Food Log Record
struct FoodLogRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "food_logs"

    var id: String
    var userId: String
    var foodItemId: String?
    var date: Date
    var mealType: MealType
    var quantity: Double
    var unit: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double?
    var notes: String?
    var photoUrl: String?
    var aiConfidence: Double?
    var loggedAt: Date
    var createdAt: Date
    var updatedAt: Date
    var synced: Bool

    enum MealType: String, Codable, CaseIterable {
        case breakfast, lunch, dinner, snack
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case foodItemId = "food_item_id"
        case date
        case mealType = "meal_type"
        case quantity, unit, calories, protein, carbs, fat, fiber, notes
        case photoUrl = "photo_url"
        case aiConfidence = "ai_confidence"
        case loggedAt = "logged_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case synced
    }
}

// MARK: - Weight Log Record
struct WeightLogRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "weight_logs"

    var id: String
    var userId: String
    var weight: Double // kilograms
    var bodyFatPercent: Double?
    var date: Date
    var source: WeightSource
    var notes: String?
    var createdAt: Date
    var synced: Bool

    enum WeightSource: String, Codable {
        case manual, healthkit, scale
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case weight
        case bodyFatPercent = "body_fat_percent"
        case date, source, notes
        case createdAt = "created_at"
        case synced
    }
}

// MARK: - Sync Queue Record
struct SyncQueueRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "sync_queue"

    var id: Int64?
    var entityType: String
    var entityId: String
    var operation: SyncOperation
    var payload: Data
    var createdAt: Date
    var retryCount: Int
    var lastError: String?

    enum SyncOperation: String, Codable {
        case create, update, delete
    }

    enum CodingKeys: String, CodingKey {
        case id
        case entityType = "entity_type"
        case entityId = "entity_id"
        case operation, payload
        case createdAt = "created_at"
        case retryCount = "retry_count"
        case lastError = "last_error"
    }
}
```

---

## 3. Repository Pattern

```swift
import GRDB
import Combine

// MARK: - Base Repository Protocol
protocol Repository {
    associatedtype Entity: FetchableRecord & PersistableRecord

    var database: DatabaseManager { get }

    func fetch(id: String) async throws -> Entity?
    func fetchAll() async throws -> [Entity]
    func save(_ entity: Entity) async throws
    func delete(id: String) async throws
}

// MARK: - Food Log Repository
final class FoodLogRepository {
    private let database: DatabaseManager
    private let syncQueue: SyncQueueManager

    init(database: DatabaseManager, syncQueue: SyncQueueManager = .shared) {
        self.database = database
        self.syncQueue = syncQueue
    }

    // MARK: - Fetch Operations

    func fetchToday(userId: String) async throws -> [FoodLogRecord] {
        try await database.reader.read { db in
            let today = Calendar.current.startOfDay(for: Date())
            return try FoodLogRecord
                .filter(Column("user_id") == userId)
                .filter(Column("date") == today)
                .order(Column("logged_at").asc)
                .fetchAll(db)
        }
    }

    func fetchByDateRange(
        userId: String,
        from: Date,
        to: Date
    ) async throws -> [FoodLogRecord] {
        try await database.reader.read { db in
            try FoodLogRecord
                .filter(Column("user_id") == userId)
                .filter(Column("date") >= from && Column("date") <= to)
                .order(Column("date").desc, Column("logged_at").desc)
                .fetchAll(db)
        }
    }

    func fetchByMeal(
        userId: String,
        date: Date,
        meal: FoodLogRecord.MealType
    ) async throws -> [FoodLogRecord] {
        try await database.reader.read { db in
            try FoodLogRecord
                .filter(Column("user_id") == userId)
                .filter(Column("date") == date)
                .filter(Column("meal_type") == meal.rawValue)
                .order(Column("logged_at").asc)
                .fetchAll(db)
        }
    }

    // MARK: - Write Operations

    func save(_ record: FoodLogRecord) async throws {
        var mutableRecord = record
        mutableRecord.updatedAt = Date()
        mutableRecord.synced = false

        try await database.writer.write { db in
            try mutableRecord.save(db)
        }

        // Queue for sync
        try await syncQueue.enqueue(
            entityType: "food_log",
            entityId: record.id,
            operation: .create,
            payload: record
        )
    }

    func update(_ record: FoodLogRecord) async throws {
        var mutableRecord = record
        mutableRecord.updatedAt = Date()
        mutableRecord.synced = false

        try await database.writer.write { db in
            try mutableRecord.update(db)
        }

        try await syncQueue.enqueue(
            entityType: "food_log",
            entityId: record.id,
            operation: .update,
            payload: record
        )
    }

    func delete(id: String) async throws {
        let record = try await database.reader.read { db in
            try FoodLogRecord.fetchOne(db, key: id)
        }

        guard let record else { return }

        try await database.writer.write { db in
            try FoodLogRecord.deleteOne(db, key: id)
        }

        try await syncQueue.enqueue(
            entityType: "food_log",
            entityId: id,
            operation: .delete,
            payload: record
        )
    }

    // MARK: - Aggregations

    func dailyNutrition(userId: String, date: Date) async throws -> NutritionSummary {
        try await database.reader.read { db in
            let sql = """
                SELECT
                    COALESCE(SUM(calories), 0) as total_calories,
                    COALESCE(SUM(protein), 0) as total_protein,
                    COALESCE(SUM(carbs), 0) as total_carbs,
                    COALESCE(SUM(fat), 0) as total_fat,
                    COALESCE(SUM(fiber), 0) as total_fiber
                FROM food_logs
                WHERE user_id = ? AND date = ?
                """

            let row = try Row.fetchOne(db, sql: sql, arguments: [userId, date])

            return NutritionSummary(
                calories: row?["total_calories"] ?? 0,
                protein: row?["total_protein"] ?? 0,
                carbs: row?["total_carbs"] ?? 0,
                fat: row?["total_fat"] ?? 0,
                fiber: row?["total_fiber"] ?? 0
            )
        }
    }

    // MARK: - Observation

    func observeToday(userId: String) -> AnyPublisher<[FoodLogRecord], Error> {
        let today = Calendar.current.startOfDay(for: Date())

        return ValueObservation
            .tracking { db in
                try FoodLogRecord
                    .filter(Column("user_id") == userId)
                    .filter(Column("date") == today)
                    .order(Column("logged_at").asc)
                    .fetchAll(db)
            }
            .publisher(in: database.reader, scheduling: .immediate)
            .eraseToAnyPublisher()
    }
}

// MARK: - Food Item Repository
final class FoodItemRepository {
    private let database: DatabaseManager

    init(database: DatabaseManager) {
        self.database = database
    }

    // MARK: - Search (FTS5)

    func search(query: String, limit: Int = 50) async throws -> [FoodItemRecord] {
        try await database.reader.read { db in
            // FTS5 search with ranking
            let pattern = FTS5Pattern(matchingAllPrefixesIn: query)

            let sql = """
                SELECT food_items.*
                FROM food_items
                JOIN food_items_fts ON food_items.id = food_items_fts.rowid
                WHERE food_items_fts MATCH ?
                ORDER BY bm25(food_items_fts), food_items.name
                LIMIT ?
                """

            return try FoodItemRecord.fetchAll(
                db,
                sql: sql,
                arguments: [pattern?.rawPattern ?? query, limit]
            )
        }
    }

    func fetchByBarcode(_ barcode: String) async throws -> FoodItemRecord? {
        try await database.reader.read { db in
            try FoodItemRecord
                .filter(Column("barcode") == barcode)
                .fetchOne(db)
        }
    }

    func fetchRecent(userId: String, limit: Int = 20) async throws -> [FoodItemRecord] {
        try await database.reader.read { db in
            let sql = """
                SELECT DISTINCT fi.*
                FROM food_items fi
                JOIN food_logs fl ON fi.id = fl.food_item_id
                WHERE fl.user_id = ?
                ORDER BY fl.logged_at DESC
                LIMIT ?
                """

            return try FoodItemRecord.fetchAll(db, sql: sql, arguments: [userId, limit])
        }
    }

    func fetchFavorites(userId: String) async throws -> [FoodItemRecord] {
        try await database.reader.read { db in
            let sql = """
                SELECT fi.*
                FROM food_items fi
                JOIN favorites f ON fi.id = f.food_item_id
                WHERE f.user_id = ?
                ORDER BY f.use_count DESC, f.last_used_at DESC
                """

            return try FoodItemRecord.fetchAll(db, sql: sql, arguments: [userId])
        }
    }

    func save(_ record: FoodItemRecord) async throws {
        try await database.writer.write { db in
            try record.save(db)
        }
    }

    func saveFromAPI(_ items: [FoodItemRecord]) async throws {
        try await database.writer.write { db in
            for item in items {
                try item.save(db, onConflict: .ignore)
            }
        }
    }
}
```

---

## 4. Sync Engine Interface (PowerSync)

```swift
import Foundation

// MARK: - Sync Status
enum SyncStatus: Equatable {
    case idle
    case syncing
    case error(SyncError)
    case offline

    enum SyncError: Error, Equatable {
        case networkUnavailable
        case authenticationRequired
        case serverError(Int)
        case conflict(String)
        case unknown(String)
    }
}

// MARK: - Sync Engine Protocol
protocol SyncEngineProtocol {
    var status: SyncStatus { get }
    var statusPublisher: AnyPublisher<SyncStatus, Never> { get }

    func startSync() async
    func stopSync()
    func forcePush() async throws
    func forcePull() async throws
    func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution) async throws
}

// MARK: - Sync Conflict
struct SyncConflict: Identifiable {
    let id: String
    let entityType: String
    let entityId: String
    let localVersion: Data
    let remoteVersion: Data
    let localTimestamp: Date
    let remoteTimestamp: Date
}

enum ConflictResolution {
    case keepLocal
    case keepRemote
    case merge(Data)
}

// MARK: - PowerSync Implementation
final class SyncEngine: SyncEngineProtocol {
    private let database: DatabaseManager
    private let api: APIClient
    private let connectivity: NetworkMonitor

    @Published private(set) var status: SyncStatus = .idle
    var statusPublisher: AnyPublisher<SyncStatus, Never> {
        $status.eraseToAnyPublisher()
    }

    private var syncTask: Task<Void, Never>?
    private let syncInterval: TimeInterval = 30 // seconds

    init(database: DatabaseManager, api: APIClient, connectivity: NetworkMonitor = .shared) {
        self.database = database
        self.api = api
        self.connectivity = connectivity

        setupConnectivityObserver()
    }

    func startSync() async {
        guard syncTask == nil else { return }

        syncTask = Task {
            while !Task.isCancelled {
                await performSync()
                try? await Task.sleep(nanoseconds: UInt64(syncInterval * 1_000_000_000))
            }
        }
    }

    func stopSync() {
        syncTask?.cancel()
        syncTask = nil
    }

    func forcePush() async throws {
        guard connectivity.isConnected else {
            throw SyncStatus.SyncError.networkUnavailable
        }

        status = .syncing

        do {
            let pendingOps = try await fetchPendingOperations()

            for op in pendingOps {
                try await pushOperation(op)
                try await markSynced(op)
            }

            status = .idle
        } catch {
            status = .error(.unknown(error.localizedDescription))
            throw error
        }
    }

    func forcePull() async throws {
        guard connectivity.isConnected else {
            throw SyncStatus.SyncError.networkUnavailable
        }

        status = .syncing

        do {
            let lastSync = UserDefaults.standard.object(forKey: "lastSyncTimestamp") as? Date
            let changes = try await api.fetchChanges(since: lastSync)

            try await applyRemoteChanges(changes)

            UserDefaults.standard.set(Date(), forKey: "lastSyncTimestamp")
            status = .idle
        } catch {
            status = .error(.unknown(error.localizedDescription))
            throw error
        }
    }

    func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution) async throws {
        switch resolution {
        case .keepLocal:
            try await forcePushEntity(type: conflict.entityType, id: conflict.entityId)
        case .keepRemote:
            try await forcePullEntity(type: conflict.entityType, id: conflict.entityId)
        case .merge(let mergedData):
            try await saveMergedEntity(type: conflict.entityType, id: conflict.entityId, data: mergedData)
        }
    }

    // MARK: - Private

    private func performSync() async {
        guard connectivity.isConnected else {
            status = .offline
            return
        }

        status = .syncing

        do {
            try await forcePush()
            try await forcePull()
            status = .idle
        } catch {
            status = .error(.unknown(error.localizedDescription))
        }
    }

    private func setupConnectivityObserver() {
        connectivity.onConnectionRestored = { [weak self] in
            Task {
                await self?.performSync()
            }
        }
    }

    private func fetchPendingOperations() async throws -> [SyncQueueRecord] {
        try await database.reader.read { db in
            try SyncQueueRecord
                .order(Column("created_at").asc)
                .limit(100)
                .fetchAll(db)
        }
    }

    private func pushOperation(_ op: SyncQueueRecord) async throws {
        // Implementation depends on API
    }

    private func markSynced(_ op: SyncQueueRecord) async throws {
        try await database.writer.write { db in
            try SyncQueueRecord.deleteOne(db, key: op.id)
        }
    }

    private func applyRemoteChanges(_ changes: RemoteChanges) async throws {
        // Implementation
    }

    private func forcePushEntity(type: String, id: String) async throws {
        // Implementation
    }

    private func forcePullEntity(type: String, id: String) async throws {
        // Implementation
    }

    private func saveMergedEntity(type: String, id: String, data: Data) async throws {
        // Implementation
    }
}

// MARK: - Offline Queue Manager
final class SyncQueueManager {
    static let shared = SyncQueueManager()

    private let database: DatabaseManager

    init(database: DatabaseManager = .shared) {
        self.database = database
    }

    func enqueue<T: Encodable>(
        entityType: String,
        entityId: String,
        operation: SyncQueueRecord.SyncOperation,
        payload: T
    ) async throws {
        let payloadData = try JSONEncoder().encode(payload)

        let record = SyncQueueRecord(
            id: nil,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payload: payloadData,
            createdAt: Date(),
            retryCount: 0,
            lastError: nil
        )

        try await database.writer.write { db in
            try record.insert(db)
        }
    }

    func pendingCount() async throws -> Int {
        try await database.reader.read { db in
            try SyncQueueRecord.fetchCount(db)
        }
    }

    func clearAll() async throws {
        try await database.writer.write { db in
            try SyncQueueRecord.deleteAll(db)
        }
    }
}
```

---

## 5. Domain Models

```swift
// MARK: - Nutrition Summary
struct NutritionSummary: Equatable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double

    static let empty = NutritionSummary(
        calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0
    )

    init(calories: Double, protein: Double, carbs: Double, fat: Double, fiber: Double) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
    }

    init(from logs: [FoodLogRecord]) {
        self.calories = logs.reduce(0) { $0 + $1.calories }
        self.protein = logs.reduce(0) { $0 + $1.protein }
        self.carbs = logs.reduce(0) { $0 + $1.carbs }
        self.fat = logs.reduce(0) { $0 + $1.fat }
        self.fiber = logs.reduce(0) { $0 + ($1.fiber ?? 0) }
    }

    func progress(against goals: UserGoalsRecord) -> NutritionProgress {
        NutritionProgress(
            calorieProgress: goals.calorieTarget.map { calories / Double($0) } ?? 0,
            proteinProgress: goals.proteinTarget.map { protein / $0 } ?? 0,
            carbsProgress: goals.carbsTarget.map { carbs / $0 } ?? 0,
            fatProgress: goals.fatTarget.map { fat / $0 } ?? 0,
            fiberProgress: goals.fiberTarget.map { fiber / $0 } ?? 0
        )
    }
}

struct NutritionProgress {
    let calorieProgress: Double
    let proteinProgress: Double
    let carbsProgress: Double
    let fatProgress: Double
    let fiberProgress: Double

    var caloriePercentage: Int { Int(min(calorieProgress * 100, 100)) }
    var proteinPercentage: Int { Int(min(proteinProgress * 100, 100)) }
    var carbsPercentage: Int { Int(min(carbsProgress * 100, 100)) }
    var fatPercentage: Int { Int(min(fatProgress * 100, 100)) }
    var fiberPercentage: Int { Int(min(fiberProgress * 100, 100)) }
}

// MARK: - Meal Entry (View Model)
struct MealEntry: Identifiable, Equatable {
    let id: String
    let foodName: String
    let brandName: String?
    let mealType: FoodLogRecord.MealType
    let quantity: Double
    let unit: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let loggedAt: Date
    let photoUrl: String?
    let aiConfidence: Double?

    init(from record: FoodLogRecord, foodItem: FoodItemRecord?) {
        self.id = record.id
        self.foodName = foodItem?.name ?? "Unknown Food"
        self.brandName = foodItem?.brand
        self.mealType = record.mealType
        self.quantity = record.quantity
        self.unit = record.unit
        self.calories = record.calories
        self.protein = record.protein
        self.carbs = record.carbs
        self.fat = record.fat
        self.loggedAt = record.loggedAt
        self.photoUrl = record.photoUrl
        self.aiConfidence = record.aiConfidence
    }
}
```

---

*Document continues in HEALTHKIT_INTEGRATION.md*
