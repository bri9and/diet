import SwiftUI
import Clerk
#if canImport(UIKit)
import UIKit
#endif

/// Main content view with tab navigation
/// Serves as the root view after app initialization
public struct ContentView: View {

    // MARK: - Version

    public static let appVersion = "1.011"

    // MARK: - Environment

    @EnvironmentObject private var appEnvironment: AppEnvironment
    @Environment(\.clerk) private var clerk

    // MARK: - State

    @State private var selectedTab: Tab = .today
    @State private var showAuthView = false

    // MARK: - Types

    public enum Tab: Int, CaseIterable, Identifiable {
        case today
        case insights
        case me

        public var id: Int { rawValue }

        public var title: String {
            switch self {
            case .today: return "Today"
            case .insights: return "Insights"
            case .me: return "Me"
            }
        }

        public var icon: String {
            switch self {
            case .today: return "house.fill"
            case .insights: return "chart.line.uptrend.xyaxis"
            case .me: return "person.fill"
            }
        }
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Body

    public var body: some View {
        Group {
            if !clerk.isLoaded {
                loadingView
            } else if clerk.user != nil {
                mainTabView
            } else {
                signInPromptView
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showAuthView) {
            AuthView()
        }
        #endif
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sign In Prompt

    private var signInPromptView: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.green.opacity(0.1),
                    Color.green.opacity(0.05),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo and branding
                VStack(spacing: 20) {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: .green.opacity(0.3), radius: 20, y: 10)

                    VStack(spacing: 8) {
                        Text("Fuelvio")
                            .font(.system(size: 36, weight: .bold, design: .rounded))

                        Text("Your personal nutrition companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Features
                VStack(spacing: 16) {
                    FeatureRow(
                        icon: "camera.fill",
                        color: .blue,
                        title: "Photo Recognition",
                        subtitle: "Snap a photo, we'll identify the food"
                    )

                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        color: .orange,
                        title: "Track Progress",
                        subtitle: "See your nutrition trends over time"
                    )

                    FeatureRow(
                        icon: "target",
                        color: .green,
                        title: "Reach Your Goals",
                        subtitle: "Personalized targets for your journey"
                    )
                }
                .padding(.horizontal, 32)

                Spacer()

                // CTA Button
                VStack(spacing: 16) {
                    Button(action: { showAuthView = true }) {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .green.opacity(0.3), radius: 10, y: 5)
                    }

                    Text("Free to use. No credit card required.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Main Tab View

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            TodayView(viewModel: appEnvironment.makeTodayViewModel())
                .tabItem {
                    Label(Tab.today.title, systemImage: Tab.today.icon)
                }
                .tag(Tab.today)

            InsightsPlaceholderView()
                .tabItem {
                    Label(Tab.insights.title, systemImage: Tab.insights.icon)
                }
                .tag(Tab.insights)

            MeView(foodService: appEnvironment.foodService)
                .tabItem {
                    Label(Tab.me.title, systemImage: Tab.me.icon)
                }
                .tag(Tab.me)
        }
        .overlay(alignment: .bottomLeading) {
            Text("v\(Self.appVersion)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.leading, 8)
                .padding(.bottom, 52)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Insights Placeholder

/// Placeholder view for the Insights tab
/// Will be replaced with actual insights implementation
struct InsightsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)

                Text("Insights")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Track your progress and discover patterns in your nutrition journey.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.groupedBackground)
            .navigationTitle("Insights")
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppEnvironment.shared)
}
