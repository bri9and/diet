import Foundation

// MARK: - Daily Summary Response

public struct DailySummaryResponse: Decodable {
    public let date: String
    public let totals: DailyTotals
    public let meals: MealsByType
    public let targets: NutritionTargets
}

public struct DailyTotals: Decodable {
    public let calories: Double
    public let proteinG: Double
    public let carbsG: Double
    public let fatG: Double
    public let fiberG: Double
    public let sugarG: Double
    public let sodiumMg: Double
    public let mealCount: Int
    public let itemCount: Int
}

public struct MealsByType: Decodable {
    public let breakfast: [APIFoodLog]
    public let lunch: [APIFoodLog]
    public let dinner: [APIFoodLog]
    public let snack: [APIFoodLog]
}

public struct NutritionTargets: Decodable {
    public let calories: Double
    public let proteinG: Double
    public let carbsG: Double
    public let fatG: Double
}

// MARK: - Food Log API Model

public struct APIFoodLog: Decodable, Identifiable {
    public let id: String
    public let loggedDate: String
    public let loggedAt: Date
    public let mealType: String
    public let mealName: String?
    public let entryMethod: String
    public let items: [APIFoodLogItem]
    public let totals: APIFoodLogTotals
    public let notes: String?
    public let mood: String?
    public let hungerLevel: Int?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case loggedDate, loggedAt, mealType, mealName, entryMethod
        case items, totals, notes, mood, hungerLevel
    }
}

public struct APIFoodLogItem: Decodable, Identifiable {
    public let id: String
    public let foodId: String?
    public let quantity: Double
    public let servingMultiplier: Double
    public let nutrition: APIItemNutrition
    public let quickAddName: String?
    public let quickAddDescription: String?
    public let foodSnapshot: APIFoodSnapshot

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case foodId, quantity, servingMultiplier, nutrition
        case quickAddName, quickAddDescription, foodSnapshot
    }
}

public struct APIItemNutrition: Decodable {
    public let calories: Double
    public let proteinG: Double
    public let carbsG: Double
    public let fatG: Double
    public let fiberG: Double?
    public let sugarG: Double?
    public let sodiumMg: Double?
}

public struct APIFoodSnapshot: Decodable {
    public let name: String
    public let brand: String?
    public let servingDescription: String?
}

public struct APIFoodLogTotals: Decodable {
    public let calories: Double
    public let proteinG: Double
    public let carbsG: Double
    public let fatG: Double
    public let fiberG: Double
    public let sugarG: Double
    public let sodiumMg: Double
    public let itemCount: Int
}

// MARK: - Food Search Response

public struct FoodSearchResponse: Decodable {
    public let data: [APIFood]
    public let query: String
}

public struct APIFood: Decodable, Identifiable {
    public let id: String
    public let source: String
    public let externalId: String?
    public let name: String
    public let brand: String?
    public let description: String?
    public let category: String?
    public let servingSize: Double
    public let servingUnit: String
    public let servingDescription: String?
    public let nutrition: APINutrition

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case source, externalId, name, brand, description, category
        case servingSize, servingUnit, servingDescription, nutrition
    }
}

public struct APINutrition: Decodable {
    public let calories: Double
    public let proteinG: Double
    public let carbsG: Double
    public let fatG: Double
    public let fiberG: Double?
    public let sugarG: Double?
    public let sodiumMg: Double?
}

// MARK: - Recent Foods Response

public struct RecentFoodsResponse: Decodable {
    public let data: [RecentFood]
}

public struct RecentFood: Decodable, Identifiable {
    public let name: String
    public let brand: String?
    public let nutrition: APIItemNutrition
    public let foodId: String?
    public let lastUsed: Date
    public let useCount: Int

    public var id: String { name + (brand ?? "") }
}

// MARK: - Create Food Log Request

public struct CreateFoodLogRequest: Encodable {
    public let loggedDate: String
    public let loggedAt: Date
    public let mealType: String
    public let entryMethod: String
    public let items: [CreateFoodLogItem]
    public let notes: String?

    public init(
        loggedDate: String,
        loggedAt: Date = Date(),
        mealType: String,
        entryMethod: String = "manual",
        items: [CreateFoodLogItem],
        notes: String? = nil
    ) {
        self.loggedDate = loggedDate
        self.loggedAt = loggedAt
        self.mealType = mealType
        self.entryMethod = entryMethod
        self.items = items
        self.notes = notes
    }
}

public struct CreateFoodLogItem: Encodable {
    public let foodId: String?
    public let quantity: Double
    public let servingMultiplier: Double
    public let nutrition: CreateItemNutrition
    public let foodSnapshot: CreateFoodSnapshot

    public init(
        foodId: String? = nil,
        quantity: Double = 1,
        servingMultiplier: Double = 1,
        nutrition: CreateItemNutrition,
        foodSnapshot: CreateFoodSnapshot
    ) {
        self.foodId = foodId
        self.quantity = quantity
        self.servingMultiplier = servingMultiplier
        self.nutrition = nutrition
        self.foodSnapshot = foodSnapshot
    }
}

public struct CreateItemNutrition: Encodable {
    public let calories: Double
    public let proteinG: Double
    public let carbsG: Double
    public let fatG: Double
    public let fiberG: Double?
    public let sugarG: Double?
    public let sodiumMg: Double?

    public init(
        calories: Double,
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        fiberG: Double? = nil,
        sugarG: Double? = nil,
        sodiumMg: Double? = nil
    ) {
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.fiberG = fiberG
        self.sugarG = sugarG
        self.sodiumMg = sodiumMg
    }
}

public struct CreateFoodSnapshot: Encodable {
    public let name: String
    public let brand: String?
    public let servingDescription: String?

    public init(name: String, brand: String? = nil, servingDescription: String? = nil) {
        self.name = name
        self.brand = brand
        self.servingDescription = servingDescription
    }
}

// MARK: - Photo Analysis

public struct PhotoAnalysisRequest: Encodable {
    public let image: String  // Base64 encoded
    public let mimeType: String

    public init(image: String, mimeType: String = "image/jpeg") {
        self.image = image
        self.mimeType = mimeType
    }
}

public struct PhotoAnalysisResponse: Decodable {
    public let success: Bool
    public let provider: String
    public let confidence: Double
    public let items: [AnalyzedFoodItem]
}

public struct AnalyzedFoodItem: Decodable, Identifiable {
    public let name: String
    public let quantity: Double
    public let unit: String
    public let nutrition: AnalyzedNutrition
    public let confidence: Double

    public var id: String { "\(name)-\(quantity)-\(unit)" }
}

public struct AnalyzedNutrition: Decodable {
    public let calories: Double
    public let proteinG: Double
    public let carbsG: Double
    public let fatG: Double
}

// MARK: - Barcode Lookup

public struct BarcodeLookupResponse: Decodable {
    public let success: Bool
    public let product: BarcodeProduct?
    public let error: String?
}

public struct BarcodeProduct: Decodable {
    public let barcode: String
    public let name: String
    public let brand: String?
    public let servingSize: String?
    public let servingUnit: String?
    public let nutrition: BarcodeNutrition
    public let imageUrl: String?
    public let source: String
}

public struct BarcodeNutrition: Decodable {
    public let calories: Double
    public let proteinG: Double
    public let carbsG: Double
    public let fatG: Double
    public let fiberG: Double?
    public let sugarG: Double?
    public let sodiumMg: Double?
}
