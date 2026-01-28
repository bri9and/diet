import SwiftUI

/// Onboarding flow for new users
public struct OnboardingView: View {

    // MARK: - Properties

    @StateObject private var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss

    let onComplete: () -> Void

    // MARK: - Initialization

    public init(foodService: FoodService, notificationService: NotificationService, onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(
            foodService: foodService,
            notificationService: notificationService
        ))
        self.onComplete = onComplete
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            progressIndicator

            // Page content
            TabView(selection: $viewModel.currentPage) {
                welcomePage.tag(0)
                goalsPage.tag(1)
                trackingPage.tag(2)
                notificationsPage.tag(3)
                readyPage.tag(4)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .animation(.easeInOut, value: viewModel.currentPage)

            // Navigation buttons
            navigationButtons
        }
        .background(Color.groupedBackground)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<5) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= viewModel.currentPage ? Color.blue : Color.secondary.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    // MARK: - Welcome Page

    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.blue)

            VStack(spacing: 16) {
                Text("Welcome to Diet App")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Track your nutrition effortlessly with AI-powered food recognition.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Goals Page

    private var goalsPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "target")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Set Your Goal")
                .font(.title)
                .fontWeight(.bold)

            Text("What would you like to achieve?")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                goalButton(type: .lose, icon: "arrow.down.circle", color: .blue)
                goalButton(type: .maintain, icon: "equal.circle", color: .green)
                goalButton(type: .gain, icon: "arrow.up.circle", color: .orange)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private func goalButton(type: GoalType, icon: String, color: Color) -> some View {
        Button {
            viewModel.selectedGoal = type
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title2)

                Text(type.displayName + " Weight")
                    .font(.headline)

                Spacer()

                if viewModel.selectedGoal == type {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(viewModel.selectedGoal == type ? color : Color.cardBackground)
            .foregroundStyle(viewModel.selectedGoal == type ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tracking Page

    private var trackingPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Easy Tracking")
                .font(.title)
                .fontWeight(.bold)

            Text("Multiple ways to log your food")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(spacing: 16) {
                trackingFeature(
                    icon: "camera.fill",
                    title: "Photo Recognition",
                    description: "Take a photo and AI identifies your food"
                )

                trackingFeature(
                    icon: "barcode.viewfinder",
                    title: "Barcode Scanner",
                    description: "Scan product barcodes for instant logging"
                )

                trackingFeature(
                    icon: "mic.fill",
                    title: "Voice Input",
                    description: "Describe what you ate and we'll log it"
                )

                trackingFeature(
                    icon: "magnifyingglass",
                    title: "Food Search",
                    description: "Search our database of foods"
                )
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func trackingFeature(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Notifications Page

    private var notificationsPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)

            VStack(spacing: 16) {
                Text("Stay on Track")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Get reminders to log your meals and celebrate your progress.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Toggle("Meal Reminders", isOn: $viewModel.enableNotifications)
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)

            if viewModel.enableNotifications {
                Text("You can customize reminder times in Settings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Ready Page

    private var readyPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.green)

            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Start tracking your nutrition today.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if viewModel.currentPage > 0 {
                Button("Back") {
                    withAnimation {
                        viewModel.currentPage -= 1
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Button(viewModel.currentPage == 4 ? "Get Started" : "Continue") {
                if viewModel.currentPage == 4 {
                    Task {
                        await viewModel.completeOnboarding()
                        onComplete()
                    }
                } else {
                    withAnimation {
                        viewModel.currentPage += 1
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.currentPage == 1 && viewModel.selectedGoal == nil)
        }
        .padding(24)
    }
}

// MARK: - View Model

@MainActor
public final class OnboardingViewModel: ObservableObject {

    @Published public var currentPage = 0
    @Published public var selectedGoal: GoalType? = .maintain
    @Published public var enableNotifications = true

    private let foodService: FoodService
    private let notificationService: NotificationService

    public init(foodService: FoodService, notificationService: NotificationService) {
        self.foodService = foodService
        self.notificationService = notificationService
    }

    public func completeOnboarding() async {
        // Save goal
        if let goal = selectedGoal {
            let calorieGoal: Int
            switch goal {
            case .lose: calorieGoal = 1800
            case .maintain: calorieGoal = 2000
            case .gain: calorieGoal = 2500
            }

            let request = UpdateGoalsRequest(
                dailyCalories: calorieGoal,
                dailyProteinG: 50,
                dailyCarbsG: 250,
                dailyFatG: 65,
                goalType: goal.rawValue
            )

            do {
                _ = try await foodService.updateGoals(request)
            } catch {
                print("Failed to save goals: \(error)")
            }
        }

        // Request notification permission
        if enableNotifications {
            _ = await notificationService.requestPermission()
        }

        // Mark onboarding complete
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Onboarding Check

public extension UserDefaults {
    var hasCompletedOnboarding: Bool {
        bool(forKey: "hasCompletedOnboarding")
    }
}
