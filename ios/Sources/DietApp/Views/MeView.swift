import SwiftUI
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

                    // Body info
                    bodyInfoSection

                    // Goals section
                    goalsSection

                    // Settings link
                    settingsLink
                }
                .padding()
            }
            .background(Color.groupedBackground)
            .navigationTitle("Me")
            .task {
                await viewModel.loadProfile()
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
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
                .shadow(color: .green.opacity(0.3), radius: 10, y: 5)

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

    // MARK: - Goals Section

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Goals")
                .font(.headline)
                .padding(.leading, 4)

            HStack(spacing: 12) {
                goalCard(label: "Calories", value: "\(viewModel.calorieGoal)", color: .green)
                goalCard(label: "Protein", value: "\(viewModel.proteinGoal)g", color: .blue)
                goalCard(label: "Carbs", value: "\(viewModel.carbsGoal)g", color: .orange)
                goalCard(label: "Fat", value: "\(viewModel.fatGoal)g", color: .purple)
            }
        }
    }

    private func goalCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
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

// MARK: - View Model

@MainActor
public final class MeViewModel: ObservableObject {

    @Published public var profile: UserProfile?
    @Published public var goals: UserGoals?
    @Published public var streak: Int = 0
    @Published public var totalMeals: Int = 0
    @Published public var avgCalories: Int = 0

    private let foodService: FoodService

    public init(foodService: FoodService) {
        self.foodService = foodService
    }

    public func loadProfile() async {
        do {
            let profileResponse = try await foodService.getProfile()
            profile = profileResponse.profile

            let goalsResponse = try await foodService.getGoals()
            goals = goalsResponse.goals

            // Load progress for stats
            let progressResponse = try await foodService.getProgress()
            streak = progressResponse.daysTracked
            avgCalories = progressResponse.weeklyAverage.calories

            // Calculate total meals (rough estimate)
            totalMeals = progressResponse.daysTracked * 3
        } catch {
            print("Failed to load profile: \(error)")
        }
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

    public var calorieGoal: Int {
        goals?.dailyCalories ?? 2000
    }

    public var proteinGoal: Int {
        goals?.dailyProteinG ?? 50
    }

    public var carbsGoal: Int {
        goals?.dailyCarbsG ?? 250
    }

    public var fatGoal: Int {
        goals?.dailyFatG ?? 65
    }
}
