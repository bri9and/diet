import SwiftUI
import Clerk
#if canImport(UIKit)
import UIKit
#endif

/// Main content view with tab navigation
/// Serves as the root view after app initialization
public struct ContentView: View {

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
        case settings

        public var id: Int { rawValue }

        public var title: String {
            switch self {
            case .today: return "Today"
            case .insights: return "Insights"
            case .settings: return "Settings"
            }
        }

        public var icon: String {
            switch self {
            case .today: return "house.fill"
            case .insights: return "chart.line.uptrend.xyaxis"
            case .settings: return "gearshape.fill"
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
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            VStack(spacing: 12) {
                Text("Diet App")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Track your nutrition, reach your goals")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Button(action: { showAuthView = true }) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            Spacer()
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

            SettingsView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
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
