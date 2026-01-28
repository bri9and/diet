# HealthKit Integration Spec
## Diet App - Agent 04

---

## 1. Data Types Overview

### Read Permissions (FROM HealthKit)

| Data Type | Identifier | Purpose |
|-----------|------------|---------|
| Body Mass | `HKQuantityTypeIdentifier.bodyMass` | Track weight trends |
| Body Fat % | `HKQuantityTypeIdentifier.bodyFatPercentage` | Body composition |
| Lean Body Mass | `HKQuantityTypeIdentifier.leanBodyMass` | Muscle tracking |
| Active Energy | `HKQuantityTypeIdentifier.activeEnergyBurned` | Adjust calorie goals |
| Basal Energy | `HKQuantityTypeIdentifier.basalEnergyBurned` | TDEE calculation |
| Step Count | `HKQuantityTypeIdentifier.stepCount` | Activity indicator |
| Workouts | `HKWorkoutType.workoutType()` | Exercise adjustments |
| Water | `HKQuantityTypeIdentifier.dietaryWater` | Hydration sync |

### Write Permissions (TO HealthKit)

| Data Type | Identifier | Purpose |
|-----------|------------|---------|
| Dietary Energy | `HKQuantityTypeIdentifier.dietaryEnergyConsumed` | Log calories |
| Dietary Protein | `HKQuantityTypeIdentifier.dietaryProtein` | Log protein |
| Dietary Carbs | `HKQuantityTypeIdentifier.dietaryCarbohydrates` | Log carbs |
| Dietary Fat | `HKQuantityTypeIdentifier.dietaryFatTotal` | Log fat |
| Dietary Fiber | `HKQuantityTypeIdentifier.dietaryFiber` | Log fiber |
| Dietary Sugar | `HKQuantityTypeIdentifier.dietarySugar` | Log sugar |
| Dietary Sodium | `HKQuantityTypeIdentifier.dietarySodium` | Log sodium |
| Dietary Cholesterol | `HKQuantityTypeIdentifier.dietaryCholesterol` | Log cholesterol |
| Dietary Saturated Fat | `HKQuantityTypeIdentifier.dietaryFatSaturated` | Log sat fat |
| Water | `HKQuantityTypeIdentifier.dietaryWater` | Log hydration |
| Body Mass | `HKQuantityTypeIdentifier.bodyMass` | Write weight entries |

---

## 2. Permission Request Flow

```swift
import HealthKit

// MARK: - HealthKit Permissions
struct HealthKitPermissions {
    // Types we read FROM HealthKit
    static let readTypes: Set<HKObjectType> = [
        HKQuantityType(.bodyMass),
        HKQuantityType(.bodyFatPercentage),
        HKQuantityType(.leanBodyMass),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.basalEnergyBurned),
        HKQuantityType(.stepCount),
        HKQuantityType(.dietaryWater),
        HKWorkoutType.workoutType()
    ]

    // Types we write TO HealthKit
    static let writeTypes: Set<HKSampleType> = [
        HKQuantityType(.dietaryEnergyConsumed),
        HKQuantityType(.dietaryProtein),
        HKQuantityType(.dietaryCarbohydrates),
        HKQuantityType(.dietaryFatTotal),
        HKQuantityType(.dietaryFiber),
        HKQuantityType(.dietarySugar),
        HKQuantityType(.dietarySodium),
        HKQuantityType(.dietaryCholesterol),
        HKQuantityType(.dietaryFatSaturated),
        HKQuantityType(.dietaryWater),
        HKQuantityType(.bodyMass)
    ]

    // Minimal set for onboarding (expand later)
    static let onboardingReadTypes: Set<HKObjectType> = [
        HKQuantityType(.bodyMass),
        HKQuantityType(.activeEnergyBurned),
        HKWorkoutType.workoutType()
    ]

    static let onboardingWriteTypes: Set<HKSampleType> = [
        HKQuantityType(.dietaryEnergyConsumed),
        HKQuantityType(.dietaryProtein),
        HKQuantityType(.dietaryCarbohydrates),
        HKQuantityType(.dietaryFatTotal)
    ]
}

// MARK: - HealthKit Manager
final class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()

    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var lastSyncDate: Date?

    enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied
        case unavailable
    }

    // MARK: - Availability Check

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestOnboardingAuthorization() async throws {
        guard isAvailable else {
            authorizationStatus = .unavailable
            throw HealthKitError.unavailable
        }

        try await healthStore.requestAuthorization(
            toShare: HealthKitPermissions.onboardingWriteTypes,
            read: HealthKitPermissions.onboardingReadTypes
        )

        await updateAuthorizationStatus()
    }

    func requestFullAuthorization() async throws {
        guard isAvailable else {
            authorizationStatus = .unavailable
            throw HealthKitError.unavailable
        }

        try await healthStore.requestAuthorization(
            toShare: HealthKitPermissions.writeTypes,
            read: HealthKitPermissions.readTypes
        )

        await updateAuthorizationStatus()
    }

    @MainActor
    private func updateAuthorizationStatus() {
        // Check a representative type
        let status = healthStore.authorizationStatus(for: HKQuantityType(.dietaryEnergyConsumed))

        switch status {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .sharingAuthorized:
            authorizationStatus = .authorized
        case .sharingDenied:
            authorizationStatus = .denied
        @unknown default:
            authorizationStatus = .notDetermined
        }
    }

    // MARK: - Error Types

    enum HealthKitError: LocalizedError {
        case unavailable
        case notAuthorized
        case queryFailed(Error)
        case saveFailed(Error)

        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "HealthKit is not available on this device"
            case .notAuthorized:
                return "HealthKit access has not been authorized"
            case .queryFailed(let error):
                return "Failed to query HealthKit: \(error.localizedDescription)"
            case .saveFailed(let error):
                return "Failed to save to HealthKit: \(error.localizedDescription)"
            }
        }
    }
}
```

### Onboarding Permission UI

```swift
struct HealthKitPermissionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.appEnvironment) private var environment

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.theme.primary)

                Text("Connect to Apple Health")
                    .font(.title2.bold())

                Text("Sync your nutrition data and track your progress alongside your other health metrics.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            // Benefits
            VStack(alignment: .leading, spacing: 16) {
                BenefitRow(
                    icon: "arrow.left.arrow.right",
                    title: "Two-way sync",
                    description: "Your logged meals appear in Apple Health"
                )

                BenefitRow(
                    icon: "figure.run",
                    title: "Smart calorie adjustment",
                    description: "We read your workouts to adjust daily goals"
                )

                BenefitRow(
                    icon: "scalemass",
                    title: "Weight tracking",
                    description: "Keep weight data in sync across apps"
                )
            }
            .padding()
            .background(Color.theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            // Privacy note
            Text("Your health data stays private and is never shared with third parties.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Actions
            VStack(spacing: 12) {
                Button("Connect Apple Health") {
                    Task {
                        await viewModel.requestHealthKitAccess()
                    }
                }
                .buttonStyle(.primary)

                Button("Skip for now") {
                    viewModel.skipHealthKit()
                }
                .buttonStyle(.secondary)
            }
        }
        .padding()
    }
}
```

---

## 3. Reading Data from HealthKit

```swift
extension HealthKitManager {
    // MARK: - Read Weight

    func fetchLatestWeight() async throws -> (weight: Double, date: Date)? {
        let weightType = HKQuantityType(.bodyMass)

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            // Handled via continuation below
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let weightKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: (weightKg, sample.startDate))
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Read Weight History

    func fetchWeightHistory(days: Int = 30) async throws -> [(weight: Double, date: Date)] {
        let weightType = HKQuantityType(.bodyMass)
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: Date(),
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                let results = (samples as? [HKQuantitySample])?.map { sample in
                    (sample.quantity.doubleValue(for: .gramUnit(with: .kilo)), sample.startDate)
                } ?? []

                continuation.resume(returning: results)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Read Active Energy (Today)

    func fetchTodayActiveEnergy() async throws -> Double {
        let energyType = HKQuantityType(.activeEnergyBurned)
        let startOfDay = Calendar.current.startOfDay(for: Date())

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                let energy = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: energy)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Read Workouts (Today)

    func fetchTodayWorkouts() async throws -> [WorkoutSummary] {
        let startOfDay = Calendar.current.startOfDay(for: Date())

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKWorkoutType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                let workouts = (samples as? [HKWorkout])?.map { workout in
                    WorkoutSummary(
                        activityType: workout.workoutActivityType,
                        duration: workout.duration,
                        calories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                        startDate: workout.startDate,
                        endDate: workout.endDate
                    )
                } ?? []

                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
        }
    }
}

// MARK: - Workout Summary
struct WorkoutSummary {
    let activityType: HKWorkoutActivityType
    let duration: TimeInterval
    let calories: Double
    let startDate: Date
    let endDate: Date

    var displayName: String {
        switch activityType {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .functionalStrengthTraining: return "Strength Training"
        case .yoga: return "Yoga"
        case .hiking: return "Hiking"
        default: return "Workout"
        }
    }
}
```

---

## 4. Writing Data to HealthKit

```swift
extension HealthKitManager {
    // MARK: - Write Nutrition

    func writeNutrition(from foodLog: FoodLogRecord) async throws {
        let samples = buildNutritionSamples(from: foodLog)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(samples) { success, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.saveFailed(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func buildNutritionSamples(from log: FoodLogRecord) -> [HKQuantitySample] {
        var samples: [HKQuantitySample] = []

        let metadata: [String: Any] = [
            HKMetadataKeyFoodType: log.notes ?? "Logged meal",
            "DietAppLogId": log.id
        ]

        // Calories
        let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: log.calories)
        samples.append(HKQuantitySample(
            type: HKQuantityType(.dietaryEnergyConsumed),
            quantity: calorieQuantity,
            start: log.loggedAt,
            end: log.loggedAt,
            metadata: metadata
        ))

        // Protein
        let proteinQuantity = HKQuantity(unit: .gram(), doubleValue: log.protein)
        samples.append(HKQuantitySample(
            type: HKQuantityType(.dietaryProtein),
            quantity: proteinQuantity,
            start: log.loggedAt,
            end: log.loggedAt,
            metadata: metadata
        ))

        // Carbs
        let carbsQuantity = HKQuantity(unit: .gram(), doubleValue: log.carbs)
        samples.append(HKQuantitySample(
            type: HKQuantityType(.dietaryCarbohydrates),
            quantity: carbsQuantity,
            start: log.loggedAt,
            end: log.loggedAt,
            metadata: metadata
        ))

        // Fat
        let fatQuantity = HKQuantity(unit: .gram(), doubleValue: log.fat)
        samples.append(HKQuantitySample(
            type: HKQuantityType(.dietaryFatTotal),
            quantity: fatQuantity,
            start: log.loggedAt,
            end: log.loggedAt,
            metadata: metadata
        ))

        // Fiber (optional)
        if let fiber = log.fiber {
            let fiberQuantity = HKQuantity(unit: .gram(), doubleValue: fiber)
            samples.append(HKQuantitySample(
                type: HKQuantityType(.dietaryFiber),
                quantity: fiberQuantity,
                start: log.loggedAt,
                end: log.loggedAt,
                metadata: metadata
            ))
        }

        return samples
    }

    // MARK: - Write Weight

    func writeWeight(_ weightKg: Double, date: Date = Date()) async throws {
        let weightType = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)

        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: date,
            end: date,
            metadata: ["Source": "DietApp"]
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(sample) { success, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.saveFailed(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Write Water

    func writeWater(_ milliliters: Double, date: Date = Date()) async throws {
        let waterType = HKQuantityType(.dietaryWater)
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: milliliters)

        let sample = HKQuantitySample(
            type: waterType,
            quantity: quantity,
            start: date,
            end: date
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(sample) { success, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.saveFailed(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Delete Sample

    func deleteNutrition(logId: String) async throws {
        // Find samples with our log ID
        let types: [HKQuantityType] = [
            HKQuantityType(.dietaryEnergyConsumed),
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryCarbohydrates),
            HKQuantityType(.dietaryFatTotal),
            HKQuantityType(.dietaryFiber)
        ]

        for type in types {
            let predicate = HKQuery.predicateForObjects(
                withMetadataKey: "DietAppLogId",
                allowedValues: [logId]
            )

            let samples = try await querySamples(type: type, predicate: predicate)

            if !samples.isEmpty {
                try await deleteSamples(samples)
            }
        }
    }

    private func querySamples(type: HKSampleType, predicate: NSPredicate) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                } else {
                    continuation.resume(returning: samples ?? [])
                }
            }

            healthStore.execute(query)
        }
    }

    private func deleteSamples(_ samples: [HKSample]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.delete(samples) { success, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.saveFailed(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
```

---

## 5. Background Delivery Setup

```swift
extension HealthKitManager {
    // MARK: - Background Delivery

    func enableBackgroundDelivery() {
        let typesToObserve: [HKQuantityType] = [
            HKQuantityType(.bodyMass),
            HKQuantityType(.activeEnergyBurned)
        ]

        for type in typesToObserve {
            healthStore.enableBackgroundDelivery(
                for: type,
                frequency: .immediate
            ) { success, error in
                if let error {
                    print("Background delivery error for \(type): \(error)")
                }
            }
        }
    }

    func setupObserverQueries() {
        // Weight observer
        let weightType = HKQuantityType(.bodyMass)
        let weightQuery = HKObserverQuery(sampleType: weightType, predicate: nil) { [weak self] _, completionHandler, error in
            if error == nil {
                Task {
                    await self?.handleWeightUpdate()
                }
            }
            completionHandler()
        }
        healthStore.execute(weightQuery)

        // Active energy observer
        let energyType = HKQuantityType(.activeEnergyBurned)
        let energyQuery = HKObserverQuery(sampleType: energyType, predicate: nil) { [weak self] _, completionHandler, error in
            if error == nil {
                Task {
                    await self?.handleEnergyUpdate()
                }
            }
            completionHandler()
        }
        healthStore.execute(energyQuery)
    }

    @MainActor
    private func handleWeightUpdate() async {
        // Notify app of weight change
        NotificationCenter.default.post(name: .healthKitWeightUpdated, object: nil)
    }

    @MainActor
    private func handleEnergyUpdate() async {
        // Recalculate calorie budget
        NotificationCenter.default.post(name: .healthKitEnergyUpdated, object: nil)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let healthKitWeightUpdated = Notification.Name("healthKitWeightUpdated")
    static let healthKitEnergyUpdated = Notification.Name("healthKitEnergyUpdated")
}
```

---

## 6. Sync Frequency & Strategy

| Data Type | Sync Direction | Frequency | Trigger |
|-----------|---------------|-----------|---------|
| Weight | Bidirectional | On change | Observer query |
| Active Energy | Read only | Hourly + on demand | Timer + app foreground |
| Workouts | Read only | On demand | App foreground, user action |
| Nutrition | Write only | Immediate | On food log save |
| Water | Bidirectional | Immediate | On log / observer |

### Sync Strategy

```swift
final class HealthKitSyncService {
    private let healthKit: HealthKitManager
    private let weightRepo: WeightRepository
    private let foodLogRepo: FoodLogRepository

    private var syncTimer: Timer?

    init(healthKit: HealthKitManager, weightRepo: WeightRepository, foodLogRepo: FoodLogRepository) {
        self.healthKit = healthKit
        self.weightRepo = weightRepo
        self.foodLogRepo = foodLogRepo

        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWeightUpdate),
            name: .healthKitWeightUpdated,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    // MARK: - Weight Sync

    @objc private func handleWeightUpdate() {
        Task {
            await syncWeightFromHealthKit()
        }
    }

    func syncWeightFromHealthKit() async {
        do {
            guard let (weight, date) = try await healthKit.fetchLatestWeight() else { return }

            // Check if we already have this entry
            let existing = try await weightRepo.fetchByDate(date)
            if existing == nil {
                let record = WeightLogRecord(
                    id: UUID().uuidString,
                    userId: CurrentUser.id,
                    weight: weight,
                    bodyFatPercent: nil,
                    date: date,
                    source: .healthkit,
                    notes: nil,
                    createdAt: Date(),
                    synced: true
                )
                try await weightRepo.save(record)
            }
        } catch {
            print("Weight sync error: \(error)")
        }
    }

    // MARK: - Energy Sync

    @objc private func handleAppForeground() {
        Task {
            await refreshActiveEnergy()
        }
    }

    func refreshActiveEnergy() async {
        do {
            let activeEnergy = try await healthKit.fetchTodayActiveEnergy()

            // Post update for calorie adjustment
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .activeEnergyUpdated,
                    object: nil,
                    userInfo: ["activeEnergy": activeEnergy]
                )
            }
        } catch {
            print("Energy sync error: \(error)")
        }
    }

    // MARK: - Write to HealthKit

    func syncFoodLogToHealthKit(_ log: FoodLogRecord) async {
        do {
            try await healthKit.writeNutrition(from: log)
        } catch {
            print("Failed to write nutrition to HealthKit: \(error)")
            // Queue for retry
        }
    }

    func syncWeightToHealthKit(_ weight: Double, date: Date) async {
        do {
            try await healthKit.writeWeight(weight, date: date)
        } catch {
            print("Failed to write weight to HealthKit: \(error)")
        }
    }
}

extension Notification.Name {
    static let activeEnergyUpdated = Notification.Name("activeEnergyUpdated")
}
```

---

## 7. Info.plist Configuration

```xml
<key>NSHealthShareUsageDescription</key>
<string>We read your weight and workout data to personalize your nutrition goals and track your progress.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>We save your logged meals and weight entries to Apple Health so all your health data stays in one place.</string>

<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
</array>

<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.dietapp.healthkit.sync</string>
</array>
```

---

*Document continues in WIDGET_ARCHITECTURE.md*
