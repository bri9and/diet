import Foundation
import GRDB

/// GRDB record representing a food log entry in the local database
public struct FoodLogRecord: Codable, FetchableRecord, PersistableRecord, Identifiable {

    // MARK: - Table Configuration

    public static let databaseTableName = "food_logs"

    // MARK: - Properties

    public var id: String
    public var userId: String
    public var foodId: String?
    public var date: Date
    public var mealType: MealType
    public var quantity: Double
    public var unit: String
    public var calories: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double
    public var fiber: Double?
    public var notes: String?
    public var photoUrl: String?
    public var aiConfidence: Double?
    public var loggedAt: Date
    public var createdAt: Date
    public var updatedAt: Date
    public var synced: Bool

    // MARK: - Types

    public enum MealType: String, Codable, CaseIterable, Identifiable {
        case breakfast
        case lunch
        case dinner
        case snack

        public var id: String { rawValue }

        public var displayName: String {
            switch self {
            case .breakfast: return "Breakfast"
            case .lunch: return "Lunch"
            case .dinner: return "Dinner"
            case .snack: return "Snack"
            }
        }

        public var icon: String {
            switch self {
            case .breakfast: return "sunrise.fill"
            case .lunch: return "sun.max.fill"
            case .dinner: return "moon.fill"
            case .snack: return "carrot.fill"
            }
        }
    }

    // MARK: - Column Mapping

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case foodId = "food_id"
        case date
        case mealType = "meal_type"
        case quantity
        case unit
        case calories
        case protein
        case carbs
        case fat
        case fiber
        case notes
        case photoUrl = "photo_url"
        case aiConfidence = "ai_confidence"
        case loggedAt = "logged_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case synced
    }

    // MARK: - Initialization

    public init(
        id: String = UUID().uuidString,
        userId: String,
        foodId: String? = nil,
        date: Date = Date(),
        mealType: MealType,
        quantity: Double,
        unit: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double? = nil,
        notes: String? = nil,
        photoUrl: String? = nil,
        aiConfidence: Double? = nil,
        loggedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        synced: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.foodId = foodId
        self.date = date
        self.mealType = mealType
        self.quantity = quantity
        self.unit = unit
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.notes = notes
        self.photoUrl = photoUrl
        self.aiConfidence = aiConfidence
        self.loggedAt = loggedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.synced = synced
    }
}

// MARK: - Associations

extension FoodLogRecord {
    public static let user = belongsTo(UserRecord.self)
    public static let food = belongsTo(FoodRecord.self)

    public var user: QueryInterfaceRequest<UserRecord> {
        request(for: FoodLogRecord.user)
    }

    public var food: QueryInterfaceRequest<FoodRecord> {
        request(for: FoodLogRecord.food)
    }
}

// MARK: - Helpers

extension FoodLogRecord {
    /// Creates a copy with updated timestamp
    public func withUpdatedTimestamp() -> FoodLogRecord {
        var copy = self
        copy.updatedAt = Date()
        copy.synced = false
        return copy
    }
}
