import Foundation
import SwiftUI
import Clerk

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

    // MARK: - Clerk Configuration

    /// Clerk publishable key
    public static let clerkPublishableKey = "pk_test_d2FudGVkLWJ1ZmZhbG8tMzIuY2xlcmsuYWNjb3VudHMuZGV2JA"

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

    /// Notification service for push notifications
    public lazy var notificationService: NotificationService = {
        NotificationService(apiClient: apiClient)
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

        // Initialize API client - always use production backend
        // Set USE_LOCAL_BACKEND=1 in scheme environment variables to use localhost
        let useLocal = ProcessInfo.processInfo.environment["USE_LOCAL_BACKEND"] == "1"
        let baseURL = useLocal
            ? URL(string: "http://localhost:3000/api")!
            : URL(string: "https://backend-xi-ivory-20.vercel.app/api")!
        self.apiClient = APIClient(baseURL: baseURL)

        // Connect auth token provider to API client
        self.apiClient.tokenProvider = {
            await Self.getClerkToken()
        }
    }

    // MARK: - Auth Helper

    /// Get JWT token from Clerk session
    @MainActor
    public static func getClerkToken() async -> String? {
        guard let session = Clerk.shared.session else { return nil }
        do {
            let token = try await session.getToken()
            return token?.jwt
        } catch {
            print("Failed to get Clerk token: \(error)")
            return nil
        }
    }

    // MARK: - Factory Methods

    /// Creates a TodayViewModel with required dependencies
    public func makeTodayViewModel() -> TodayViewModel {
        TodayViewModel(
            foodLogRepository: foodLogRepository,
            foodService: foodService
        )
    }

    /// Creates an AddFoodViewModel with required dependencies
    public func makeAddFoodViewModel() -> AddFoodViewModel {
        AddFoodViewModel(foodService: foodService)
    }
}
