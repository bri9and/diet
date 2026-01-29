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
                genderPage.tag(1)
                measurementsPage.tag(2)
                goalsPage.tag(3)
                activityPage.tag(4)
                resultsPage.tag(5)
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
            ForEach(0..<6) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= viewModel.currentPage ? Color.green : Color.secondary.opacity(0.3))
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

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .green.opacity(0.3), radius: 20, y: 10)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }

            VStack(spacing: 16) {
                Text("Welcome to Fuelvio")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Let's personalize your experience by setting up your profile and calculating your optimal calorie goals.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Gender Page

    private var genderPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("What's your biological sex?")
                .font(.title)
                .fontWeight(.bold)

            Text("This helps us calculate your metabolism accurately")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                genderButton(gender: "male", icon: "figure.stand", label: "Male")
                genderButton(gender: "female", icon: "figure.stand.dress", label: "Female")
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private func genderButton(gender: String, icon: String, label: String) -> some View {
        Button {
            viewModel.gender = gender
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title2)

                Text(label)
                    .font(.headline)

                Spacer()

                if viewModel.gender == gender {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(viewModel.gender == gender ? Color.blue : Color.cardBackground)
            .foregroundStyle(viewModel.gender == gender ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Measurements Page

    private var measurementsPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "ruler")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                    .padding(.top, 40)

                Text("Your Measurements")
                    .font(.title)
                    .fontWeight(.bold)

                // Birth Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Birth Date")
                        .font(.headline)

                    DatePicker(
                        "Birth Date",
                        selection: $viewModel.birthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)

                // Height
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height")
                        .font(.headline)

                    HStack {
                        Text("\(Int(viewModel.heightCm)) cm")
                            .font(.system(size: 32, weight: .bold, design: .rounded))

                        Spacer()

                        Stepper("", value: $viewModel.heightCm, in: 100...250, step: 1)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)

                // Current Weight
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Weight")
                        .font(.headline)

                    HStack {
                        Text(String(format: "%.1f kg", viewModel.currentWeightKg))
                            .font(.system(size: 32, weight: .bold, design: .rounded))

                        Spacer()

                        Stepper("", value: $viewModel.currentWeightKg, in: 30...300, step: 0.5)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 100)
            }
        }
    }

    // MARK: - Goals Page

    private var goalsPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "target")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                    .padding(.top, 40)

                Text("What's Your Goal?")
                    .font(.title)
                    .fontWeight(.bold)

                VStack(spacing: 12) {
                    goalButton(type: .lose, icon: "arrow.down.circle.fill", color: .blue, description: "Burn fat and slim down")
                    goalButton(type: .maintain, icon: "equal.circle.fill", color: .green, description: "Stay at current weight")
                    goalButton(type: .gain, icon: "arrow.up.circle.fill", color: .orange, description: "Build muscle and mass")
                }
                .padding(.horizontal, 24)

                // Target Weight (only show if lose or gain)
                if viewModel.selectedGoal != .maintain {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Weight")
                            .font(.headline)

                        HStack {
                            Text(String(format: "%.1f kg", viewModel.targetWeightKg))
                                .font(.system(size: 32, weight: .bold, design: .rounded))

                            Spacer()

                            Stepper("", value: $viewModel.targetWeightKg, in: 30...300, step: 0.5)
                                .labelsHidden()
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer(minLength: 100)
            }
        }
        .animation(.easeInOut, value: viewModel.selectedGoal)
    }

    private func goalButton(type: GoalType, icon: String, color: Color, description: String) -> some View {
        Button {
            viewModel.selectedGoal = type
            // Set default target weight based on goal
            if type == .lose {
                viewModel.targetWeightKg = max(viewModel.currentWeightKg - 10, 40)
            } else if type == .gain {
                viewModel.targetWeightKg = viewModel.currentWeightKg + 5
            }
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(viewModel.selectedGoal == type ? .white : color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName + " Weight")
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .opacity(0.8)
                }

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

    // MARK: - Activity Page

    private var activityPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "figure.run")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple)
                    .padding(.top, 40)

                Text("Activity Level")
                    .font(.title)
                    .fontWeight(.bold)

                Text("How active are you on a typical week?")
                    .font(.body)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    activityButton(level: "sedentary", title: "Sedentary", description: "Little or no exercise, desk job")
                    activityButton(level: "light", title: "Lightly Active", description: "Light exercise 1-3 days/week")
                    activityButton(level: "moderate", title: "Moderately Active", description: "Moderate exercise 3-5 days/week")
                    activityButton(level: "active", title: "Very Active", description: "Hard exercise 6-7 days/week")
                    activityButton(level: "very_active", title: "Extra Active", description: "Very hard exercise, physical job")
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 100)
            }
        }
    }

    private func activityButton(level: String, title: String, description: String) -> some View {
        Button {
            viewModel.activityLevel = level
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(viewModel.activityLevel == level ? .white.opacity(0.8) : .secondary)
                }

                Spacer()

                if viewModel.activityLevel == level {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(viewModel.activityLevel == level ? Color.purple : Color.cardBackground)
            .foregroundStyle(viewModel.activityLevel == level ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Results Page

    private var resultsPage: some View {
        VStack(spacing: 24) {
            if viewModel.isCalculating {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Text("Calculating your personalized goals...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            } else if let calculations = viewModel.calculations {
                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                            .padding(.top, 40)

                        Text("Your Personalized Plan")
                            .font(.title)
                            .fontWeight(.bold)

                        // Daily Calorie Target
                        VStack(spacing: 8) {
                            Text("Daily Calorie Target")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("\(calculations.dailyCalories)")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(.green)

                            Text("calories per day")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)

                        // Macros breakdown
                        HStack(spacing: 16) {
                            macroCard(label: "Protein", value: "\(calculations.dailyProteinG)g", color: .blue)
                            macroCard(label: "Carbs", value: "\(calculations.dailyCarbsG)g", color: .orange)
                            macroCard(label: "Fat", value: "\(calculations.dailyFatG)g", color: .purple)
                        }
                        .padding(.horizontal, 24)

                        // Additional info
                        VStack(alignment: .leading, spacing: 12) {
                            infoRow(label: "Your BMR", value: "\(calculations.bmr) cal/day")
                            infoRow(label: "Your TDEE", value: "\(calculations.tdee) cal/day")
                            if calculations.weeklyGoalKg != 0 {
                                infoRow(
                                    label: "Expected Progress",
                                    value: calculations.weeklyGoalKg > 0 ? "+\(String(format: "%.1f", calculations.weeklyGoalKg)) kg/week" : "\(String(format: "%.1f", calculations.weeklyGoalKg)) kg/week"
                                )
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)

                        Spacer(minLength: 100)
                    }
                }
            } else {
                Spacer()
                Text("Ready to calculate your goals")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .onAppear {
            if viewModel.currentPage == 5 && viewModel.calculations == nil {
                Task {
                    await viewModel.calculateGoals()
                }
            }
        }
    }

    private func macroCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
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

            Button(viewModel.currentPage == 5 ? "Get Started" : "Continue") {
                if viewModel.currentPage == 5 {
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
            .tint(.green)
            .disabled(!viewModel.canContinue)
        }
        .padding(24)
    }
}

// MARK: - View Model

@MainActor
public final class OnboardingViewModel: ObservableObject {

    @Published public var currentPage = 0
    @Published public var gender: String = "male"
    @Published public var birthDate: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @Published public var heightCm: Double = 170
    @Published public var currentWeightKg: Double = 70
    @Published public var targetWeightKg: Double = 70
    @Published public var selectedGoal: GoalType = .maintain
    @Published public var activityLevel: String = "moderate"
    @Published public var enableNotifications = true

    @Published public var isCalculating = false
    @Published public var calculations: GoalCalculations?

    private let foodService: FoodService
    private let notificationService: NotificationService

    public var canContinue: Bool {
        switch currentPage {
        case 1: return !gender.isEmpty
        case 4: return !activityLevel.isEmpty
        case 5: return calculations != nil && !isCalculating
        default: return true
        }
    }

    public init(foodService: FoodService, notificationService: NotificationService) {
        self.foodService = foodService
        self.notificationService = notificationService
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    public func calculateGoals() async {
        isCalculating = true

        let request = CalculateGoalsRequest(
            heightCm: heightCm,
            currentWeightKg: currentWeightKg,
            targetWeightKg: selectedGoal == .maintain ? nil : targetWeightKg,
            birthDate: formatDate(birthDate),
            gender: gender,
            activityLevel: activityLevel,
            goalType: selectedGoal.rawValue
        )

        do {
            let response = try await foodService.calculateGoals(request)
            calculations = response.calculations
        } catch {
            print("Failed to calculate goals: \(error)")
            // Create default calculations as fallback
            calculations = GoalCalculations(
                age: 30,
                bmr: 1500,
                tdee: 2000,
                dailyCalories: selectedGoal == .lose ? 1500 : selectedGoal == .gain ? 2500 : 2000,
                dailyProteinG: 120,
                dailyCarbsG: 200,
                dailyFatG: 65,
                goalType: selectedGoal.rawValue,
                weeklyGoalKg: selectedGoal == .lose ? -0.5 : selectedGoal == .gain ? 0.35 : 0
            )
        }

        isCalculating = false
    }

    public func completeOnboarding() async {
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
