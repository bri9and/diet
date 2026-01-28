import Foundation

/// View model for AddFoodView
@MainActor
public final class AddFoodViewModel: ObservableObject {

    // MARK: - Published State

    @Published public var searchQuery: String = ""
    @Published public var searchResults: [APIFood] = []
    @Published public var recentFoods: [RecentFood] = []
    @Published public var isSearching: Bool = false
    @Published public var isLoadingRecent: Bool = false
    @Published public var showError: Bool = false
    @Published public var errorMessage: String?

    // MARK: - Dependencies

    private let foodService: FoodService

    // MARK: - Initialization

    public init(foodService: FoodService) {
        self.foodService = foodService
    }

    // MARK: - Load Recent Foods

    public func loadRecentFoods() async {
        isLoadingRecent = true

        do {
            let response = try await foodService.fetchRecentFoods()
            recentFoods = response.data
        } catch {
            print("Failed to load recent foods: \(error)")
            // Don't show error for recent foods - just show empty state
        }

        isLoadingRecent = false
    }

    // MARK: - Search

    public func search() async {
        guard searchQuery.count >= 2 else { return }

        isSearching = true

        do {
            let response = try await foodService.searchFoods(query: searchQuery)
            searchResults = response.data
        } catch {
            showError(error)
        }

        isSearching = false
    }

    // MARK: - Log Food

    public func logFood(_ food: APIFood, mealType: FoodLogRecord.MealType) async {
        let today = formatDate(Date())

        let request = CreateFoodLogRequest(
            loggedDate: today,
            mealType: mealType.rawValue,
            items: [
                CreateFoodLogItem(
                    foodId: food.id,
                    quantity: 1,
                    servingMultiplier: 1,
                    nutrition: CreateItemNutrition(
                        calories: food.nutrition.calories,
                        proteinG: food.nutrition.proteinG,
                        carbsG: food.nutrition.carbsG,
                        fatG: food.nutrition.fatG,
                        fiberG: food.nutrition.fiberG,
                        sugarG: food.nutrition.sugarG,
                        sodiumMg: food.nutrition.sodiumMg
                    ),
                    foodSnapshot: CreateFoodSnapshot(
                        name: food.name,
                        brand: food.brand,
                        servingDescription: food.servingDescription
                    )
                )
            ]
        )

        do {
            _ = try await foodService.createFoodLog(request)
        } catch {
            showError(error)
        }
    }

    public func logRecentFood(_ food: RecentFood, mealType: FoodLogRecord.MealType) async {
        let today = formatDate(Date())

        let request = CreateFoodLogRequest(
            loggedDate: today,
            mealType: mealType.rawValue,
            items: [
                CreateFoodLogItem(
                    foodId: food.foodId,
                    quantity: 1,
                    servingMultiplier: 1,
                    nutrition: CreateItemNutrition(
                        calories: food.nutrition.calories,
                        proteinG: food.nutrition.proteinG,
                        carbsG: food.nutrition.carbsG,
                        fatG: food.nutrition.fatG,
                        fiberG: food.nutrition.fiberG,
                        sugarG: food.nutrition.sugarG,
                        sodiumMg: food.nutrition.sodiumMg
                    ),
                    foodSnapshot: CreateFoodSnapshot(
                        name: food.name,
                        brand: food.brand
                    )
                )
            ]
        )

        do {
            _ = try await foodService.createFoodLog(request)
        } catch {
            showError(error)
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func showError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}
