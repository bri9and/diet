import SwiftUI
import Clerk

/// Main entry point for the Diet App
/// iOS 17+ with SwiftUI lifecycle
/// Note: When using in an Xcode project, add @main attribute
public struct DietAppApp: App {

    // MARK: - Environment

    @StateObject private var appEnvironment = AppEnvironment.shared

    // MARK: - Initialization

    public init() {}

    // MARK: - Body

    public var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appEnvironment)
                .task {
                    await initializeApp()
                }
        }
    }

    // MARK: - Initialization

    private func initializeApp() async {
        // Configure Clerk SDK
        Clerk.shared.configure(publishableKey: AppEnvironment.clerkPublishableKey)

        // Load Clerk session
        do {
            try await Clerk.shared.load()
        } catch {
            print("Clerk initialization failed: \(error)")
        }

        // Initialize database
        do {
            try await appEnvironment.databaseManager.initialize()
        } catch {
            print("Database initialization failed: \(error)")
        }
    }
}
