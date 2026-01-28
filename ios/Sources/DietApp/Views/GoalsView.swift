import SwiftUI

/// View for setting and viewing nutrition goals
public struct GoalsView: View {

    // MARK: - Properties

    @StateObject private var viewModel: GoalsViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    public init(foodService: FoodService) {
        _viewModel = StateObject(wrappedValue: GoalsViewModel(foodService: foodService))
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Goal type selector
                        goalTypeSection

                        // Daily targets
                        dailyTargetsSection

                        // Weekly progress
                        if !viewModel.weeklyProgress.isEmpty {
                            weeklyProgressSection
                        }
                    }
                }
                .padding()
            }
            .background(Color.groupedBackground)
            .navigationTitle("Goals")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.hasChanges {
                        Button("Save") {
                            Task {
                                await viewModel.saveGoals()
                            }
                        }
                        .disabled(viewModel.isSaving)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
        .task {
            await viewModel.loadGoals()
            await viewModel.loadProgress()
        }
    }

    // MARK: - Goal Type Section

    private var goalTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Goal")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(GoalType.allCases, id: \.self) { goalType in
                    goalTypeButton(goalType)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func goalTypeButton(_ goalType: GoalType) -> some View {
        Button {
            viewModel.goalType = goalType
        } label: {
            VStack(spacing: 8) {
                Image(systemName: goalType.icon)
                    .font(.title2)

                Text(goalType.displayName)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.goalType == goalType ? Color.blue : Color.searchBarBackground)
            .foregroundStyle(viewModel.goalType == goalType ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Daily Targets Section

    private var dailyTargetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Targets")
                .font(.headline)

            // Calories
            nutrientEditor(
                label: "Calories",
                value: $viewModel.dailyCalories,
                unit: "cal",
                range: 1000...5000,
                step: 50,
                color: .orange
            )

            Divider()

            // Protein
            nutrientEditor(
                label: "Protein",
                value: $viewModel.dailyProtein,
                unit: "g",
                range: 20...300,
                step: 5,
                color: .red
            )

            Divider()

            // Carbs
            nutrientEditor(
                label: "Carbs",
                value: $viewModel.dailyCarbs,
                unit: "g",
                range: 50...500,
                step: 10,
                color: .blue
            )

            Divider()

            // Fat
            nutrientEditor(
                label: "Fat",
                value: $viewModel.dailyFat,
                unit: "g",
                range: 20...200,
                step: 5,
                color: .yellow
            )
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func nutrientEditor(
        label: String,
        value: Binding<Double>,
        unit: String,
        range: ClosedRange<Double>,
        step: Double,
        color: Color
    ) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(.subheadline)

            Spacer()

            HStack(spacing: 12) {
                Button {
                    if value.wrappedValue > range.lowerBound {
                        value.wrappedValue -= step
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                Text("\(Int(value.wrappedValue))\(unit)")
                    .font(.headline)
                    .monospacedDigit()
                    .frame(minWidth: 70)

                Button {
                    if value.wrappedValue < range.upperBound {
                        value.wrappedValue += step
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    // MARK: - Weekly Progress Section

    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.daysTracked) days tracked")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Average stats
            HStack(spacing: 16) {
                averageStat(
                    label: "Avg Calories",
                    value: viewModel.weeklyAverage.calories,
                    goal: Int(viewModel.dailyCalories),
                    unit: ""
                )

                averageStat(
                    label: "Avg Protein",
                    value: viewModel.weeklyAverage.protein,
                    goal: Int(viewModel.dailyProtein),
                    unit: "g"
                )
            }

            // Daily bars
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(viewModel.weeklyProgress, id: \.date) { day in
                    VStack(spacing: 4) {
                        // Progress bar
                        GeometryReader { geometry in
                            let height = geometry.size.height
                            let fillHeight = min(CGFloat(day.caloriePercentage) / 100.0, 1.0) * height

                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(progressColor(day.caloriePercentage))
                                    .frame(height: fillHeight)
                            }
                        }
                        .frame(height: 60)

                        // Day label
                        Text(dayLabel(day.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func averageStat(label: String, value: Int, goal: Int, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("of \(goal)\(unit) goal")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.searchBarBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func progressColor(_ percentage: Int) -> Color {
        if percentage < 80 { return .blue }
        if percentage <= 110 { return .green }
        return .orange
    }

    private func dayLabel(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return "" }

        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Goal Type

public enum GoalType: String, CaseIterable {
    case lose
    case maintain
    case gain

    var displayName: String {
        switch self {
        case .lose: return "Lose"
        case .maintain: return "Maintain"
        case .gain: return "Gain"
        }
    }

    var icon: String {
        switch self {
        case .lose: return "arrow.down.circle"
        case .maintain: return "equal.circle"
        case .gain: return "arrow.up.circle"
        }
    }
}

// MARK: - View Model

@MainActor
public final class GoalsViewModel: ObservableObject {

    @Published public var goalType: GoalType = .maintain
    @Published public var dailyCalories: Double = 2000
    @Published public var dailyProtein: Double = 50
    @Published public var dailyCarbs: Double = 250
    @Published public var dailyFat: Double = 65

    @Published public var weeklyProgress: [DayProgress] = []
    @Published public var weeklyAverage: (calories: Int, protein: Int) = (0, 0)
    @Published public var daysTracked: Int = 0

    @Published public var isLoading = false
    @Published public var isSaving = false
    @Published public var showError = false
    @Published public var errorMessage: String?

    private var originalGoals: (GoalType, Double, Double, Double, Double)?
    private let foodService: FoodService

    public var hasChanges: Bool {
        guard let original = originalGoals else { return false }
        return original != (goalType, dailyCalories, dailyProtein, dailyCarbs, dailyFat)
    }

    public init(foodService: FoodService) {
        self.foodService = foodService
    }

    public func loadGoals() async {
        isLoading = true

        do {
            let response = try await foodService.getGoals()
            goalType = GoalType(rawValue: response.goals.goalType) ?? .maintain
            dailyCalories = Double(response.goals.dailyCalories)
            dailyProtein = Double(response.goals.dailyProteinG)
            dailyCarbs = Double(response.goals.dailyCarbsG)
            dailyFat = Double(response.goals.dailyFatG)

            originalGoals = (goalType, dailyCalories, dailyProtein, dailyCarbs, dailyFat)
        } catch {
            showError(message: "Could not load goals")
        }

        isLoading = false
    }

    public func loadProgress() async {
        do {
            let response = try await foodService.getProgress()
            weeklyProgress = response.progress
            weeklyAverage = (response.weeklyAverage.calories, response.weeklyAverage.protein)
            daysTracked = response.daysTracked
        } catch {
            // Silent fail for progress - not critical
        }
    }

    public func saveGoals() async {
        isSaving = true

        do {
            let request = UpdateGoalsRequest(
                dailyCalories: Int(dailyCalories),
                dailyProteinG: Int(dailyProtein),
                dailyCarbsG: Int(dailyCarbs),
                dailyFatG: Int(dailyFat),
                goalType: goalType.rawValue
            )
            _ = try await foodService.updateGoals(request)
            originalGoals = (goalType, dailyCalories, dailyProtein, dailyCarbs, dailyFat)
        } catch {
            showError(message: "Could not save goals")
        }

        isSaving = false
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
