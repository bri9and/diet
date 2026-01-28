import SwiftUI

/// View for managing notification preferences
public struct NotificationSettingsView: View {

    // MARK: - Properties

    @StateObject private var viewModel: NotificationSettingsViewModel

    // MARK: - Initialization

    public init(notificationService: NotificationService) {
        _viewModel = StateObject(wrappedValue: NotificationSettingsViewModel(notificationService: notificationService))
    }

    // MARK: - Body

    public var body: some View {
        List {
            // Permission section
            if !viewModel.isAuthorized {
                Section {
                    permissionPrompt
                }
            }

            // Meal reminders
            Section {
                Toggle("Meal Reminders", isOn: $viewModel.mealReminders)
                    .onChange(of: viewModel.mealReminders) { _, _ in
                        viewModel.savePreferences()
                    }

                if viewModel.mealReminders {
                    timePicker(label: "Breakfast", time: $viewModel.breakfastTime)
                    timePicker(label: "Lunch", time: $viewModel.lunchTime)
                    timePicker(label: "Dinner", time: $viewModel.dinnerTime)
                }
            } header: {
                Text("Reminders")
            } footer: {
                Text("Get reminded to log your meals at specific times.")
            }

            // Other notifications
            Section {
                Toggle("Weekly Digest", isOn: $viewModel.weeklyDigest)
                    .onChange(of: viewModel.weeklyDigest) { _, _ in
                        viewModel.savePreferences()
                    }

                Toggle("Goal Progress", isOn: $viewModel.goalProgress)
                    .onChange(of: viewModel.goalProgress) { _, _ in
                        viewModel.savePreferences()
                    }

                Toggle("Streak Reminders", isOn: $viewModel.streakReminders)
                    .onChange(of: viewModel.streakReminders) { _, _ in
                        viewModel.savePreferences()
                    }
            } header: {
                Text("Updates")
            }
        }
        .navigationTitle("Notifications")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await viewModel.load()
        }
        .disabled(!viewModel.isAuthorized)
    }

    // MARK: - Permission Prompt

    private var permissionPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.badge")
                    .font(.title)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Notifications")
                        .font(.headline)

                    Text("Get reminders to log your meals and track your progress.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button("Enable Notifications") {
                Task {
                    await viewModel.requestPermission()
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Time Picker

    private func timePicker(label: String, time: Binding<Date>) -> some View {
        DatePicker(
            label,
            selection: time,
            displayedComponents: .hourAndMinute
        )
        .onChange(of: time.wrappedValue) { _, _ in
            viewModel.savePreferences()
        }
    }
}

// MARK: - View Model

@MainActor
public final class NotificationSettingsViewModel: ObservableObject {

    @Published public var isAuthorized = false
    @Published public var mealReminders = true
    @Published public var breakfastTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @Published public var lunchTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
    @Published public var dinnerTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
    @Published public var weeklyDigest = true
    @Published public var goalProgress = true
    @Published public var streakReminders = true

    private let notificationService: NotificationService
    private var saveTask: Task<Void, Never>?

    public init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }

    public func load() async {
        await notificationService.checkPermission()
        isAuthorized = notificationService.isAuthorized

        await notificationService.loadPreferences()

        if let prefs = notificationService.preferences {
            mealReminders = prefs.mealReminders
            weeklyDigest = prefs.weeklyDigest
            goalProgress = prefs.goalProgress
            streakReminders = prefs.streakReminders

            breakfastTime = parseTime(prefs.mealReminderTimes.breakfast) ?? breakfastTime
            lunchTime = parseTime(prefs.mealReminderTimes.lunch) ?? lunchTime
            dinnerTime = parseTime(prefs.mealReminderTimes.dinner) ?? dinnerTime
        }
    }

    public func requestPermission() async {
        let granted = await notificationService.requestPermission()
        isAuthorized = granted
    }

    public func savePreferences() {
        // Debounce saves
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))

            guard !Task.isCancelled else { return }

            let updates = UpdateNotificationPreferences(
                mealReminders: mealReminders,
                mealReminderTimes: MealReminderTimesUpdate(
                    breakfast: formatTime(breakfastTime),
                    lunch: formatTime(lunchTime),
                    dinner: formatTime(dinnerTime)
                ),
                weeklyDigest: weeklyDigest,
                goalProgress: goalProgress,
                streakReminders: streakReminders
            )

            do {
                try await notificationService.updatePreferences(updates)

                // Update local notification schedules
                if mealReminders {
                    await notificationService.scheduleAllMealReminders()
                } else {
                    await notificationService.cancelMealReminders()
                }
            } catch {
                print("Failed to save preferences: \(error)")
            }
        }
    }

    private func parseTime(_ timeString: String) -> Date? {
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return nil }
        return Calendar.current.date(from: DateComponents(hour: components[0], minute: components[1]))
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
