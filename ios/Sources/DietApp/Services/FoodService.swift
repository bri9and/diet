import Foundation

/// Service for food-related API operations
public final class FoodService {

    // MARK: - Properties

    private let apiClient: APIClient

    // MARK: - Initialization

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Daily Summary

    /// Fetch daily nutrition summary
    public func fetchDailySummary(date: Date = Date()) async throws -> DailySummaryResponse {
        let dateString = formatDate(date)
        return try await apiClient.get(
            "/food-logs/summary",
            queryItems: [URLQueryItem(name: "date", value: dateString)]
        )
    }

    // MARK: - Food Logs

    /// Fetch food logs for a date
    public func fetchFoodLogs(date: Date) async throws -> FoodLogsResponse {
        let dateString = formatDate(date)
        return try await apiClient.get(
            "/food-logs",
            queryItems: [URLQueryItem(name: "date", value: dateString)]
        )
    }

    /// Create a new food log
    public func createFoodLog(_ request: CreateFoodLogRequest) async throws -> APIFoodLog {
        return try await apiClient.post("/food-logs", body: request)
    }

    /// Delete a food log
    public func deleteFoodLog(id: String) async throws {
        try await apiClient.delete("/food-logs/\(id)")
    }

    /// Remove a specific item from a food log
    /// If it's the last item, deletes the entire log
    public func removeItemFromLog(logId: String, itemId: String, allItems: [APIFoodLogItem]) async throws {
        let remainingItems = allItems.filter { $0.id != itemId }

        if remainingItems.isEmpty {
            // Delete the whole log if no items remain
            try await deleteFoodLog(id: logId)
        } else {
            // Update the log with remaining items
            let itemsPayload = remainingItems.map { item in
                [
                    "_id": item.id,
                    "foodId": item.foodId as Any,
                    "quantity": item.quantity,
                    "servingMultiplier": item.servingMultiplier,
                    "nutrition": [
                        "calories": item.nutrition.calories,
                        "proteinG": item.nutrition.proteinG,
                        "carbsG": item.nutrition.carbsG,
                        "fatG": item.nutrition.fatG,
                        "fiberG": item.nutrition.fiberG as Any,
                        "sugarG": item.nutrition.sugarG as Any,
                        "sodiumMg": item.nutrition.sodiumMg as Any
                    ],
                    "foodSnapshot": [
                        "name": item.foodSnapshot.name,
                        "brand": item.foodSnapshot.brand as Any,
                        "servingDescription": item.foodSnapshot.servingDescription as Any
                    ]
                ] as [String: Any]
            }

            let _: APIFoodLog = try await apiClient.patch("/food-logs/\(logId)", body: ["items": itemsPayload])
        }
    }

    // MARK: - Food Search

    /// Search foods database
    public func searchFoods(query: String, limit: Int = 20) async throws -> FoodSearchResponse {
        return try await apiClient.get(
            "/foods/search",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
    }

    /// Fetch recent foods for the user
    public func fetchRecentFoods(limit: Int = 20) async throws -> RecentFoodsResponse {
        return try await apiClient.get(
            "/foods/recent",
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
    }

    // MARK: - Photo Analysis

    /// Analyze a food photo using AI
    public func analyzePhoto(imageData: Data) async throws -> PhotoAnalysisResponse {
        let base64Image = imageData.base64EncodedString()
        let request = PhotoAnalysisRequest(image: base64Image, mimeType: "image/jpeg")
        return try await apiClient.post("/analyze-photo", body: request)
    }

    /// Look up a product by barcode
    public func lookupBarcode(_ barcode: String) async throws -> BarcodeLookupResponse {
        return try await apiClient.get("/barcode?code=\(barcode)")
    }

    /// Parse natural language food description
    public func parseFood(text: String) async throws -> VoiceParseFoodResponse {
        let request = ParseFoodRequest(text: text)
        return try await apiClient.post("/parse-food", body: request)
    }

    // MARK: - Goals

    /// Get user goals
    public func getGoals() async throws -> GoalsResponse {
        return try await apiClient.get("/goals")
    }

    /// Update user goals
    public func updateGoals(_ request: UpdateGoalsRequest) async throws -> GoalsResponse {
        return try await apiClient.put("/goals", body: request)
    }

    /// Get progress for last 7 days
    public func getProgress() async throws -> ProgressResponse {
        return try await apiClient.get("/progress")
    }

    // MARK: - Profile

    /// Get user profile
    public func getProfile() async throws -> ProfileResponse {
        return try await apiClient.get("/profile")
    }

    /// Update user profile
    public func updateProfile(_ request: UpdateProfileRequest) async throws -> ProfileResponse {
        return try await apiClient.put("/profile", body: request)
    }

    /// Calculate goals based on profile data
    public func calculateGoals(_ request: CalculateGoalsRequest) async throws -> CalculateGoalsResponse {
        return try await apiClient.post("/profile/calculate-goals", body: request)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Food Logs Response

public struct FoodLogsResponse: Decodable {
    public let data: [APIFoodLog]
    public let pagination: Pagination
}

public struct Pagination: Decodable {
    public let total: Int
    public let limit: Int
    public let offset: Int
    public let hasMore: Bool
}
