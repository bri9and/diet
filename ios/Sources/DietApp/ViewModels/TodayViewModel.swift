import Foundation
import Combine
import Clerk

/// View model for the Today dashboard
/// Manages loading and displaying today's food logs and nutrition summary
@MainActor
public final class TodayViewModel: ObservableObject {

    // MARK: - Published State

    @Published public private(set) var todayLogs: [FoodLogRecord] = []
    @Published public private(set) var apiLogs: [APIFoodLog] = []
    @Published public private(set) var nutrition: NutritionSummary = .empty
    @Published public private(set) var targets: NutritionTargets?
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var error: Error?

    @Published public var showingAddFood: Bool = false
    @Published public var selectedMealType: FoodLogRecord.MealType?

    // MARK: - Dependencies

    private let foodLogRepository: FoodLogRepository
    private let foodService: FoodService

    // MARK: - Initialization

    public init(
        foodLogRepository: FoodLogRepository,
        foodService: FoodService
    ) {
        self.foodLogRepository = foodLogRepository
        self.foodService = foodService
    }

    // MARK: - Data Loading

    /// Load today's food logs and calculate nutrition summary
    public func loadTodayData() async {
        isLoading = true
        error = nil

        do {
            // Fetch from API
            let summary = try await foodService.fetchDailySummary()

            // Update nutrition from API response
            nutrition = NutritionSummary(
                calories: summary.totals.calories,
                protein: summary.totals.proteinG,
                carbs: summary.totals.carbsG,
                fat: summary.totals.fatG,
                fiber: summary.totals.fiberG
            )

            targets = summary.targets

            // Flatten meals into a single array
            var allLogs: [APIFoodLog] = []
            allLogs.append(contentsOf: summary.meals.breakfast)
            allLogs.append(contentsOf: summary.meals.lunch)
            allLogs.append(contentsOf: summary.meals.dinner)
            allLogs.append(contentsOf: summary.meals.snack)
            apiLogs = allLogs

        } catch {
            self.error = error
            print("Failed to load today's data: \(error)")

            // Fallback to local data if available
            if let userId = Clerk.shared.user?.id {
                do {
                    let logs = try await foodLogRepository.fetchToday(userId: userId)
                    todayLogs = logs
                    nutrition = try await foodLogRepository.dailyNutrition(
                        userId: userId,
                        date: Date()
                    )
                } catch {
                    print("Also failed to load local data: \(error)")
                }
            }
        }

        isLoading = false
    }

    /// Refresh data
    public func refresh() async {
        await loadTodayData()
    }

    // MARK: - Actions

    /// Show the add food sheet
    public func showAddFood(for mealType: FoodLogRecord.MealType? = nil) {
        selectedMealType = mealType ?? suggestedMealType()
        showingAddFood = true
    }

    /// Delete a food log entry
    public func deleteLog(_ log: APIFoodLog) async {
        do {
            try await foodService.deleteFoodLog(id: log.id)

            // Remove from local state
            apiLogs.removeAll { $0.id == log.id }

            // Recalculate nutrition
            nutrition = calculateNutrition(from: apiLogs)
        } catch {
            self.error = error
            print("Failed to delete log: \(error)")
        }
    }

    /// Delete a specific item from a food log
    public func deleteItem(_ item: APIFoodLogItem, from log: APIFoodLog) async {
        do {
            try await foodService.removeItemFromLog(logId: log.id, itemId: item.id, allItems: log.items)

            // Update local state
            if log.items.count == 1 {
                // Last item - remove entire log
                apiLogs.removeAll { $0.id == log.id }
            } else {
                // Update the log's items
                if let index = apiLogs.firstIndex(where: { $0.id == log.id }) {
                    // Reload from API to get updated totals
                    await loadTodayData()
                    return
                }
            }

            // Recalculate nutrition
            nutrition = calculateNutrition(from: apiLogs)
        } catch {
            self.error = error
            print("Failed to delete item: \(error)")
        }
    }

    // MARK: - Computed Properties

    /// Get logs for a specific meal type
    public func logs(for mealType: FoodLogRecord.MealType) -> [APIFoodLog] {
        apiLogs.filter { $0.mealType == mealType.rawValue }
    }

    /// Get total calories for a meal type
    public func calories(for mealType: FoodLogRecord.MealType) -> Double {
        logs(for: mealType).reduce(0) { $0 + $1.totals.calories }
    }

    // MARK: - Helpers

    /// Suggest the current meal type based on time of day
    private func suggestedMealType() -> FoodLogRecord.MealType {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<11:
            return .breakfast
        case 11..<15:
            return .lunch
        case 15..<21:
            return .dinner
        default:
            return .snack
        }
    }

    /// Calculate nutrition summary from API logs
    private func calculateNutrition(from logs: [APIFoodLog]) -> NutritionSummary {
        NutritionSummary(
            calories: logs.reduce(0) { $0 + $1.totals.calories },
            protein: logs.reduce(0) { $0 + $1.totals.proteinG },
            carbs: logs.reduce(0) { $0 + $1.totals.carbsG },
            fat: logs.reduce(0) { $0 + $1.totals.fatG },
            fiber: logs.reduce(0) { $0 + $1.totals.fiberG }
        )
    }
}
