import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

/// Service for handling push notifications
@MainActor
public final class NotificationService: NSObject, ObservableObject {

    // MARK: - Published State

    @Published public var isAuthorized = false
    @Published public var deviceToken: String?
    @Published public var preferences: NotificationPreferencesData?

    // MARK: - Dependencies

    private let apiClient: APIClient

    // MARK: - Initialization

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
        super.init()
    }

    // MARK: - Permission

    public func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted

            if granted {
                await registerForRemoteNotifications()
            }

            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    public func checkPermission() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Remote Notifications

    private func registerForRemoteNotifications() async {
        #if os(iOS)
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
        #endif
    }

    public func handleDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString

        Task {
            await registerTokenWithServer(tokenString)
        }
    }

    public func handleRegistrationError(_ error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    private func registerTokenWithServer(_ token: String) async {
        do {
            let request = RegisterTokenRequest(token: token, platform: "ios")
            let _: EmptyResponse = try await apiClient.post("/device-token", body: request)
        } catch {
            print("Failed to register token with server: \(error)")
        }
    }

    public func unregisterToken() async {
        guard let token = deviceToken else { return }

        do {
            try await apiClient.delete("/device-token?token=\(token)")
        } catch {
            print("Failed to unregister token: \(error)")
        }
    }

    // MARK: - Preferences

    public func loadPreferences() async {
        do {
            let response: NotificationPreferencesResponse = try await apiClient.get("/notifications")
            preferences = response.preferences
        } catch {
            print("Failed to load notification preferences: \(error)")
        }
    }

    public func updatePreferences(_ updates: UpdateNotificationPreferences) async throws {
        let response: NotificationPreferencesResponse = try await apiClient.put("/notifications", body: updates)
        preferences = response.preferences
    }

    // MARK: - Local Notifications

    public func scheduleMealReminder(for mealType: String, at time: String) async {
        guard isAuthorized else { return }

        let center = UNUserNotificationCenter.current()

        // Parse time string (HH:mm)
        let components = time.split(separator: ":").map { Int($0) ?? 0 }
        guard components.count == 2 else { return }

        var dateComponents = DateComponents()
        dateComponents.hour = components[0]
        dateComponents.minute = components[1]

        let content = UNMutableNotificationContent()
        content.title = "Time for \(mealType)!"
        content.body = "Don't forget to log your \(mealType.lowercased())."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "meal-reminder-\(mealType.lowercased())",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule meal reminder: \(error)")
        }
    }

    public func cancelMealReminders() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            "meal-reminder-breakfast",
            "meal-reminder-lunch",
            "meal-reminder-dinner"
        ])
    }

    public func scheduleAllMealReminders() async {
        guard let prefs = preferences, prefs.mealReminders else { return }

        await scheduleMealReminder(for: "Breakfast", at: prefs.mealReminderTimes.breakfast)
        await scheduleMealReminder(for: "Lunch", at: prefs.mealReminderTimes.lunch)
        await scheduleMealReminder(for: "Dinner", at: prefs.mealReminderTimes.dinner)
    }
}

// MARK: - API Models

struct RegisterTokenRequest: Encodable {
    let token: String
    let platform: String
}

struct EmptyResponse: Decodable {}

public struct NotificationPreferencesResponse: Decodable {
    public let success: Bool
    public let preferences: NotificationPreferencesData
}

public struct NotificationPreferencesData: Decodable {
    public let mealReminders: Bool
    public let mealReminderTimes: MealReminderTimes
    public let weeklyDigest: Bool
    public let goalProgress: Bool
    public let streakReminders: Bool
    public let timezone: String
}

public struct MealReminderTimes: Decodable {
    public let breakfast: String
    public let lunch: String
    public let dinner: String
}

public struct UpdateNotificationPreferences: Encodable {
    public var mealReminders: Bool?
    public var mealReminderTimes: MealReminderTimesUpdate?
    public var weeklyDigest: Bool?
    public var goalProgress: Bool?
    public var streakReminders: Bool?
    public var timezone: String?

    public init(
        mealReminders: Bool? = nil,
        mealReminderTimes: MealReminderTimesUpdate? = nil,
        weeklyDigest: Bool? = nil,
        goalProgress: Bool? = nil,
        streakReminders: Bool? = nil,
        timezone: String? = nil
    ) {
        self.mealReminders = mealReminders
        self.mealReminderTimes = mealReminderTimes
        self.weeklyDigest = weeklyDigest
        self.goalProgress = goalProgress
        self.streakReminders = streakReminders
        self.timezone = timezone
    }
}

public struct MealReminderTimesUpdate: Encodable {
    public let breakfast: String
    public let lunch: String
    public let dinner: String

    public init(breakfast: String, lunch: String, dinner: String) {
        self.breakfast = breakfast
        self.lunch = lunch
        self.dinner = dinner
    }
}
