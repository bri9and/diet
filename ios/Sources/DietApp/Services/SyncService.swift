import Foundation
import Combine

/// Service for syncing data between device and server
@MainActor
public final class SyncService: ObservableObject {

    // MARK: - Published State

    @Published public var isSyncing = false
    @Published public var lastSyncAt: Date?
    @Published public var syncError: String?

    // MARK: - Dependencies

    private let apiClient: APIClient
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Storage Keys

    private let lastSyncKey = "lastSyncTimestamp"

    // MARK: - Initialization

    public init(apiClient: APIClient) {
        self.apiClient = apiClient

        // Load last sync time
        if let timestamp = UserDefaults.standard.string(forKey: lastSyncKey),
           let date = ISO8601DateFormatter().date(from: timestamp) {
            lastSyncAt = date
        }
    }

    // MARK: - Sync Methods

    /// Perform a full sync with the server
    public func sync() async {
        guard !isSyncing else { return }

        isSyncing = true
        syncError = nil

        do {
            var path = "/sync"
            if let lastSync = lastSyncAt {
                let timestamp = ISO8601DateFormatter().string(from: lastSync)
                path += "?since=\(timestamp)"
            }

            let response: SyncResponse = try await apiClient.get(path)

            // Update last sync time
            if let syncedAt = ISO8601DateFormatter().date(from: response.syncedAt) {
                lastSyncAt = syncedAt
                UserDefaults.standard.set(response.syncedAt, forKey: lastSyncKey)
            }

            // Process synced data
            await processSyncData(response.data)

        } catch {
            syncError = "Sync failed. Will retry later."
            print("Sync error: \(error)")
        }

        isSyncing = false
    }

    /// Force a full resync
    public func forceResync() async {
        lastSyncAt = nil
        UserDefaults.standard.removeObject(forKey: lastSyncKey)
        await sync()
    }

    // MARK: - Data Processing

    private func processSyncData(_ data: SyncData) async {
        // Cache profile data
        if let profile = data.profile {
            cacheProfile(profile)
        }

        // Cache goals
        if let goals = data.goals {
            cacheGoals(goals)
        }

        // Cache notification preferences
        if let notifications = data.notifications {
            cacheNotificationPreferences(notifications)
        }

        // Note: Food logs are cached in the local database via FoodLogRepository
        // This sync response can be used to update local cache if needed
    }

    private func cacheProfile(_ profile: SyncProfile) {
        UserDefaults.standard.set(profile.displayName, forKey: "profile.displayName")
        UserDefaults.standard.set(profile.email, forKey: "profile.email")
        UserDefaults.standard.set(profile.avatarUrl, forKey: "profile.avatarUrl")
    }

    private func cacheGoals(_ goals: SyncGoals) {
        UserDefaults.standard.set(goals.dailyCalories, forKey: "goals.dailyCalories")
        UserDefaults.standard.set(goals.dailyProteinG, forKey: "goals.dailyProteinG")
        UserDefaults.standard.set(goals.dailyCarbsG, forKey: "goals.dailyCarbsG")
        UserDefaults.standard.set(goals.dailyFatG, forKey: "goals.dailyFatG")
        UserDefaults.standard.set(goals.goalType, forKey: "goals.goalType")
    }

    private func cacheNotificationPreferences(_ notifications: SyncNotifications) {
        UserDefaults.standard.set(notifications.mealReminders, forKey: "notifications.mealReminders")
        UserDefaults.standard.set(notifications.weeklyDigest, forKey: "notifications.weeklyDigest")
        UserDefaults.standard.set(notifications.goalProgress, forKey: "notifications.goalProgress")
    }

    // MARK: - Cached Getters

    public var cachedDisplayName: String? {
        UserDefaults.standard.string(forKey: "profile.displayName")
    }

    public var cachedDailyCaloriesGoal: Int {
        UserDefaults.standard.integer(forKey: "goals.dailyCalories").nonZeroOrDefault(2000)
    }

    public var cachedDailyProteinGoal: Int {
        UserDefaults.standard.integer(forKey: "goals.dailyProteinG").nonZeroOrDefault(50)
    }
}

// MARK: - Int Extension

extension Int {
    func nonZeroOrDefault(_ defaultValue: Int) -> Int {
        self != 0 ? self : defaultValue
    }
}

// MARK: - Sync Response Models

public struct SyncResponse: Decodable {
    public let success: Bool
    public let syncedAt: String
    public let data: SyncData
}

public struct SyncData: Decodable {
    public let profile: SyncProfile?
    public let goals: SyncGoals?
    public let foodLogs: [SyncFoodLog]?
    public let notifications: SyncNotifications?
}

public struct SyncProfile: Decodable {
    public let displayName: String?
    public let email: String?
    public let avatarUrl: String?
    public let heightCm: Double?
    public let currentWeightKg: Double?
    public let birthDate: String?
    public let gender: String?
}

public struct SyncGoals: Decodable {
    public let dailyCalories: Int
    public let dailyProteinG: Int
    public let dailyCarbsG: Int
    public let dailyFatG: Int
    public let goalType: String
    public let targetWeight: Double?
}

public struct SyncFoodLog: Decodable {
    public let id: String
    public let loggedDate: String
    public let mealType: String
    public let entryMethod: String
    public let items: [SyncFoodLogItem]
    public let updatedAt: String?
}

public struct SyncFoodLogItem: Decodable {
    public let quantity: Double
    public let nutrition: SyncNutrition
    public let foodSnapshot: SyncFoodSnapshot
}

public struct SyncNutrition: Decodable {
    public let calories: Double
    public let proteinG: Double
    public let carbsG: Double
    public let fatG: Double
}

public struct SyncFoodSnapshot: Decodable {
    public let name: String
    public let brand: String?
    public let servingDescription: String?
}

public struct SyncNotifications: Decodable {
    public let mealReminders: Bool
    public let mealReminderTimes: MealReminderTimes
    public let weeklyDigest: Bool
    public let goalProgress: Bool
    public let streakReminders: Bool
}
