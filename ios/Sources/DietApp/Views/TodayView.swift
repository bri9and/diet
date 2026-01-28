import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Today dashboard view showing daily nutrition summary and meal logs
public struct TodayView: View {

    // MARK: - Properties

    @StateObject private var viewModel: TodayViewModel
    @EnvironmentObject private var environment: AppEnvironment
    @State private var showQuickAdd = false

    // MARK: - Initialization

    public init(viewModel: TodayViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Progress Dashboard
                        dashboardCard

                        // Quick Actions
                        quickActionsBar

                        // Meals
                        mealsSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Space for FAB
                }
                .background(Color.appBackground)

                // Floating Action Button
                floatingAddButton
            }
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadTodayData()
            }
            .task {
                await viewModel.loadTodayData()
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
            .sheet(isPresented: $showQuickAdd) {
                QuickAddSheet(
                    onSelectMealType: { mealType in
                        showQuickAdd = false
                        viewModel.showAddFood(for: mealType)
                    }
                )
                .presentationDetents([.medium])
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Dashboard Card

    private var dashboardCard: some View {
        VStack(spacing: 24) {
            // Calorie Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 180, height: 180)

                // Progress ring
                Circle()
                    .trim(from: 0, to: calorieProgress)
                    .stroke(
                        calorieGradient,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: calorieProgress)

                // Center content
                VStack(spacing: 4) {
                    Text("\(Int(viewModel.nutrition.calories))")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    if let targets = viewModel.targets {
                        Text("of \(Int(targets.calories))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text("calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
            }
            .padding(.top, 8)

            // Macro Progress Bars
            HStack(spacing: 16) {
                MacroProgressView(
                    title: "Protein",
                    current: viewModel.nutrition.protein,
                    target: viewModel.targets?.proteinG ?? 150,
                    unit: "g",
                    color: .blue
                )

                MacroProgressView(
                    title: "Carbs",
                    current: viewModel.nutrition.carbs,
                    target: viewModel.targets?.carbsG ?? 250,
                    unit: "g",
                    color: .orange
                )

                MacroProgressView(
                    title: "Fat",
                    current: viewModel.nutrition.fat,
                    target: viewModel.targets?.fatG ?? 65,
                    unit: "g",
                    color: .purple
                )
            }
        }
        .padding(24)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }

    private var calorieProgress: CGFloat {
        guard let targets = viewModel.targets, targets.calories > 0 else {
            return min(viewModel.nutrition.calories / 2000, 1.0)
        }
        return min(viewModel.nutrition.calories / targets.calories, 1.0)
    }

    private var calorieGradient: LinearGradient {
        LinearGradient(
            colors: [.green, .green.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Quick Actions Bar

    private var quickActionsBar: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "camera.fill",
                title: "Photo",
                color: .blue
            ) {
                viewModel.showAddFood(for: suggestedMealType)
            }

            QuickActionButton(
                icon: "mic.fill",
                title: "Voice",
                color: .orange
            ) {
                viewModel.showAddFood(for: suggestedMealType)
            }

            QuickActionButton(
                icon: "barcode.viewfinder",
                title: "Scan",
                color: .purple
            ) {
                viewModel.showAddFood(for: suggestedMealType)
            }

            QuickActionButton(
                icon: "magnifyingglass",
                title: "Search",
                color: .green
            ) {
                viewModel.showAddFood(for: suggestedMealType)
            }
        }
    }

    private var suggestedMealType: FoodLogRecord.MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return .breakfast
        case 11..<15: return .lunch
        case 15..<21: return .dinner
        default: return .snack
        }
    }

    // MARK: - Meals Section

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Meals")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.leading, 4)

            ForEach(FoodLogRecord.MealType.allCases) { mealType in
                MealCard(
                    mealType: mealType,
                    logs: viewModel.logs(for: mealType),
                    calories: viewModel.calories(for: mealType),
                    onAdd: {
                        viewModel.showAddFood(for: mealType)
                    },
                    onDelete: { log in
                        Task {
                            await viewModel.deleteLog(log)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Floating Add Button

    private var floatingAddButton: some View {
        Button {
            showQuickAdd = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: .green.opacity(0.4), radius: 10, y: 5)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Macro Progress View

struct MacroProgressView: View {
    let title: String
    let current: Double
    let target: Double
    let unit: String
    let color: Color

    private var progress: CGFloat {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }

            VStack(spacing: 2) {
                Text("\(Int(current))\(unit)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))

                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Meal Card

struct MealCard: View {
    let mealType: FoodLogRecord.MealType
    let logs: [APIFoodLog]
    let calories: Double
    let onAdd: () -> Void
    let onDelete: (APIFoodLog) -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Meal icon
                    Image(systemName: mealType.icon)
                        .font(.title3)
                        .foregroundColor(mealType.color)
                        .frame(width: 40, height: 40)
                        .background(mealType.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(mealType.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("\(logs.flatMap { $0.items }.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("\(Int(calories)) cal")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // Items
            if isExpanded {
                Divider()
                    .padding(.horizontal, 16)

                if logs.isEmpty {
                    emptyState
                } else {
                    itemsList
                }

                // Add button
                Button(action: onAdd) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Food")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(mealType.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife")
                .font(.title2)
                .foregroundColor(.secondary.opacity(0.5))

            Text("No food logged yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var itemsList: some View {
        VStack(spacing: 0) {
            ForEach(logs) { log in
                ForEach(log.items) { item in
                    FoodItemRow(item: item)

                    if item.id != log.items.last?.id {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
        }
    }
}

// MARK: - Food Item Row

struct FoodItemRow: View {
    let item: APIFoodLogItem

    var body: some View {
        HStack(spacing: 12) {
            // Food icon placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green.opacity(0.5))
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.foodSnapshot.name)
                    .font(.subheadline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let serving = item.foodSnapshot.servingDescription {
                        Text(serving)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("P: \(Int(item.nutrition.proteinG))g")
                        .font(.caption2)
                        .foregroundColor(.blue)

                    Text("C: \(Int(item.nutrition.carbsG))g")
                        .font(.caption2)
                        .foregroundColor(.orange)

                    Text("F: \(Int(item.nutrition.fatG))g")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
            }

            Spacer()

            Text("\(Int(item.nutrition.calories))")
                .font(.subheadline.weight(.semibold))
            + Text(" cal")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Quick Add Sheet

struct QuickAddSheet: View {
    let onSelectMealType: (FoodLogRecord.MealType) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Add to which meal?")
                    .font(.headline)
                    .padding(.top)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(FoodLogRecord.MealType.allCases) { mealType in
                        Button {
                            onSelectMealType(mealType)
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: mealType.icon)
                                    .font(.title)
                                    .foregroundColor(mealType.color)
                                    .frame(width: 60, height: 60)
                                    .background(mealType.color.opacity(0.15))
                                    .clipShape(Circle())

                                Text(mealType.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .background(Color.appBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Meal Type Extensions

extension FoodLogRecord.MealType {
    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .lunch: return .green
        case .dinner: return .blue
        case .snack: return .purple
        }
    }
}

// MARK: - Color Extensions

extension Color {
    #if canImport(UIKit)
    static let appBackground = Color(UIColor.systemGroupedBackground)
    static let cardBackground = Color(UIColor.systemBackground)
    static let groupedBackground = Color(UIColor.systemGroupedBackground)
    static let searchBarBackground = Color(UIColor.systemGray6)
    #else
    static let appBackground = Color(NSColor.windowBackgroundColor)
    static let cardBackground = Color(NSColor.controlBackgroundColor)
    static let groupedBackground = Color(NSColor.windowBackgroundColor)
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
