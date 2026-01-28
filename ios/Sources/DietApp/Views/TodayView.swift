import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Today dashboard view showing daily nutrition summary and meal logs
public struct TodayView: View {

    // MARK: - Properties

    @StateObject private var viewModel: TodayViewModel
    @EnvironmentObject private var environment: AppEnvironment

    // MARK: - Initialization

    public init(viewModel: TodayViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Nutrition summary card
                    nutritionSummaryCard

                    // Meals section
                    mealsSection
                }
                .padding()
            }
            .background(Color.groupedBackground)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showAddFood()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .refreshable {
                await viewModel.loadTodayData()
            }
            .task {
                await viewModel.loadTodayData()
            }
            .overlay {
                if viewModel.isLoading && viewModel.apiLogs.isEmpty {
                    ProgressView()
                }
            }
            .sheet(isPresented: $viewModel.showingAddFood) {
                if let mealType = viewModel.selectedMealType {
                    AddFoodView(
                        mealType: mealType,
                        viewModel: environment.makeAddFoodViewModel()
                    ) {
                        Task {
                            await viewModel.loadTodayData()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Nutrition Summary Card

    private var nutritionSummaryCard: some View {
        VStack(spacing: 16) {
            // Calories
            VStack(spacing: 8) {
                Text("\(Int(viewModel.nutrition.calories))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))

                if let targets = viewModel.targets {
                    Text("of \(Int(targets.calories)) cal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("calories consumed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Macros
            HStack(spacing: 24) {
                macroItem(
                    title: "Protein",
                    value: viewModel.nutrition.protein,
                    unit: "g",
                    color: .blue
                )

                macroItem(
                    title: "Carbs",
                    value: viewModel.nutrition.carbs,
                    unit: "g",
                    color: .orange
                )

                macroItem(
                    title: "Fat",
                    value: viewModel.nutrition.fat,
                    unit: "g",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func macroItem(
        title: String,
        value: Double,
        unit: String,
        color: Color
    ) -> some View {
        VStack(spacing: 4) {
            Text("\(Int(value))\(unit)")
                .font(.headline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Meals Section

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meals")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(FoodLogRecord.MealType.allCases) { mealType in
                mealCard(for: mealType)
            }
        }
    }

    private func mealCard(for mealType: FoodLogRecord.MealType) -> some View {
        let logsForMeal = viewModel.logs(for: mealType)
        let mealCalories = viewModel.calories(for: mealType)

        return VStack(alignment: .leading, spacing: 12) {
            // Meal header
            HStack {
                Image(systemName: mealType.icon)
                    .foregroundStyle(.secondary)

                Text(mealType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(Int(mealCalories)) cal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    viewModel.showAddFood(for: mealType)
                } label: {
                    Image(systemName: "plus")
                        .font(.body)
                        .foregroundStyle(.blue)
                }
            }

            // Logged items
            if logsForMeal.isEmpty {
                Text("No items logged")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(logsForMeal) { log in
                    apiLogRow(log)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func apiLogRow(_ log: APIFoodLog) -> some View {
        VStack(spacing: 4) {
            ForEach(log.items) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.foodSnapshot.name)
                            .font(.subheadline)

                        if let serving = item.foodSnapshot.servingDescription {
                            Text(serving)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Text("\(Int(item.nutrition.calories)) cal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Color Extensions

extension Color {
    #if canImport(UIKit)
    static let groupedBackground = Color(UIColor.systemGroupedBackground)
    static let cardBackground = Color(UIColor.systemBackground)
    static let searchBarBackground = Color(UIColor.systemGray6)
    #else
    static let groupedBackground = Color(NSColor.windowBackgroundColor)
    static let cardBackground = Color(NSColor.controlBackgroundColor)
    static let searchBarBackground = Color(NSColor.controlBackgroundColor)
    #endif
}

// MARK: - Preview

#Preview {
    TodayView(
        viewModel: TodayViewModel(
            foodLogRepository: FoodLogRepository(databaseManager: DatabaseManager()),
            foodService: FoodService(apiClient: APIClient(baseURL: URL(string: "http://localhost:3000/api")!))
        )
    )
    .environmentObject(AppEnvironment.shared)
}
