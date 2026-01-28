# Widget Architecture
## Diet App - Agent 04

---

## 1. Widget Types Overview

| Widget | Family | Purpose | Interactive (iOS 17+) |
|--------|--------|---------|----------------------|
| Daily Progress | Small, Medium | Show calorie/macro progress | No |
| Quick Log | Medium | Log favorite foods | Yes |
| Macro Breakdown | Medium, Large | Detailed nutrient view | No |
| Lock Screen | Accessory | Calories remaining | No |

---

## 2. App Group Setup

```swift
// MARK: - App Group Identifier
enum AppGroup {
    static let identifier = "group.com.dietapp.shared"

    static var containerURL: URL {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        )!
    }

    static var databaseURL: URL {
        containerURL.appendingPathComponent("shared.sqlite")
    }

    static var userDefaults: UserDefaults {
        UserDefaults(suiteName: identifier)!
    }
}
```

### Shared Data Provider

```swift
import WidgetKit

// MARK: - Widget Data Model
struct WidgetData: Codable {
    let lastUpdated: Date
    let todayNutrition: NutritionSnapshot
    let goals: GoalsSnapshot
    let recentFoods: [QuickLogFood]
    let trackingMode: String

    struct NutritionSnapshot: Codable {
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
    }

    struct GoalsSnapshot: Codable {
        let calorieTarget: Int
        let proteinTarget: Double
        let carbsTarget: Double
        let fatTarget: Double
    }

    struct QuickLogFood: Codable, Identifiable {
        let id: String
        let name: String
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let defaultQuantity: Double
        let unit: String
    }

    // Computed properties
    var caloriesRemaining: Double {
        max(0, Double(goals.calorieTarget) - todayNutrition.calories)
    }

    var calorieProgress: Double {
        guard goals.calorieTarget > 0 else { return 0 }
        return min(1.0, todayNutrition.calories / Double(goals.calorieTarget))
    }

    var isRecoveryMode: Bool {
        trackingMode == "mindful"
    }
}

// MARK: - Widget Data Provider
final class WidgetDataProvider {
    static let shared = WidgetDataProvider()

    private let userDefaults = AppGroup.userDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let dataKey = "widgetData"

    // MARK: - Write (from main app)

    func updateWidgetData(_ data: WidgetData) {
        do {
            let encoded = try encoder.encode(data)
            userDefaults.set(encoded, forKey: dataKey)

            // Trigger widget refresh
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to encode widget data: \(error)")
        }
    }

    func updateNutrition(_ nutrition: NutritionSummary, goals: UserGoalsRecord) {
        var current = fetchWidgetData() ?? defaultWidgetData()

        current = WidgetData(
            lastUpdated: Date(),
            todayNutrition: WidgetData.NutritionSnapshot(
                calories: nutrition.calories,
                protein: nutrition.protein,
                carbs: nutrition.carbs,
                fat: nutrition.fat
            ),
            goals: WidgetData.GoalsSnapshot(
                calorieTarget: goals.calorieTarget ?? 2000,
                proteinTarget: goals.proteinTarget ?? 150,
                carbsTarget: goals.carbsTarget ?? 250,
                fatTarget: goals.fatTarget ?? 65
            ),
            recentFoods: current.recentFoods,
            trackingMode: current.trackingMode
        )

        updateWidgetData(current)
    }

    func updateRecentFoods(_ foods: [WidgetData.QuickLogFood]) {
        guard var current = fetchWidgetData() else { return }

        current = WidgetData(
            lastUpdated: current.lastUpdated,
            todayNutrition: current.todayNutrition,
            goals: current.goals,
            recentFoods: Array(foods.prefix(6)),
            trackingMode: current.trackingMode
        )

        updateWidgetData(current)
    }

    // MARK: - Read (from widget)

    func fetchWidgetData() -> WidgetData? {
        guard let data = userDefaults.data(forKey: dataKey) else { return nil }
        return try? decoder.decode(WidgetData.self, from: data)
    }

    private func defaultWidgetData() -> WidgetData {
        WidgetData(
            lastUpdated: Date(),
            todayNutrition: .init(calories: 0, protein: 0, carbs: 0, fat: 0),
            goals: .init(calorieTarget: 2000, proteinTarget: 150, carbsTarget: 250, fatTarget: 65),
            recentFoods: [],
            trackingMode: "full"
        )
    }
}
```

---

## 3. Timeline Provider

```swift
import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct DietWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetData?
    let configuration: ConfigurationAppIntent?

    var isPlaceholder: Bool {
        data == nil
    }

    static var placeholder: DietWidgetEntry {
        DietWidgetEntry(
            date: Date(),
            data: nil,
            configuration: nil
        )
    }
}

// MARK: - Timeline Provider
struct DietWidgetTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = DietWidgetEntry
    typealias Intent = ConfigurationAppIntent

    func placeholder(in context: Context) -> Entry {
        .placeholder
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        return DietWidgetEntry(date: Date(), data: data, configuration: configuration)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        let currentEntry = DietWidgetEntry(date: Date(), data: data, configuration: configuration)

        // Schedule updates at key times
        var entries: [Entry] = [currentEntry]

        // Update at midnight for new day
        if let midnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) {
            entries.append(DietWidgetEntry(date: midnight, data: nil, configuration: configuration))
        }

        // Update hourly during active hours (6 AM - 10 PM)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())

        if hour >= 6 && hour < 22 {
            if let nextHour = calendar.date(byAdding: .hour, value: 1, to: Date()) {
                entries.append(DietWidgetEntry(date: nextHour, data: data, configuration: configuration))
            }
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

// MARK: - Configuration Intent
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Widget"
    static var description = IntentDescription("Choose what to display.")

    @Parameter(title: "Show Macros", default: true)
    var showMacros: Bool

    @Parameter(title: "Compact Mode", default: false)
    var compactMode: Bool
}
```

---

## 4. Widget Views

### Small Widget (Progress Ring)

```swift
struct SmallWidgetView: View {
    let entry: DietWidgetEntry

    var body: some View {
        if let data = entry.data {
            VStack(spacing: 8) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: data.calorieProgress)
                        .stroke(
                            Color.theme.primary,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        if data.isRecoveryMode {
                            Image(systemName: "leaf.fill")
                                .font(.title2)
                                .foregroundStyle(Color.theme.primary)
                        } else {
                            Text("\(Int(data.caloriesRemaining))")
                                .font(.system(.title2, design: .rounded, weight: .bold))

                            Text("left")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(width: 80, height: 80)

                if !data.isRecoveryMode {
                    Text("\(Int(data.todayNutrition.calories)) / \(data.goals.calorieTarget)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            PlaceholderView()
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

struct PlaceholderView: View {
    var body: some View {
        VStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 12)
        }
    }
}
```

### Medium Widget (Macro Breakdown)

```swift
struct MediumWidgetView: View {
    let entry: DietWidgetEntry

    var body: some View {
        if let data = entry.data {
            HStack(spacing: 16) {
                // Calorie progress
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 6)

                        Circle()
                            .trim(from: 0, to: data.calorieProgress)
                            .stroke(Color.theme.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text("\(Int(data.caloriesRemaining))")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                            Text("cal left")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 70, height: 70)
                }

                // Macro bars
                VStack(alignment: .leading, spacing: 8) {
                    MacroRow(
                        label: "Protein",
                        current: data.todayNutrition.protein,
                        target: data.goals.proteinTarget,
                        color: .blue
                    )

                    MacroRow(
                        label: "Carbs",
                        current: data.todayNutrition.carbs,
                        target: data.goals.carbsTarget,
                        color: .orange
                    )

                    MacroRow(
                        label: "Fat",
                        current: data.todayNutrition.fat,
                        target: data.goals.fatTarget,
                        color: .purple
                    )
                }
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            MediumPlaceholderView()
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

struct MacroRow: View {
    let label: String
    let current: Double
    let target: Double
    let color: Color

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(1.0, current / target)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(current))g")
                    .font(.caption2.bold())
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 6)
        }
    }
}
```

### Lock Screen Widget

```swift
struct LockScreenWidgetView: View {
    let entry: DietWidgetEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            accessoryCircular
        case .accessoryRectangular:
            accessoryRectangular
        case .accessoryInline:
            accessoryInline
        default:
            EmptyView()
        }
    }

    var accessoryCircular: some View {
        ZStack {
            if let data = entry.data {
                Gauge(value: data.calorieProgress) {
                    Image(systemName: "fork.knife")
                }
                .gaugeStyle(.accessoryCircular)
            } else {
                Gauge(value: 0) {
                    Image(systemName: "fork.knife")
                }
                .gaugeStyle(.accessoryCircular)
            }
        }
    }

    var accessoryRectangular: some View {
        VStack(alignment: .leading) {
            if let data = entry.data {
                HStack {
                    Image(systemName: "fork.knife")
                    Text("\(Int(data.caloriesRemaining)) cal left")
                        .font(.headline)
                }

                Gauge(value: data.calorieProgress) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryLinear)
            } else {
                Text("Open app to sync")
                    .font(.caption)
            }
        }
    }

    var accessoryInline: some View {
        if let data = entry.data {
            Text("\(Int(data.caloriesRemaining)) calories remaining")
        } else {
            Text("Sync required")
        }
    }
}
```

---

## 5. Interactive Widget (iOS 17+)

```swift
import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Quick Log Intent
@available(iOS 17.0, *)
struct QuickLogFoodIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Food"
    static var description = IntentDescription("Quickly log a favorite food item")

    @Parameter(title: "Food ID")
    var foodId: String

    init() {}

    init(foodId: String) {
        self.foodId = foodId
    }

    func perform() async throws -> some IntentResult {
        // Log the food
        await MainActor.run {
            NotificationCenter.default.post(
                name: .quickLogFood,
                object: nil,
                userInfo: ["foodId": foodId]
            )
        }

        // Refresh widget
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}

extension Notification.Name {
    static let quickLogFood = Notification.Name("quickLogFood")
}

// MARK: - Interactive Quick Log Widget
@available(iOS 17.0, *)
struct QuickLogWidgetView: View {
    let entry: DietWidgetEntry

    var body: some View {
        if let data = entry.data, !data.recentFoods.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Log")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(data.recentFoods.prefix(4)) { food in
                        Button(intent: QuickLogFoodIntent(foodId: food.id)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(food.name)
                                    .font(.caption.bold())
                                    .lineLimit(1)

                                Text("\(Int(food.calories)) cal")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color.theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            VStack {
                Image(systemName: "star")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("Add favorites to quick log")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}
```

---

## 6. Widget Bundle

```swift
import WidgetKit
import SwiftUI

@main
struct DietWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Progress widget (all sizes)
        DietProgressWidget()

        // Quick log widget (iOS 17+ interactive)
        if #available(iOS 17.0, *) {
            QuickLogWidget()
        }

        // Lock screen widgets
        LockScreenWidget()
    }
}

// MARK: - Progress Widget
struct DietProgressWidget: Widget {
    let kind = "DietProgressWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: DietWidgetTimelineProvider()
        ) { entry in
            DietProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Progress")
        .description("Track your daily nutrition progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DietProgressWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: DietWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Quick Log Widget (iOS 17+)
@available(iOS 17.0, *)
struct QuickLogWidget: Widget {
    let kind = "QuickLogWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: DietWidgetTimelineProvider()
        ) { entry in
            QuickLogWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Log")
        .description("Quickly log your favorite foods.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Lock Screen Widget
struct LockScreenWidget: Widget {
    let kind = "LockScreenWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: DietWidgetTimelineProvider()
        ) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Calories")
        .description("See calories remaining at a glance.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
```

---

## 7. Widget Refresh Strategy

| Trigger | Action |
|---------|--------|
| Food logged | `WidgetCenter.shared.reloadAllTimelines()` |
| App foreground | Update shared data, reload timelines |
| Midnight | Timeline entry scheduled |
| Hourly (6 AM - 10 PM) | Timeline entry scheduled |
| Settings changed | Reload timelines |

```swift
// MARK: - Widget Update Manager
final class WidgetUpdateManager {
    static let shared = WidgetUpdateManager()

    private let dataProvider = WidgetDataProvider.shared

    func onFoodLogged(nutrition: NutritionSummary, goals: UserGoalsRecord) {
        dataProvider.updateNutrition(nutrition, goals: goals)
        // WidgetCenter reload is called inside updateNutrition
    }

    func onAppForeground() {
        // Refresh from database
        Task {
            await refreshWidgetData()
        }
    }

    func onSettingsChanged() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func refreshWidgetData() async {
        // Fetch current data from repositories and update widget
    }
}
```

---

*Document continues in CAMERA_AI_PIPELINE.md*
