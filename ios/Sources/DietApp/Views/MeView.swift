import SwiftUI
import PhotosUI
import Charts
import Clerk
#if canImport(UIKit)
import UIKit
#endif

/// Profile view showing user information and stats
public struct MeView: View {

    // MARK: - Environment

    @EnvironmentObject private var appEnvironment: AppEnvironment
    @Environment(\.clerk) private var clerk

    // MARK: - State

    @StateObject private var viewModel: MeViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingPhotoOptions = false

    // MARK: - Initialization

    public init(foodService: FoodService) {
        _viewModel = StateObject(wrappedValue: MeViewModel(foodService: foodService))
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    profileHeader

                    // Stats cards
                    statsSection

                    // Calorie Analytics
                    calorieAnalyticsSection

                    // Body info
                    bodyInfoSection

                    // Settings link
                    settingsLink
                }
                .padding()
            }
            .background(Color.groupedBackground)
            .task {
                await viewModel.loadProfile()
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar with photo picker
            Button {
                showingPhotoOptions = true
            } label: {
                ZStack {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay {
                                if let user = clerk.user, let initial = (user.firstName ?? user.username ?? "U").first {
                                    Text(String(initial).uppercased())
                                        .font(.system(size: 40, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                }
                            }
                    }

                    // Camera badge
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                        .offset(x: 35, y: 35)
                }
                .shadow(color: .green.opacity(0.3), radius: 10, y: 5)
            }
            .buttonStyle(.plain)
            .confirmationDialog("Change Profile Photo", isPresented: $showingPhotoOptions) {
                Button("Take Photo") {
                    showingImagePicker = true
                }
                Button("Choose from Library") {
                    showingImagePicker = true
                }
                if profileImage != nil {
                    Button("Remove Photo", role: .destructive) {
                        removeProfilePhoto()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let newItem = newItem {
                        await loadPhoto(from: newItem)
                    }
                }
            }

            // Name and email
            VStack(spacing: 4) {
                if let user = clerk.user {
                    Text(user.firstName ?? user.username ?? "User")
                        .font(.title2.weight(.bold))

                    if let email = user.primaryEmailAddress?.emailAddress {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            loadSavedProfileImage()
        }
    }

    // MARK: - Photo Helpers

    private func loadPhoto(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }

        await MainActor.run {
            profileImage = image
            saveProfileImage(image)
        }
    }

    private func saveProfileImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let url = getProfileImageURL()
        try? data.write(to: url)
    }

    private func loadSavedProfileImage() {
        let url = getProfileImageURL()
        if let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            profileImage = image
        }
    }

    private func removeProfilePhoto() {
        profileImage = nil
        let url = getProfileImageURL()
        try? FileManager.default.removeItem(at: url)
    }

    private func getProfileImageURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("profile_photo.jpg")
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 16) {
            statCard(
                title: "Streak",
                value: "\(viewModel.streak)",
                unit: "days",
                icon: "flame.fill",
                color: .orange
            )

            statCard(
                title: "Logged",
                value: "\(viewModel.totalMeals)",
                unit: "meals",
                icon: "fork.knife",
                color: .green
            )

            statCard(
                title: "Avg Cal",
                value: "\(viewModel.avgCalories)",
                unit: "daily",
                icon: "chart.bar.fill",
                color: .blue
            )
        }
    }

    private func statCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Body Info Section

    private var bodyInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Body")
                .font(.headline)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                infoRow(icon: "figure.stand", label: "Height", value: viewModel.heightDisplay, color: .blue)
                Divider().padding(.leading, 52)
                infoRow(icon: "scalemass", label: "Current Weight", value: viewModel.weightDisplay, color: .purple)
                Divider().padding(.leading, 52)
                infoRow(icon: "target", label: "Goal Weight", value: viewModel.goalWeightDisplay, color: .green)
                Divider().padding(.leading, 52)
                infoRow(icon: "calendar", label: "Age", value: viewModel.ageDisplay, color: .orange)
                Divider().padding(.leading, 52)
                infoRow(icon: "figure.walk", label: "Activity", value: viewModel.activityDisplay, color: .red)
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func infoRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(label)
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Calorie Analytics Section

    private var calorieAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Calorie Insights")
                .font(.headline)
                .padding(.leading, 4)

            // Averages row
            HStack(spacing: 12) {
                averageCard(
                    title: "Daily Avg",
                    value: viewModel.dailyAverageCalories,
                    color: .green
                )
                averageCard(
                    title: "Weekly Avg",
                    value: viewModel.weeklyAverageCalories,
                    color: .blue
                )
                averageCard(
                    title: "Monthly Avg",
                    value: viewModel.monthlyAverageCalories,
                    color: .purple
                )
            }

            // Calorie chart
            if !viewModel.dailyProgress.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last 7 Days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)

                    Chart(viewModel.chartData) { day in
                        BarMark(
                            x: .value("Day", day.dayLabel),
                            y: .value("Calories", day.calories)
                        )
                        .foregroundStyle(
                            day.calories >= viewModel.calorieGoal
                                ? Color.green.gradient
                                : Color.orange.gradient
                        )
                        .cornerRadius(4)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartYScale(domain: 0...(Double(viewModel.calorieGoal) * 1.5))
                    .chartPlotStyle { plotArea in
                        plotArea
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                    }
                    .frame(height: 180)
                    .padding(.horizontal, 4)

                    // Goal line legend
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Met goal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                            Text("Under goal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Goal: \(viewModel.calorieGoal) cal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func averageCard(title: String, value: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text("cal")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Settings Link

    private var settingsLink: some View {
        NavigationLink {
            SettingsView()
        } label: {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("Settings")
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chart Data Model

public struct CalorieChartData: Identifiable {
    public let id = UUID()
    public let date: Date
    public let dayLabel: String
    public let calories: Int
}

// MARK: - View Model

@MainActor
public final class MeViewModel: ObservableObject {

    @Published public var profile: UserProfile?
    @Published public var streak: Int = 0
    @Published public var totalMeals: Int = 0
    @Published public var avgCalories: Int = 0
    @Published public var dailyProgress: [DayProgress] = []
    @Published public var calorieGoal: Int = 2000

    private let foodService: FoodService

    public init(foodService: FoodService) {
        self.foodService = foodService
    }

    public func loadProfile() async {
        do {
            let profileResponse = try await foodService.getProfile()
            profile = profileResponse.profile

            // Load progress for stats
            let progressResponse = try await foodService.getProgress()
            streak = progressResponse.daysTracked
            avgCalories = progressResponse.weeklyAverage.calories
            dailyProgress = progressResponse.progress
            calorieGoal = progressResponse.goals.dailyCalories

            // Calculate total meals (rough estimate)
            totalMeals = progressResponse.daysTracked * 3
        } catch {
            print("Failed to load profile: \(error)")
        }
    }

    // MARK: - Calorie Analytics

    public var chartData: [CalorieChartData] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        return dailyProgress.suffix(7).compactMap { day in
            guard let date = formatter.date(from: day.date) else { return nil }
            return CalorieChartData(
                date: date,
                dayLabel: dayFormatter.string(from: date),
                calories: day.calories.consumed
            )
        }
    }

    public var dailyAverageCalories: Int {
        guard !dailyProgress.isEmpty else { return 0 }
        var total = 0
        for day in dailyProgress { total += day.calories.consumed }
        return total / dailyProgress.count
    }

    public var weeklyAverageCalories: Int {
        let lastWeek = Array(dailyProgress.suffix(7))
        guard !lastWeek.isEmpty else { return 0 }
        var total = 0
        for day in lastWeek { total += day.calories.consumed }
        return total / lastWeek.count
    }

    public var monthlyAverageCalories: Int {
        let lastMonth = Array(dailyProgress.suffix(30))
        guard !lastMonth.isEmpty else { return 0 }
        var total = 0
        for day in lastMonth { total += day.calories.consumed }
        return total / lastMonth.count
    }

    // MARK: - Computed Display Values

    public var heightDisplay: String {
        guard let height = profile?.heightCm else { return "Not set" }
        return "\(Int(height)) cm"
    }

    public var weightDisplay: String {
        guard let weight = profile?.currentWeightKg else { return "Not set" }
        return String(format: "%.1f kg", weight)
    }

    public var goalWeightDisplay: String {
        guard let weight = profile?.targetWeightKg else { return "Not set" }
        return String(format: "%.1f kg", weight)
    }

    public var ageDisplay: String {
        guard let birthDateStr = profile?.birthDate else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let birthDate = formatter.date(from: birthDateStr) else { return "Not set" }

        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        return "\(age) years"
    }

    public var activityDisplay: String {
        guard let level = profile?.activityLevel else { return "Not set" }
        switch level {
        case "sedentary": return "Sedentary"
        case "light": return "Lightly Active"
        case "moderate": return "Moderate"
        case "active": return "Very Active"
        case "very_active": return "Extra Active"
        default: return level.capitalized
        }
    }

}
