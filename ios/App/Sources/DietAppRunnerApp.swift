import SwiftUI
import DietApp
import Clerk

@main
struct DietAppRunnerApp: App {
    @StateObject private var appEnvironment = AppEnvironment.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appEnvironment)
                .task {
                    await initializeApp()
                }
        }
    }

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
