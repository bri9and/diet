import Foundation
import GRDB

/// GRDB record representing a food item in the local database
public struct FoodRecord: Codable, FetchableRecord, PersistableRecord, Identifiable {

    // MARK: - Table Configuration

    public static let databaseTableName = "foods"

    // MARK: - Properties

    public var id: String
    public var name: String
    public var brand: String?
    public var barcode: String?
    public var servingSize: Double
    public var servingUnit: String
    public var calories: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double
    public var fiber: Double?
    public var sugar: Double?
    public var sodium: Double?
    public var source: FoodSource
    public var verified: Bool
    public var isCustom: Bool
    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Types

    public enum FoodSource: String, Codable, CaseIterable {
        case usda           // USDA food database
        case nutritionix    // Nutritionix API
        case openFoodFacts  // Open Food Facts database
        case custom         // User-created food
        case ai             // AI-generated entry
    }

    // MARK: - Column Mapping

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case barcode
        case servingSize = "serving_size"
        case servingUnit = "serving_unit"
        case calories
        case protein
        case carbs
        case fat
        case fiber
        case sugar
        case sodium
        case source
        case verified
        case isCustom = "is_custom"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Initialization

    public init(
        id: String = UUID().uuidString,
        name: String,
        brand: String? = nil,
        barcode: String? = nil,
        servingSize: Double,
        servingUnit: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double? = nil,
        sugar: Double? = nil,
        sodium: Double? = nil,
        source: FoodSource = .custom,
        verified: Bool = false,
        isCustom: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.source = source
        self.verified = verified
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Computed Properties

extension FoodRecord {
    /// Display name including brand if available
    public var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(name) (\(brand))"
        }
        return name
    }

    /// Serving description for display
    public var servingDescription: String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        let sizeString = formatter.string(from: NSNumber(value: servingSize)) ?? "\(servingSize)"
        return "\(sizeString) \(servingUnit)"
    }
}

// MARK: - Associations

extension FoodRecord {
    public static let foodLogs = hasMany(FoodLogRecord.self)
}
