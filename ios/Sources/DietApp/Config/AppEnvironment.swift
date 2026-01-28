import Foundation
import SwiftUI

/// Dependency container for the app
/// Provides access to all core services and managers
@MainActor
public final class AppEnvironment: ObservableObject {

    // MARK: - Singleton

    public static let shared = AppEnvironment()

    // MARK: - Core Services

    /// Database manager for local SQLite/GRDB operations
    public let databaseManager: DatabaseManager

    /// HTTP client for API communication
    public let apiClient: APIClient

    /// Authentication manager (Clerk integration placeholder)
    public let authManager: AuthManager

    // MARK: - Repositories

    /// Food log repository for CRUD operations
    public lazy var foodLogRepository: FoodLogRepository = {
        FoodLogRepository(databaseManager: databaseManager)
    }()

    // MARK: - Services

    /// Food service for API operations
    public lazy var foodService: FoodService = {
        FoodService(apiClient: apiClient)
    }()

    // MARK: - Configuration

    /// Current environment (development, staging, production)
    public let environment: Environment

    /// API base URL based on environment
    public var apiBaseURL: URL {
        switch environment {
        case .development:
            return URL(string: "http://localhost:3000/api")!
        case .staging:
            return URL(string: "https://backend-xi-ivory-20.vercel.app/api")!
        case .production:
            return URL(string: "https://backend-xi-ivory-20.vercel.app/api")!
        }
    }

    // MARK: - Types

    public enum Environment: String {
        case development
        case staging
        case production
    }

    // MARK: - Initialization

    private init() {
        // Determine environment from build configuration
        #if DEBUG
        self.environment = .development
        #else
        self.environment = .production
        #endif

        // Initialize core services
        self.databaseManager = DatabaseManager()
        self.apiClient = APIClient(baseURL: URL(string: "http://localhost:3000/api")!)
        self.authManager = AuthManager()

        // Update API client base URL after initialization
        Task { @MainActor in
            self.apiClient.updateBaseURL(self.apiBaseURL)
        }
    }

    // MARK: - Factory Methods

    /// Creates a TodayViewModel with required dependencies
    public func makeTodayViewModel() -> TodayViewModel {
        TodayViewModel(
            foodLogRepository: foodLogRepository,
            authManager: authManager,
            foodService: foodService
        )
    }

    /// Creates an AddFoodViewModel with required dependencies
    public func makeAddFoodViewModel() -> AddFoodViewModel {
        AddFoodViewModel(foodService: foodService)
    }
}

// MARK: - Auth Manager

/// Authentication manager using Clerk iOS SDK (placeholder)
/// Replace with actual Clerk integration when ready
public final class AuthManager: ObservableObject {

    // MARK: - Published State

    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var currentUserId: String?
    @Published public private(set) var authToken: String?

    // MARK: - Initialization

    public init() {
        // TODO: Initialize Clerk SDK
        // Clerk.shared.configure(publishableKey: "your-publishable-key")
    }

    // MARK: - Auth Methods

    /// Sign in with email/password
    public func signIn(email: String, password: String) async throws {
        // TODO: Implement Clerk sign in
        // For now, simulate a successful sign in for development
        await MainActor.run {
            self.isAuthenticated = true
            self.currentUserId = "dev-user-id"
            self.authToken = "dev-token"
        }
    }

    /// Sign out the current user
    public func signOut() async throws {
        // TODO: Implement Clerk sign out
        await MainActor.run {
            self.isAuthenticated = false
            self.currentUserId = nil
            self.authToken = nil
        }
    }

    /// Get the current auth token for API requests
    public func getToken() async -> String? {
        // TODO: Get fresh token from Clerk
        return authToken
    }
}
