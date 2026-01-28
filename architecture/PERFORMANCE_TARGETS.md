# Performance Targets & Optimization
## Diet App - Agent 04

---

## 1. Performance Budget

### Launch Time

| Metric | Target | Maximum | Measurement |
|--------|--------|---------|-------------|
| Cold Launch | < 800ms | 1.0s | First frame rendered |
| Warm Launch | < 200ms | 300ms | Background to interactive |
| Time to Interactive | < 1.0s | 1.5s | User can tap |

### Responsiveness

| Interaction | Target | Maximum | Notes |
|-------------|--------|---------|-------|
| Tab Switch | < 50ms | 100ms | Instant feel |
| Navigation Push | < 100ms | 150ms | Smooth animation |
| Button Response | < 50ms | 100ms | Visual feedback |
| Scroll Frame Time | < 16.7ms | 16.7ms | 60 FPS required |
| Modal Presentation | < 150ms | 200ms | Sheet animation |

### Data Operations

| Operation | Target | Maximum | Notes |
|-----------|--------|---------|-------|
| Food Search (local) | < 50ms | 100ms | FTS5 query |
| Food Search (API) | < 400ms | 800ms | Network + parse |
| Barcode Lookup | < 300ms | 500ms | Detection + lookup |
| Photo Analysis (on-device) | < 200ms | 300ms | Core ML |
| Photo Analysis (cloud) | < 1500ms | 2500ms | Network + inference |
| Daily Summary Load | < 100ms | 200ms | Aggregation query |
| Sync Push | < 500ms | 1000ms | Per batch |

### Memory

| State | Target | Maximum | Notes |
|-------|--------|---------|-------|
| Launch Footprint | < 50MB | 80MB | Before user data |
| Active Use | < 120MB | 150MB | Normal operation |
| Camera Active | < 180MB | 220MB | Capture session |
| Background | < 40MB | 50MB | Suspended |
| Widget | < 20MB | 30MB | Extension limit |

### Battery

| Activity | Target | Notes |
|----------|--------|-------|
| Active Logging | < 5%/hour | Normal use |
| Background Sync | < 1%/hour | Periodic updates |
| HealthKit Observation | Negligible | System-managed |
| Location (if used) | N/A | Not planned |

---

## 2. Optimization Strategies

### Launch Time Optimization

```swift
// MARK: - App Delegate Optimization
@main
struct DietApp: App {
    // Use lazy initialization
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    // Defer non-critical initialization
                    await performDeferredSetup()
                }
        }
    }

    private func performDeferredSetup() async {
        // These can happen after first frame
        await Task.detached(priority: .background) {
            // Preload Core ML model
            _ = OnDeviceClassifier()
        }.value

        // Setup HealthKit observers (not blocking)
        Task {
            await AppEnvironment.shared.healthKit.setupObserverQueries()
        }
    }
}

// MARK: - Database Pre-warming
extension DatabaseManager {
    func prewarm() async {
        // Execute common queries to warm SQLite cache
        try? await reader.read { db in
            // Touch the food_items_fts index
            _ = try FoodItemRecord
                .filter(sql: "1 = 0") // No results, just warm index
                .fetchCount(db)
        }
    }
}
```

### Memory Management

```swift
// MARK: - Image Memory Management
final class ImageMemoryManager {
    static let shared = ImageMemoryManager()

    private let memoryWarningObserver: NSObjectProtocol?

    init() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }

    private func handleMemoryWarning() {
        // Clear image caches
        URLCache.shared.removeAllCachedResponses()

        // Clear recognition cache
        Task {
            await RecognitionCache.shared.clear()
        }

        // Clear thumbnail cache
        Task {
            await ImageCache.shared.handleMemoryWarning()
        }
    }
}

// MARK: - Efficient Image Loading
extension UIImage {
    static func thumbnail(from url: URL, targetSize: CGSize) async -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: max(targetSize.width, targetSize.height) * UIScreen.main.scale
        ]

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    func downsampled(to targetSize: CGSize) -> UIImage? {
        guard let data = jpegData(compressionQuality: 0.8) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: max(targetSize.width, targetSize.height) * UIScreen.main.scale
        ]

        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
```

### List Performance

```swift
// MARK: - Efficient List Rendering
struct MealListView: View {
    let meals: [MealEntry]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(meals) { meal in
                    MealCard(meal: meal)
                        .id(meal.id) // Stable identity
                }
            }
            .padding()
        }
    }
}

// MARK: - Optimized Meal Card
struct MealCard: View {
    let meal: MealEntry

    // Avoid unnecessary recomputation
    private var formattedCalories: String {
        "\(Int(meal.calories)) cal"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Lazy image loading
            if let photoUrl = meal.photoUrl {
                AsyncImage(url: URL(string: photoUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderImage
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderImage
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(meal.foodName)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                Text(formattedCalories)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
    }
}
```

### Database Query Optimization

```swift
// MARK: - Optimized Queries
extension FoodLogRepository {
    // Use precompiled statements for frequent queries
    private static let todayQuerySQL = """
        SELECT * FROM food_logs
        WHERE user_id = ? AND date = ?
        ORDER BY logged_at ASC
        """

    func fetchTodayOptimized(userId: String) async throws -> [FoodLogRecord] {
        let today = Calendar.current.startOfDay(for: Date())

        return try await database.reader.read { db in
            try FoodLogRecord.fetchAll(
                db,
                sql: Self.todayQuerySQL,
                arguments: [userId, today]
            )
        }
    }

    // Batch fetch for multiple days
    func fetchWeekOptimized(userId: String) async throws -> [Date: [FoodLogRecord]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        let logs = try await database.reader.read { db in
            try FoodLogRecord
                .filter(Column("user_id") == userId)
                .filter(Column("date") >= weekAgo)
                .filter(Column("date") <= today)
                .fetchAll(db)
        }

        // Group by date
        return Dictionary(grouping: logs) { $0.date }
    }
}

// MARK: - Search Optimization
extension FoodItemRepository {
    // Debounced search
    func searchDebounced(
        query: String,
        debounceMs: Int = 300
    ) -> AsyncStream<[FoodItemRecord]> {
        AsyncStream { continuation in
            Task {
                // Wait for debounce period
                try? await Task.sleep(nanoseconds: UInt64(debounceMs * 1_000_000))

                guard !Task.isCancelled else {
                    continuation.finish()
                    return
                }

                do {
                    let results = try await search(query: query)
                    continuation.yield(results)
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }
}
```

---

## 3. Profiling & Monitoring

### Instruments Configuration

```swift
// MARK: - Performance Signposts
import os.signpost

enum PerformanceSignpost {
    private static let log = OSLog(subsystem: "com.dietapp", category: .pointsOfInterest)

    static func begin(_ name: StaticString, id: OSSignpostID = .exclusive) {
        os_signpost(.begin, log: log, name: name, signpostID: id)
    }

    static func end(_ name: StaticString, id: OSSignpostID = .exclusive) {
        os_signpost(.end, log: log, name: name, signpostID: id)
    }

    static func event(_ name: StaticString) {
        os_signpost(.event, log: log, name: name)
    }
}

// Usage in code:
func searchFood(query: String) async throws -> [FoodItemRecord] {
    PerformanceSignpost.begin("Food Search")
    defer { PerformanceSignpost.end("Food Search") }

    return try await foodItemRepository.search(query: query)
}
```

### MetricKit Integration

```swift
import MetricKit

// MARK: - Metrics Collector
final class MetricsCollector: NSObject, MXMetricManagerSubscriber {
    static let shared = MetricsCollector()

    override init() {
        super.init()
        MXMetricManager.shared.add(self)
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            processMetricPayload(payload)
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            processDiagnosticPayload(payload)
        }
    }

    private func processMetricPayload(_ payload: MXMetricPayload) {
        // Launch metrics
        if let launchMetrics = payload.applicationLaunchMetrics {
            let resumeTime = launchMetrics.histogrammedResumeTime.averageMeasurement
            let coldLaunch = launchMetrics.histogrammedTimeToFirstDraw.averageMeasurement

            // Log for monitoring
            Logger.performance.info("Cold launch: \(coldLaunch.value)ms, Resume: \(resumeTime.value)ms")

            // Alert if exceeding targets
            if coldLaunch.value > 1000 {
                Logger.performance.warning("Cold launch exceeds 1s target")
            }
        }

        // Memory metrics
        if let memoryMetrics = payload.memoryMetrics {
            let peakMemory = memoryMetrics.peakMemoryUsage
            Logger.performance.info("Peak memory: \(peakMemory.value / 1024 / 1024)MB")
        }
    }

    private func processDiagnosticPayload(_ payload: MXDiagnosticPayload) {
        // Handle crash reports, hangs, etc.
        if let crashDiagnostics = payload.crashDiagnostics {
            for diagnostic in crashDiagnostics {
                Logger.error.error("Crash diagnostic: \(diagnostic.description)")
            }
        }

        if let hangDiagnostics = payload.hangDiagnostics {
            for diagnostic in hangDiagnostics {
                Logger.performance.warning("Hang diagnostic: \(diagnostic.description)")
            }
        }
    }
}

// MARK: - Performance Logger
enum Logger {
    static let performance = os.Logger(subsystem: "com.dietapp", category: "performance")
    static let error = os.Logger(subsystem: "com.dietapp", category: "error")
}
```

---

## 4. Battery Optimization

```swift
// MARK: - Background Task Management
final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.dietapp.sync",
            using: nil
        ) { task in
            self.handleSyncTask(task as! BGProcessingTask)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.dietapp.healthkit",
            using: nil
        ) { task in
            self.handleHealthKitTask(task as! BGAppRefreshTask)
        }
    }

    func scheduleSync() {
        let request = BGProcessingTaskRequest(identifier: "com.dietapp.sync")
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        // Schedule for optimal time
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 min

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            Logger.error.error("Failed to schedule sync: \(error)")
        }
    }

    private func handleSyncTask(_ task: BGProcessingTask) {
        task.expirationHandler = {
            // Clean up if time expires
        }

        Task {
            do {
                try await AppEnvironment.shared.syncEngine.forcePush()
                try await AppEnvironment.shared.syncEngine.forcePull()
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }

            // Reschedule
            scheduleSync()
        }
    }

    private func handleHealthKitTask(_ task: BGAppRefreshTask) {
        task.expirationHandler = {}

        Task {
            await AppEnvironment.shared.healthKit.syncFromHealthKit()
            task.setTaskCompleted(success: true)

            // Reschedule
            scheduleHealthKitRefresh()
        }
    }

    func scheduleHealthKitRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.dietapp.healthkit")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour

        try? BGTaskScheduler.shared.submit(request)
    }
}
```

### Network Efficiency

```swift
// MARK: - Smart Network Usage
final class NetworkEfficiencyManager {
    static let shared = NetworkEfficiencyManager()

    private let monitor = NWPathMonitor()

    var isOnWiFi: Bool {
        monitor.currentPath.usesInterfaceType(.wifi)
    }

    var isCellular: Bool {
        monitor.currentPath.usesInterfaceType(.cellular)
    }

    var isExpensive: Bool {
        monitor.currentPath.isExpensive
    }

    // Batch API calls when on cellular
    func shouldBatchRequests() -> Bool {
        return isCellular || isExpensive
    }

    // Defer non-critical uploads
    func shouldDeferUpload() -> Bool {
        return isExpensive
    }
}

// Usage in sync
extension SyncEngine {
    func smartSync() async {
        let efficiency = NetworkEfficiencyManager.shared

        if efficiency.isOnWiFi {
            // Full sync on WiFi
            try? await forcePush()
            try? await forcePull()
        } else if efficiency.isCellular {
            // Only push critical changes on cellular
            try? await pushCriticalOnly()
        }
    }
}
```

---

## 5. Testing & Benchmarks

### Performance Test Suite

```swift
import XCTest

final class PerformanceTests: XCTestCase {
    var database: DatabaseManager!
    var foodItemRepo: FoodItemRepository!

    override func setUp() {
        super.setUp()
        database = DatabaseManager(inMemory: true)
        foodItemRepo = FoodItemRepository(database: database)

        // Seed test data
        seedTestFoods(count: 10000)
    }

    func testFoodSearchPerformance() throws {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let expectation = expectation(description: "Search")

            Task {
                _ = try await foodItemRepo.search(query: "chicken", limit: 50)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 1.0)
        }
    }

    func testDailyAggregationPerformance() throws {
        let foodLogRepo = FoodLogRepository(database: database)

        // Seed 30 days of logs
        seedTestLogs(days: 30, logsPerDay: 10)

        measure(metrics: [XCTClockMetric()]) {
            let expectation = expectation(description: "Aggregation")

            Task {
                _ = try await foodLogRepo.dailyNutrition(userId: "test", date: Date())
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 0.5)
        }
    }

    func testLaunchTimeSimulation() throws {
        measure(metrics: [XCTClockMetric()]) {
            // Simulate launch sequence
            _ = DatabaseManager()
            _ = AppEnvironment.shared
        }
    }

    private func seedTestFoods(count: Int) {
        // Implementation
    }

    private func seedTestLogs(days: Int, logsPerDay: Int) {
        // Implementation
    }
}
```

### Continuous Monitoring

```swift
// MARK: - Runtime Performance Checks
#if DEBUG
final class PerformanceMonitor {
    static let shared = PerformanceMonitor()

    private var frameDropCount = 0
    private var lastFrameTime: CFTimeInterval = 0

    func startMonitoring() {
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
    }

    @objc private func tick(_ link: CADisplayLink) {
        let frameDuration = link.timestamp - lastFrameTime
        lastFrameTime = link.timestamp

        // Check for dropped frames (> 16.7ms)
        if frameDuration > 0.02 && lastFrameTime > 0 {
            frameDropCount += 1
            if frameDropCount > 10 {
                print("Warning: \(frameDropCount) dropped frames in last second")
                frameDropCount = 0
            }
        }
    }
}
#endif
```

---

## 6. Performance Checklist

### Pre-Release Verification

- [ ] Cold launch < 1.0s on iPhone XR (baseline device)
- [ ] 60 FPS maintained during scrolling
- [ ] Food search < 100ms for 10K+ items
- [ ] Memory stays < 150MB during normal use
- [ ] No memory leaks (Instruments Leaks)
- [ ] No main thread blocking (Time Profiler)
- [ ] Background refresh completes within limits
- [ ] Widget updates without visible delay
- [ ] Camera capture < 500ms
- [ ] AI analysis < 2s (cloud), < 300ms (on-device)

### Device Testing Matrix

| Device | iOS | Priority | Notes |
|--------|-----|----------|-------|
| iPhone 15 Pro | iOS 17 | High | Neural Engine, ProMotion |
| iPhone 14 | iOS 17 | High | Standard flagship |
| iPhone SE 3 | iOS 17 | High | Entry device |
| iPhone XR | iOS 16 | High | Baseline performance |
| iPhone 11 | iOS 16 | Medium | Mid-range |

---

*Architecture documentation complete. Ready for Manager review.*
