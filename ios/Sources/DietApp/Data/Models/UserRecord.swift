import Foundation
import GRDB

/// GRDB record representing a user in the local database
public struct UserRecord: Codable, FetchableRecord, PersistableRecord, Identifiable {

    // MARK: - Table Configuration

    public static let databaseTableName = "users"

    // MARK: - Properties

    public var id: String
    public var email: String
    public var displayName: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var trackingMode: TrackingMode
    public var recoveryModeEnabled: Bool
    public var synced: Bool

    // MARK: - Types

    public enum TrackingMode: String, Codable, CaseIterable {
        case full      // Full macro tracking
        case light     // Simplified tracking
        case mindful   // Recovery/wellness mode
    }

    // MARK: - Column Mapping

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case trackingMode = "tracking_mode"
        case recoveryModeEnabled = "recovery_mode_enabled"
        case synced
    }

    // MARK: - Initialization

    public init(
        id: String = UUID().uuidString,
        email: String,
        displayName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        trackingMode: TrackingMode = .full,
        recoveryModeEnabled: Bool = false,
        synced: Bool = false
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.trackingMode = trackingMode
        self.recoveryModeEnabled = recoveryModeEnabled
        self.synced = synced
    }
}

// MARK: - Associations

extension UserRecord {
    public static let foodLogs = hasMany(FoodLogRecord.self)

    public var foodLogs: QueryInterfaceRequest<FoodLogRecord> {
        request(for: UserRecord.foodLogs)
    }
}
