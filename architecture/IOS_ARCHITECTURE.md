# iOS Architecture Document
## Diet App - Agent 04 Technical Architecture

---

## Executive Summary

This document defines the complete iOS architecture for the diet app, targeting iOS 16+ with iOS 17 optimizations. The architecture follows SwiftUI-first principles with offline-first data management using GRDB, PowerSync for cloud sync, and a hybrid AI pipeline for food recognition.

---

## 1. Project Structure

```
DietApp/
├── App/
│   ├── DietAppApp.swift              # App entry point
│   ├── AppDelegate.swift             # UIKit lifecycle (push, background)
│   ├── SceneDelegate.swift           # Scene management
│   └── Environment/
│       ├── AppEnvironment.swift      # Dependency container
│       └── FeatureFlags.swift        # Feature toggles
│
├── Features/
│   ├── Onboarding/
│   │   ├── Views/
│   │   │   ├── OnboardingFlowView.swift
│   │   │   ├── WelcomeView.swift
│   │   │   ├── GoalSelectionView.swift
│   │   │   ├── TrackingModeView.swift
│   │   │   └── HealthKitPermissionView.swift
│   │   ├── ViewModels/
│   │   │   └── OnboardingViewModel.swift
│   │   └── Models/
│   │       └── OnboardingState.swift
│   │
│   ├── Dashboard/
│   │   ├── Views/
│   │   │   ├── DashboardView.swift
│   │   │   ├── NutritionSummaryCard.swift
│   │   │   ├── MealListView.swift
│   │   │   └── QuickActionsView.swift
│   │   ├── ViewModels/
│   │   │   └── DashboardViewModel.swift
│   │   └── Components/
│   │       ├── MacroProgressRing.swift
│   │       └── MealCard.swift
│   │
│   ├── FoodLogging/
│   │   ├── Views/
│   │   │   ├── FoodLoggingSheet.swift
│   │   │   ├── FoodSearchView.swift
│   │   │   ├── CameraView.swift
│   │   │   ├── BarcodeScanner.swift
│   │   │   ├── PhotoReviewView.swift
│   │   │   └── ManualEntryView.swift
│   │   ├── ViewModels/
│   │   │   ├── FoodLoggingViewModel.swift
│   │   │   ├── FoodSearchViewModel.swift
│   │   │   └── CameraViewModel.swift
│   │   └── Models/
│   │       └── LoggingFlow.swift
│   │
│   ├── Insights/
│   │   ├── Views/
│   │   │   ├── InsightsView.swift
│   │   │   ├── WeeklyTrendsView.swift
│   │   │   ├── PatternsView.swift
│   │   │   └── SuggestionsView.swift
│   │   ├── ViewModels/
│   │   │   └── InsightsViewModel.swift
│   │   └── Charts/
│   │       ├── MacroChart.swift
│   │       └── TrendChart.swift
│   │
│   ├── Settings/
│   │   ├── Views/
│   │   │   ├── SettingsView.swift
│   │   │   ├── ProfileView.swift
│   │   │   ├── GoalsView.swift
│   │   │   ├── NotificationsView.swift
│   │   │   └── RecoveryModeView.swift
│   │   └── ViewModels/
│   │       └── SettingsViewModel.swift
│   │
│   └── RecoveryMode/
│       ├── Views/
│       │   ├── RecoveryDashboardView.swift
│       │   └── MindfulLoggingView.swift
│       └── ViewModels/
│           └── RecoveryModeViewModel.swift
│
├── Core/
│   ├── Database/
│   │   ├── DatabaseManager.swift         # GRDB setup
│   │   ├── Migrations/
│   │   │   ├── Migration_v1.swift
│   │   │   └── MigrationRunner.swift
│   │   ├── Tables/
│   │   │   ├── FoodLogRecord.swift
│   │   │   ├── FoodItemRecord.swift
│   │   │   ├── WeightRecord.swift
│   │   │   ├── UserGoalsRecord.swift
│   │   │   └── SyncQueueRecord.swift
│   │   └── Repositories/
│   │       ├── FoodLogRepository.swift
│   │       ├── FoodItemRepository.swift
│   │       ├── WeightRepository.swift
│   │       └── UserRepository.swift
│   │
│   ├── Networking/
│   │   ├── APIClient.swift
│   │   ├── Endpoints/
│   │   │   ├── AuthEndpoint.swift
│   │   │   ├── FoodEndpoint.swift
│   │   │   └── SyncEndpoint.swift
│   │   ├── Models/
│   │   │   └── APIResponse.swift
│   │   └── Interceptors/
│   │       ├── AuthInterceptor.swift
│   │       └── RetryInterceptor.swift
│   │
│   ├── Sync/
│   │   ├── SyncEngine.swift              # PowerSync integration
│   │   ├── OfflineQueue.swift
│   │   ├── ConflictResolver.swift
│   │   └── SyncStatus.swift
│   │
│   ├── HealthKit/
│   │   ├── HealthKitManager.swift
│   │   ├── HealthKitPermissions.swift
│   │   ├── NutritionWriter.swift
│   │   ├── WorkoutReader.swift
│   │   └── WeightSync.swift
│   │
│   ├── AI/
│   │   ├── FoodRecognitionService.swift
│   │   ├── OnDeviceClassifier.swift      # Core ML
│   │   ├── CloudVisionService.swift      # Gemini API
│   │   ├── NaturalLanguageParser.swift
│   │   └── Models/
│   │       ├── FoodPrediction.swift
│   │       └── RecognitionResult.swift
│   │
│   ├── Auth/
│   │   ├── AuthManager.swift
│   │   ├── KeychainService.swift
│   │   ├── BiometricAuth.swift
│   │   └── SessionManager.swift
│   │
│   └── Notifications/
│       ├── NotificationManager.swift
│       ├── ReminderScheduler.swift
│       └── PushHandler.swift
│
├── Shared/
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   ├── View+Extensions.swift
│   │   └── Color+Theme.swift
│   ├── Components/
│   │   ├── LoadingView.swift
│   │   ├── ErrorView.swift
│   │   ├── EmptyStateView.swift
│   │   └── PrimaryButton.swift
│   ├── Utilities/
│   │   ├── Logger.swift
│   │   ├── Analytics.swift
│   │   └── Formatters.swift
│   └── Constants/
│       ├── AppConstants.swift
│       └── DesignTokens.swift
│
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.strings
│   ├── FoodClassifier.mlmodel         # Core ML model
│   └── CommonFoods.sqlite             # Pre-bundled food database
│
├── Widgets/
│   ├── DietWidget/
│   │   ├── DietWidget.swift
│   │   ├── DietWidgetBundle.swift
│   │   ├── TimelineProvider.swift
│   │   ├── WidgetViews/
│   │   │   ├── SmallWidgetView.swift
│   │   │   ├── MediumWidgetView.swift
│   │   │   └── LockScreenWidgetView.swift
│   │   └── WidgetIntents/
│   │       └── QuickLogIntent.swift    # iOS 17 interactive
│   └── Shared/
│       └── WidgetDataProvider.swift
│
└── WatchApp/
    ├── DietWatchApp.swift
    ├── Views/
    │   ├── WatchDashboardView.swift
    │   ├── QuickLogView.swift
    │   └── ComplicationView.swift
    └── Connectivity/
        └── WatchConnectivityManager.swift
```

---

## 2. State Management

### iOS 16 vs iOS 17 Strategy

We support both iOS 16 (`ObservableObject`) and iOS 17 (`@Observable`) through a compatibility layer.

```swift
// MARK: - iOS 17+ Native Observable
@available(iOS 17.0, *)
@Observable
final class DashboardState {
    var todayNutrition: NutritionSummary = .empty
    var meals: [MealEntry] = []
    var isLoading: Bool = false
    var error: AppError?

    private let foodLogRepository: FoodLogRepository

    init(foodLogRepository: FoodLogRepository) {
        self.foodLogRepository = foodLogRepository
    }

    func loadToday() async {
        isLoading = true
        defer { isLoading = false }

        do {
            meals = try await foodLogRepository.fetchToday()
            todayNutrition = NutritionSummary(from: meals)
        } catch {
            self.error = .dataLoadFailed(error)
        }
    }
}

// MARK: - iOS 16 Compatibility
final class DashboardViewModel: ObservableObject {
    @Published var todayNutrition: NutritionSummary = .empty
    @Published var meals: [MealEntry] = []
    @Published var isLoading: Bool = false
    @Published var error: AppError?

    private let foodLogRepository: FoodLogRepository

    init(foodLogRepository: FoodLogRepository) {
        self.foodLogRepository = foodLogRepository
    }

    @MainActor
    func loadToday() async {
        isLoading = true
        defer { isLoading = false }

        do {
            meals = try await foodLogRepository.fetchToday()
            todayNutrition = NutritionSummary(from: meals)
        } catch {
            self.error = .dataLoadFailed(error)
        }
    }
}

// MARK: - View Usage
struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        // View implementation
    }
}
```

### Dependency Injection

Using a lightweight container pattern for testability:

```swift
// MARK: - Dependency Container
@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()

    // Core Services
    lazy var database: DatabaseManager = DatabaseManager()
    lazy var apiClient: APIClient = APIClient(session: .shared)
    lazy var syncEngine: SyncEngine = SyncEngine(database: database, api: apiClient)
    lazy var healthKit: HealthKitManager = HealthKitManager()
    lazy var auth: AuthManager = AuthManager(keychain: keychainService)

    // Repositories
    lazy var foodLogRepository: FoodLogRepository = FoodLogRepository(database: database)
    lazy var foodItemRepository: FoodItemRepository = FoodItemRepository(database: database)
    lazy var weightRepository: WeightRepository = WeightRepository(database: database)

    // AI Services
    lazy var foodRecognition: FoodRecognitionService = FoodRecognitionService(
        onDevice: OnDeviceClassifier(),
        cloud: CloudVisionService(apiClient: apiClient)
    )

    // Private
    private lazy var keychainService: KeychainService = KeychainService()

    private init() {}

    // Factory methods for ViewModels
    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(foodLogRepository: foodLogRepository)
    }

    func makeFoodLoggingViewModel() -> FoodLoggingViewModel {
        FoodLoggingViewModel(
            foodItemRepository: foodItemRepository,
            foodLogRepository: foodLogRepository,
            recognitionService: foodRecognition
        )
    }
}

// MARK: - Environment Key
private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment.shared
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
```

### Data Flow Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                        SwiftUI View                          │
│   - Observes ViewModel state                                │
│   - Dispatches user intents                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        ViewModel                             │
│   - Holds UI state (@Published / @Observable)               │
│   - Orchestrates business logic                             │
│   - Calls repositories                                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        Repository                            │
│   - Single source of truth                                  │
│   - Abstracts data source (local/remote)                    │
│   - Manages offline queue                                   │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────────┐
│    GRDB (Local SQLite)  │     │      SyncEngine (Remote)     │
│    - Offline-first      │ ◄──►│      - PowerSync             │
│    - FTS5 search        │     │      - Conflict resolution   │
└─────────────────────────┘     └─────────────────────────────┘
```

---

## 3. Navigation Architecture

### NavigationStack Setup

```swift
// MARK: - Navigation Destinations
enum AppDestination: Hashable {
    case dashboard
    case foodLogging(meal: MealType?)
    case foodDetail(id: UUID)
    case insights
    case settings
    case profile
    case goals
    case recoveryMode

    // Deep link support
    static func from(url: URL) -> AppDestination? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.scheme == "dietapp" else { return nil }

        switch components.host {
        case "log":
            let meal = components.queryItems?.first(where: { $0.name == "meal" })?.value
            return .foodLogging(meal: MealType(rawValue: meal ?? ""))
        case "insights":
            return .insights
        case "settings":
            return .settings
        default:
            return .dashboard
        }
    }
}

// MARK: - Navigation Path Manager
@MainActor
final class NavigationManager: ObservableObject {
    @Published var path = NavigationPath()
    @Published var selectedTab: Tab = .dashboard

    enum Tab: Int, CaseIterable {
        case dashboard
        case insights
        case settings
    }

    func navigate(to destination: AppDestination) {
        path.append(destination)
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    func handleDeepLink(_ url: URL) {
        guard let destination = AppDestination.from(url: url) else { return }

        // Determine appropriate tab
        switch destination {
        case .dashboard, .foodLogging, .foodDetail:
            selectedTab = .dashboard
        case .insights:
            selectedTab = .insights
        case .settings, .profile, .goals, .recoveryMode:
            selectedTab = .settings
        }

        // Navigate after tab switch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.navigate(to: destination)
        }
    }
}

// MARK: - Root View
struct RootView: View {
    @StateObject private var navigation = NavigationManager()
    @Environment(\.appEnvironment) private var environment

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            DashboardTab()
                .tag(NavigationManager.Tab.dashboard)
                .tabItem { Label("Today", systemImage: "house.fill") }

            InsightsTab()
                .tag(NavigationManager.Tab.insights)
                .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsTab()
                .tag(NavigationManager.Tab.settings)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environmentObject(navigation)
        .onOpenURL { url in
            navigation.handleDeepLink(url)
        }
    }
}

// MARK: - Dashboard Tab with NavigationStack
struct DashboardTab: View {
    @EnvironmentObject private var navigation: NavigationManager
    @Environment(\.appEnvironment) private var environment

    var body: some View {
        NavigationStack(path: $navigation.path) {
            DashboardView(viewModel: environment.makeDashboardViewModel())
                .navigationDestination(for: AppDestination.self) { destination in
                    switch destination {
                    case .dashboard:
                        DashboardView(viewModel: environment.makeDashboardViewModel())
                    case .foodLogging(let meal):
                        FoodLoggingSheet(viewModel: environment.makeFoodLoggingViewModel(), preselectedMeal: meal)
                    case .foodDetail(let id):
                        FoodDetailView(foodId: id)
                    default:
                        EmptyView()
                    }
                }
        }
    }
}
```

### Tab Structure

```
┌─────────────────────────────────────────────────────────────┐
│                          Tab Bar                             │
├─────────────────┬─────────────────┬─────────────────────────┤
│     Today       │    Insights     │       Settings          │
│   (Dashboard)   │   (Analytics)   │      (Profile)          │
├─────────────────┴─────────────────┴─────────────────────────┤
│                                                              │
│  Today Tab:                                                  │
│  ├── Dashboard (root)                                       │
│  ├── Food Logging Sheet (modal)                             │
│  ├── Food Detail                                            │
│  └── Meal Editor                                            │
│                                                              │
│  Insights Tab:                                               │
│  ├── Insights Overview (root)                               │
│  ├── Weekly Trends                                          │
│  ├── Patterns Detail                                        │
│  └── Nutrient Deep Dive                                     │
│                                                              │
│  Settings Tab:                                               │
│  ├── Settings (root)                                        │
│  ├── Profile                                                │
│  ├── Goals                                                  │
│  ├── Notifications                                          │
│  ├── Recovery Mode                                          │
│  ├── HealthKit Settings                                     │
│  └── About / Legal                                          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Cold Launch | < 1.0s | Time to first interactive frame |
| Warm Launch | < 0.3s | Time from background to interactive |
| Navigation Transitions | < 100ms | SwiftUI animation completion |
| Food Search (cached) | < 50ms | FTS5 query response |
| Food Search (API) | < 500ms | Network + parse |
| Barcode Scan | < 500ms | Detection to result |
| Photo Analysis (on-device) | < 200ms | Core ML inference |
| Photo Analysis (cloud) | < 2000ms | Network + inference |
| Memory (foreground) | < 150MB | Average during use |
| Memory (background) | < 50MB | Background refresh |
| Battery Impact | < 5%/hour active | Active use tracking |
| Widget Refresh | ~50/day | WidgetKit budget |

### Optimization Strategies

```swift
// MARK: - Lazy Loading for Dashboard
struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Critical content loads first
                NutritionSummaryCard(nutrition: viewModel.todayNutrition)

                // Meals load on-demand
                ForEach(viewModel.meals) { meal in
                    MealCard(meal: meal)
                }
            }
        }
        .task {
            await viewModel.loadToday()
        }
    }
}

// MARK: - Image Caching
actor ImageCache {
    static let shared = ImageCache()

    private var cache = NSCache<NSString, UIImage>()
    private var inFlightTasks: [String: Task<UIImage?, Never>] = [:]

    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    func image(for key: String) async -> UIImage? {
        if let cached = cache.object(forKey: key as NSString) {
            return cached
        }

        if let task = inFlightTasks[key] {
            return await task.value
        }

        let task = Task<UIImage?, Never> {
            // Load from disk or network
            guard let image = await loadImage(key: key) else { return nil }
            cache.setObject(image, forKey: key as NSString)
            return image
        }

        inFlightTasks[key] = task
        let result = await task.value
        inFlightTasks[key] = nil
        return result
    }

    private func loadImage(key: String) async -> UIImage? {
        // Implementation
        nil
    }
}
```

---

*Document continues in DATA_LAYER.md*
