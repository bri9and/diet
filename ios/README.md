# Diet App - iOS

iOS client for the Diet App, built with SwiftUI targeting iOS 16+.

## Requirements

- Xcode 15.0+
- iOS 16.0+
- Swift 5.9+

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode and create a new project
2. Select "App" under iOS
3. Configure:
   - Product Name: `DietApp`
   - Team: Your development team
   - Organization Identifier: Your org identifier (e.g., `com.yourcompany`)
   - Interface: SwiftUI
   - Language: Swift
   - Storage: None (we use GRDB)
4. Save the project in this `ios/` directory
5. Copy the source files from `DietApp/` into the Xcode project

### 2. Add Swift Package Dependencies

In Xcode, go to File > Add Package Dependencies and add:

#### GRDB (SQLite database)
```
https://github.com/groue/GRDB.swift
```
- Version: 6.0.0 or later
- Select `GRDB` package product

#### Clerk iOS SDK (Authentication)
```
https://github.com/clerk/clerk-ios
```
- Version: Latest stable
- Select `ClerkSDK` package product

### 3. Configure Clerk

1. Create a Clerk account at https://clerk.com
2. Create a new application
3. Get your Publishable Key from the Clerk dashboard
4. Update `AppEnvironment.swift` to configure Clerk:

```swift
// In AuthManager.init()
Clerk.shared.configure(publishableKey: "pk_test_your-key")
```

### 4. Build and Run

1. Select your target device/simulator
2. Build and run (Cmd+R)

## Project Structure

```
DietApp/
├── DietAppApp.swift           # App entry point
├── Config/
│   └── AppEnvironment.swift   # Dependency container
├── Data/
│   ├── DatabaseManager.swift  # GRDB setup & migrations
│   ├── Models/
│   │   ├── UserRecord.swift
│   │   ├── FoodRecord.swift
│   │   └── FoodLogRecord.swift
│   └── Repositories/
│       └── FoodLogRepository.swift
├── Services/
│   └── APIClient.swift        # HTTP client
├── Views/
│   ├── ContentView.swift      # Tab container
│   ├── TodayView.swift        # Dashboard
│   └── SettingsView.swift     # Settings
└── ViewModels/
    └── TodayViewModel.swift   # Today view logic
```

## Architecture

### MVVM Pattern

- **Views**: SwiftUI views, observe ViewModels
- **ViewModels**: `ObservableObject` classes, manage UI state
- **Repositories**: Data access layer, abstract database operations
- **Models**: GRDB records, represent database tables

### Data Flow

```
View -> ViewModel -> Repository -> DatabaseManager (GRDB)
                               -> APIClient (Remote)
```

### Offline-First

- All data is stored locally using GRDB (SQLite)
- Sync operations are queued when offline
- PowerSync integration planned for real-time sync

## Key Dependencies

| Package | Purpose |
|---------|---------|
| [GRDB.swift](https://github.com/groue/GRDB.swift) | SQLite database with Swift |
| [Clerk iOS SDK](https://github.com/clerk/clerk-ios) | Authentication |

## Development Notes

### Database Migrations

Migrations are defined in `DatabaseManager.swift`. During development, `eraseDatabaseOnSchemaChange` is enabled to simplify iteration.

For production, proper incremental migrations should be added.

### Authentication

The `AuthManager` currently has placeholder implementations. Replace with actual Clerk SDK calls when integrating authentication.

### API Client

Configure the API base URL in `AppEnvironment.swift` based on your backend deployment:

```swift
case .development:
    return URL(string: "http://localhost:3000/api")!
case .production:
    return URL(string: "https://api.yourdomain.com")!
```

## Testing

(To be added)

- Unit tests for ViewModels and Repositories
- Integration tests for database operations
- UI tests for critical flows

## License

Proprietary - All rights reserved
