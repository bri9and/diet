import Foundation
import GRDB
import Combine

/// Repository for managing food log records
/// Provides CRUD operations and queries for food logs
public final class FoodLogRepository {

    // MARK: - Properties

    private let databaseManager: DatabaseManager

    // MARK: - Initialization

    public init(databaseManager: DatabaseManager) {
        self.databaseManager = databaseManager
    }

    // MARK: - Fetch Operations

    /// Fetch all food logs for today
    public func fetchToday(userId: String) async throws -> [FoodLogRecord] {
        guard let reader = databaseManager.reader else {
            throw RepositoryError.databaseNotInitialized
        }

        let today = Calendar.current.startOfDay(for: Date())

        return try await reader.read { db in
            try FoodLogRecord
                .filter(Column("user_id") == userId)
                .filter(Column("date") == today)
                .order(Column("logged_at").asc)
                .fetchAll(db)
        }
    }

    /// Fetch food logs for a specific date
    public func fetchForDate(_ date: Date, userId: String) async throws -> [FoodLogRecord] {
        guard let reader = databaseManager.reader else {
            throw RepositoryError.databaseNotInitialized
        }

        let startOfDay = Calendar.current.startOfDay(for: date)

        return try await reader.read { db in
            try FoodLogRecord
                .filter(Column("user_id") == userId)
                .filter(Column("date") == startOfDay)
                .order(Column("logged_at").asc)
                .fetchAll(db)
        }
    }

    /// Fetch food logs for a date range
    public func fetchForDateRange(
        from startDate: Date,
        to endDate: Date,
        userId: String
    ) async throws -> [FoodLogRecord] {
        guard let reader = databaseManager.reader else {
            throw RepositoryError.databaseNotInitialized
        }

        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)

        return try await reader.read { db in
            try FoodLogRecord
                .filter(Column("user_id") == userId)
                .filter(Column("date") >= start && Column("date") <= end)
                .order(Column("date").desc, Column("logged_at").desc)
                .fetchAll(db)
        }
    }

    /// Fetch food logs by meal type for a date
    public func fetchByMeal(
        _ mealType: FoodLogRecord.MealType,
        date: Date,
        userId: String
    ) async throws -> [FoodLogRecord] {
        guard let reader = databaseManager.reader else {
            throw RepositoryError.databaseNotInitialized
        }

        let startOfDay = Calendar.current.startOfDay(for: date)

        return try await reader.read { db in
            try FoodLogRecord
                .filter(Column("user_id") == userId)
                .filter(Column("date") == startOfDay)
                .filter(Column("meal_type") == mealType.rawValue)
                .order(Column("logged_at").asc)
                .fetchAll(db)
        }
    }

    /// Fetch a single food log by ID
    public func fetch(id: String) async throws -> FoodLogRecord? {
        guard let reader = databaseManager.reader else {
            throw RepositoryError.databaseNotInitialized
        }

        return try await reader.read { db in
            try FoodLogRecord.fetchOne(db, key: id)
        }
    }

    // MARK: - Write Operations

    /// Save a new food log
    public func save(_ record: FoodLogRecord) async throws {
        guard let writer = databaseManager.writer else {
            throw RepositoryError.databaseNotInitialized
        }

        var mutableRecord = record
        mutableRecord.updatedAt = Date()
        mutableRecord.synced = false

        let recordToSave = mutableRecord

        try await writer.write { db in
            try recordToSave.save(db)
        }
    }

    /// Update an existing food log
    public func update(_ record: FoodLogRecord) async throws {
        guard let writer = databaseManager.writer else {
            throw RepositoryError.databaseNotInitialized
        }

        var mutableRecord = record
        mutableRecord.updatedAt = Date()
        mutableRecord.synced = false

        let recordToUpdate = mutableRecord

        try await writer.write { db in
            try recordToUpdate.update(db)
        }
    }

    /// Delete a food log by ID
    public func delete(id: String) async throws {
        guard let writer = databaseManager.writer else {
            throw RepositoryError.databaseNotInitialized
        }

        _ = try await writer.write { db in
            try FoodLogRecord.deleteOne(db, key: id)
        }
    }

    /// Delete all food logs for a user
    public func deleteAll(userId: String) async throws {
        guard let writer = databaseManager.writer else {
            throw RepositoryError.databaseNotInitialized
        }

        _ = try await writer.write { db in
            try FoodLogRecord
                .filter(Column("user_id") == userId)
                .deleteAll(db)
        }
    }

    // MARK: - Aggregations

    /// Calculate daily nutrition totals
    public func dailyNutrition(userId: String, date: Date) async throws -> NutritionSummary {
        guard let reader = databaseManager.reader else {
            throw RepositoryError.databaseNotInitialized
        }

        let startOfDay = Calendar.current.startOfDay(for: date)

        return try await reader.read { db in
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

            let row = try Row.fetchOne(db, sql: sql, arguments: [userId, startOfDay])

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

    /// Observe food logs for today (returns a publisher)
    public func observeToday(userId: String) -> AnyPublisher<[FoodLogRecord], Error> {
        guard let reader = databaseManager.reader else {
            return Fail(error: RepositoryError.databaseNotInitialized)
                .eraseToAnyPublisher()
        }

        let today = Calendar.current.startOfDay(for: Date())

        return ValueObservation
            .tracking { db in
                try FoodLogRecord
                    .filter(Column("user_id") == userId)
                    .filter(Column("date") == today)
                    .order(Column("logged_at").asc)
                    .fetchAll(db)
            }
            .publisher(in: reader, scheduling: .immediate)
            .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Types

/// Summary of nutrition data
public struct NutritionSummary: Equatable {
    public let calories: Double
    public let protein: Double
    public let carbs: Double
    public let fat: Double
    public let fiber: Double

    public init(calories: Double, protein: Double, carbs: Double, fat: Double, fiber: Double) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
    }

    public static let empty = NutritionSummary(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0
    )
}

// MARK: - Errors

public enum RepositoryError: Error, LocalizedError {
    case databaseNotInitialized
    case recordNotFound
    case saveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .databaseNotInitialized:
            return "Database has not been initialized"
        case .recordNotFound:
            return "Record not found"
        case .saveFailed(let message):
            return "Failed to save record: \(message)"
        }
    }
}
