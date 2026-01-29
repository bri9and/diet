import Foundation

// MARK: - Daily Summary Response

public struct DailySummaryResponse: Decodable {
    public let date: String
    public let totals: DailyTotals
    public let meals: MealsByType
    public let targets: NutritionTargets
}

public struct DailyTotals: Decodable {
    // Macros
    public let calories: Double
    public let proteinG: Double
    public let carbsG: Double
    public let fatG: Double
    public let fiberG: Double
    public let sugarG: Double
    public let sodiumMg: Double
    public let mealCount: Int
    public let itemCount: Int

    // Vitamins
    public let vitaminAMcg: Double?
    public let vitaminCMg: Double?
    public let vitaminDMcg: Double?
    public let vitaminEMg: Double?
    public let vitaminKMcg: Double?
    public let vitaminB1Mg: Double?
    public let vitaminB2Mg: Double?
    public let vitaminB3Mg: Double?
    public let vitaminB5Mg: Double?
    public let vitaminB6Mg: Double?
    public let vitaminB9Mcg: Double?
    public let vitaminB12Mcg: Double?
    public let cholineMg: Double?

    // Minerals
    public let calciumMg: Double?
    public let ironMg: Double?
    public let magnesiumMg: Double?
    public let phosphorusMg: Double?
    public let potassiumMg: Double?
    public let zincMg: Double?
    public let copperMg: Double?
    public let manganeseMg: Double?
    public let seleniumMcg: Double?

    // Lipids
    public let saturatedFatG: Double?
    public let monounsaturatedFatG: Double?
    public let polyunsaturatedFatG: Double?
    public let transFatG: Double?
    public let cholesterolMg: Double?

    /// Convert to FullNutrition for micronutrient view
    public func toFullNutrition() -> FullNutrition {
        FullNutrition(
            calories: calories,
            proteinG: proteinG,
            fatG: fatG,
            carbsG: carbsG,
            fiberG: fiberG,
            sugarG: sugarG,
            vitaminAMcg: vitaminAMcg,
            vitaminCMg: vitaminCMg,
            vitaminDMcg: vitaminDMcg,
            vitaminEMg: vitaminEMg,
            vitaminKMcg: vitaminKMcg,
            vitaminB1Mg: vitaminB1Mg,
            vitaminB2Mg: vitaminB2Mg,
            vitaminB3Mg: vitaminB3Mg,
            vitaminB5Mg: vitaminB5Mg,
            vitaminB6Mg: vitaminB6Mg,
            vitaminB9Mcg: vitaminB9Mcg,
            vitaminB12Mcg: vitaminB12Mcg,
            cholineMg: cholineMg,
            calciumMg: calciumMg,
            ironMg: ironMg,
            magnesiumMg: magnesiumMg,
            phosphorusMg: phosphorusMg,
            potassiumMg: potassiumMg,
            sodiumMg: sodiumMg,
            zincMg: zincMg,
            copperMg: copperMg,
            manganeseMg: manganeseMg,
            seleniumMcg: seleniumMcg,
            saturatedFatG: saturatedFatG,
            monounsaturatedFatG: monounsaturatedFatG,
            polyunsaturatedFatG: polyunsaturatedFatG,
            transFatG: transFatG,
            cholesterolMg: cholesterolMg
        )
    }
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
    public var quantity: Double
    public let unit: String
    public let nutrition: AnalyzedNutrition
    public let confidence: Double

    public let id = UUID()

    enum CodingKeys: String, CodingKey {
        case name, quantity, unit, nutrition, confidence
    }
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

// MARK: - Voice Food Parsing

public struct ParseFoodRequest: Encodable {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

public struct VoiceParseFoodResponse: Decodable {
    public let success: Bool
    public let provider: String
    public let confidence: Double
    public let items: [AnalyzedFoodItem]
}

// MARK: - Goals

public struct GoalsResponse: Decodable {
    public let success: Bool
    public let goals: UserGoals
}

public struct UserGoals: Decodable {
    public let dailyCalories: Int
    public let dailyProteinG: Int
    public let dailyCarbsG: Int
    public let dailyFatG: Int
    public let targetWeight: Double?
    public let targetWeightUnit: String?
    public let activityLevel: String?
    public let goalType: String
    public let weeklyGoalKg: Double?
}

public struct UpdateGoalsRequest: Encodable {
    public let dailyCalories: Int
    public let dailyProteinG: Int
    public let dailyCarbsG: Int
    public let dailyFatG: Int
    public let goalType: String

    public init(
        dailyCalories: Int,
        dailyProteinG: Int,
        dailyCarbsG: Int,
        dailyFatG: Int,
        goalType: String
    ) {
        self.dailyCalories = dailyCalories
        self.dailyProteinG = dailyProteinG
        self.dailyCarbsG = dailyCarbsG
        self.dailyFatG = dailyFatG
        self.goalType = goalType
    }
}

// MARK: - Progress

public struct ProgressResponse: Decodable {
    public let success: Bool
    public let goals: ProgressGoals
    public let progress: [DayProgress]
    public let weeklyAverage: WeeklyAverage
    public let daysTracked: Int
}

public struct ProgressGoals: Decodable {
    public let dailyCalories: Int
    public let dailyProteinG: Int
    public let dailyCarbsG: Int
    public let dailyFatG: Int
    public let goalType: String
}

public struct WeeklyAverage: Decodable {
    public let calories: Int
    public let protein: Int
    public let carbs: Int
    public let fat: Int
}

public struct DayProgress: Decodable {
    public let date: String
    public let calories: NutrientProgress
    public let protein: NutrientProgress
    public let carbs: NutrientProgress
    public let fat: NutrientProgress

    public var caloriePercentage: Int { calories.percentage }
}

public struct NutrientProgress: Decodable {
    public let consumed: Int
    public let goal: Int
    public let percentage: Int
}

// MARK: - Profile

public struct ProfileResponse: Decodable {
    public let success: Bool
    public let profile: UserProfile
}

public struct UserProfile: Decodable {
    public let displayName: String?
    public let email: String?
    public let avatarUrl: String?
    public let heightCm: Double?
    public let currentWeightKg: Double?
    public let targetWeightKg: Double?
    public let birthDate: String?
    public let gender: String?
    public let activityLevel: String?
    public let onboardingCompleted: Bool?
    public let lastSyncAt: String?
}

public struct UpdateProfileRequest: Encodable {
    public let heightCm: Double?
    public let currentWeightKg: Double?
    public let targetWeightKg: Double?
    public let birthDate: String?
    public let gender: String?
    public let activityLevel: String?
    public let onboardingCompleted: Bool?

    public init(
        heightCm: Double? = nil,
        currentWeightKg: Double? = nil,
        targetWeightKg: Double? = nil,
        birthDate: String? = nil,
        gender: String? = nil,
        activityLevel: String? = nil,
        onboardingCompleted: Bool? = nil
    ) {
        self.heightCm = heightCm
        self.currentWeightKg = currentWeightKg
        self.targetWeightKg = targetWeightKg
        self.birthDate = birthDate
        self.gender = gender
        self.activityLevel = activityLevel
        self.onboardingCompleted = onboardingCompleted
    }
}

// MARK: - Calculate Goals

public struct CalculateGoalsRequest: Encodable {
    public let heightCm: Double
    public let currentWeightKg: Double
    public let targetWeightKg: Double?
    public let birthDate: String
    public let gender: String
    public let activityLevel: String
    public let goalType: String?

    public init(
        heightCm: Double,
        currentWeightKg: Double,
        targetWeightKg: Double?,
        birthDate: String,
        gender: String,
        activityLevel: String,
        goalType: String? = nil
    ) {
        self.heightCm = heightCm
        self.currentWeightKg = currentWeightKg
        self.targetWeightKg = targetWeightKg
        self.birthDate = birthDate
        self.gender = gender
        self.activityLevel = activityLevel
        self.goalType = goalType
    }
}

public struct CalculateGoalsResponse: Decodable {
    public let success: Bool
    public let calculations: GoalCalculations
    public let goals: UserGoals
}

public struct GoalCalculations: Decodable {
    public let age: Int
    public let bmr: Int
    public let tdee: Int
    public let dailyCalories: Int
    public let dailyProteinG: Int
    public let dailyCarbsG: Int
    public let dailyFatG: Int
    public let goalType: String
    public let weeklyGoalKg: Double
}

// MARK: - USDA Food Search

public struct USDASearchResponse: Decodable {
    public let success: Bool
    public let data: [USDAFood]
    public let query: String
    public let totalHits: Int
    public let currentPage: Int
    public let totalPages: Int
}

public struct USDAFood: Decodable, Identifiable {
    public let id: String
    public let fdcId: Int
    public let source: String
    public let dataType: String
    public let name: String
    public let brand: String?
    public let barcode: String?
    public let category: String?
    public let servingSize: Double
    public let servingUnit: String
    public let servingDescription: String?
    public let nutrition: FullNutrition

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case fdcId, source, dataType, name, brand, barcode, category
        case servingSize, servingUnit, servingDescription, nutrition
    }
}

public struct USDAFoodDetailResponse: Decodable {
    public let success: Bool
    public let data: USDAFoodDetail
}

public struct USDAFoodDetail: Decodable, Identifiable {
    public let id: String
    public let fdcId: Int
    public let source: String
    public let dataType: String
    public let name: String
    public let brand: String?
    public let barcode: String?
    public let category: String?
    public let ingredients: String?
    public let servingSize: Double
    public let servingUnit: String
    public let servingDescription: String?
    public let nutrition: FullNutrition
    public let rawNutrients: [RawNutrient]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case fdcId, source, dataType, name, brand, barcode, category
        case ingredients, servingSize, servingUnit, servingDescription
        case nutrition, rawNutrients
    }
}

public struct RawNutrient: Decodable, Identifiable {
    public let id: Int
    public let name: String
    public let amount: Double
    public let unit: String
}

// MARK: - Full Nutrition with Micronutrients

public struct FullNutrition: Decodable {
    // Macros (required)
    public let calories: Double
    public let proteinG: Double
    public let fatG: Double
    public let carbsG: Double

    // Macros (optional)
    public let fiberG: Double?
    public let sugarG: Double?

    // Vitamins
    public let vitaminAMcg: Double?
    public let vitaminCMg: Double?
    public let vitaminDMcg: Double?
    public let vitaminEMg: Double?
    public let vitaminKMcg: Double?
    public let vitaminB1Mg: Double?
    public let vitaminB2Mg: Double?
    public let vitaminB3Mg: Double?
    public let vitaminB5Mg: Double?
    public let vitaminB6Mg: Double?
    public let vitaminB9Mcg: Double?
    public let vitaminB12Mcg: Double?
    public let cholineMg: Double?

    // Minerals
    public let calciumMg: Double?
    public let ironMg: Double?
    public let magnesiumMg: Double?
    public let phosphorusMg: Double?
    public let potassiumMg: Double?
    public let sodiumMg: Double?
    public let zincMg: Double?
    public let copperMg: Double?
    public let manganeseMg: Double?
    public let seleniumMcg: Double?

    // Lipids
    public let saturatedFatG: Double?
    public let monounsaturatedFatG: Double?
    public let polyunsaturatedFatG: Double?
    public let transFatG: Double?
    public let cholesterolMg: Double?
}

// MARK: - RDA (Recommended Daily Allowances)

public struct RDAResponse: Decodable {
    public let success: Bool
    public let data: [String: RDAValue]
}

public struct RDAValue: Decodable {
    public let value: Double
    public let unit: String
    public let name: String
}

// MARK: - RDA Constants for Local Use

public struct RDAConstants {
    // Macros
    public static let calories: Double = 2000
    public static let proteinG: Double = 50
    public static let fatG: Double = 78
    public static let carbsG: Double = 275
    public static let fiberG: Double = 28
    public static let sugarG: Double = 50

    // Vitamins
    public static let vitaminAMcg: Double = 900
    public static let vitaminCMg: Double = 90
    public static let vitaminDMcg: Double = 20
    public static let vitaminEMg: Double = 15
    public static let vitaminKMcg: Double = 120
    public static let vitaminB1Mg: Double = 1.2
    public static let vitaminB2Mg: Double = 1.3
    public static let vitaminB3Mg: Double = 16
    public static let vitaminB5Mg: Double = 5
    public static let vitaminB6Mg: Double = 1.7
    public static let vitaminB9Mcg: Double = 400
    public static let vitaminB12Mcg: Double = 2.4
    public static let cholineMg: Double = 550

    // Minerals
    public static let calciumMg: Double = 1300
    public static let ironMg: Double = 18
    public static let magnesiumMg: Double = 420
    public static let phosphorusMg: Double = 1250
    public static let potassiumMg: Double = 4700
    public static let sodiumMg: Double = 2300
    public static let zincMg: Double = 11
    public static let copperMg: Double = 0.9
    public static let manganeseMg: Double = 2.3
    public static let seleniumMcg: Double = 55

    // Lipids
    public static let saturatedFatG: Double = 20
    public static let cholesterolMg: Double = 300
}
