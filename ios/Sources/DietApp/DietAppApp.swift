import SwiftUI

/// Main entry point for the Diet App
/// iOS 16+ with SwiftUI lifecycle
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
        // Initialize database
        do {
            try await appEnvironment.databaseManager.initialize()
        } catch {
            // In production, handle this error appropriately
            print("Database initialization failed: \(error)")
        }

        // Additional startup tasks can be added here:
        // - Check auth state
        // - Load cached user data
        // - Configure analytics
    }
}
