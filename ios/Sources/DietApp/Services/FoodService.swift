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
