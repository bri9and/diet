# ADR-005: Sync Protocol

**Status**: Accepted (Revised)
**Date**: 2026-01-27
**Decision Makers**: Sebastian (CEO/Product Owner), Backend Architecture Team

## Context

The diet tracking app must work seamlessly offline because users log food in various situations:
- At a restaurant with poor signal
- In a gym basement
- While traveling internationally
- During temporary network outages

The previous PowerSync-based architecture was **rejected due to cost** (~$500/month at scale). We need a simpler, cost-effective approach.

**Requirements**:
- Offline-first: Users can log food without internet
- Eventual consistency: Data syncs when online
- Conflict resolution: Handle edits from multiple devices
- **Zero additional cost**: Use what we already have

## Decision

We will implement a **simple local-first sync strategy** using:

1. **Local SQLite database** (via GRDB on iOS) for offline storage
2. **REST API sync** with timestamp-based reconciliation
3. **Version vectors** for conflict detection
4. **Last-write-wins + merge** for conflict resolution

### Why Not MongoDB Realm Sync?

| Option | Cost at 10K MAU | Complexity |
|--------|-----------------|------------|
| MongoDB Realm Sync | ~$150-500/month | Medium (proprietary) |
| PowerSync | ~$500/month | Medium (proprietary) |
| Custom REST sync | $0 | Low-Medium |
| CRDTs | $0 | High |

**Decision**: Custom REST sync is the only option that meets our $0 infrastructure cost requirement.

### Sync Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              iOS Device                                  │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │                        Local Data Layer                              ││
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────┐ ││
│  │  │ GRDB/SQLite │  │ Pending     │  │ Conflict Resolution Engine  │ ││
│  │  │ (Local DB)  │  │ Changes     │  │ (Last-Write-Wins + Merge)   │ ││
│  │  │             │  │ Queue       │  │                             │ ││
│  │  └─────────────┘  └─────────────┘  └─────────────────────────────┘ ││
│  └─────────────────────────────────────────────────────────────────────┘│
│                                    │                                     │
│                                    │ Sync when online                    │
│                                    ▼                                     │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │                       SyncManager                                    ││
│  │  1. Push local changes to server                                    ││
│  │  2. Pull remote changes since lastSyncedAt                          ││
│  │  3. Resolve conflicts locally                                       ││
│  │  4. Apply changes to local DB                                       ││
│  └─────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ REST API (HTTPS)
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        Backend API (Node.js/Express)                    │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │                    Sync Endpoints                                    ││
│  │  POST /sync/push   - Receive client changes                         ││
│  │  GET  /sync/pull   - Send server changes since timestamp            ││
│  │  POST /sync/full   - Full sync (initial or recovery)                ││
│  └─────────────────────────────────────────────────────────────────────┘│
│                              │                                           │
│                              ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │                       MongoDB                                        ││
│  │  - All collections have updatedAt index                             ││
│  │  - Version field for optimistic locking                             ││
│  │  - Soft deletes (deletedAt timestamp)                               ││
│  └─────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────┘
```

## What Syncs vs. What Stays Local

### Synced Data

| Collection | Sync Direction | Notes |
|------------|----------------|-------|
| foodLogs | Bidirectional | Core user data |
| userGoals | Bidirectional | Goal settings |
| weightLogs | Bidirectional | Weight tracking |
| dailySummaries | Server to Client | Computed on server |
| recentFoods | Bidirectional | Usage history |
| families | Bidirectional | Family metadata |
| familyMembers | Bidirectional | Membership |

### Local-Only Data

| Data | Storage | Reason |
|------|---------|--------|
| Cached API foods | SQLite | Large, external source |
| Search cache | SQLite | Performance |
| UI state | UserDefaults | Device-specific |
| Pending sync queue | SQLite | Temporary |

## Sync Protocol

### Document Versioning

Every synced document includes:

```typescript
interface SyncMetadata {
  _id: string;              // MongoDB ObjectId
  version: number;          // Incremented on each update
  updatedAt: Date;          // Last modification time
  deletedAt: Date | null;   // Soft delete timestamp
  lastSyncedAt: Date;       // Last successful sync time
  deviceId: string;         // Device that made last change
}
```

### Sync Flow

```
┌─────────┐                              ┌──────────┐
│ Client  │                              │  Server  │
└────┬────┘                              └────┬─────┘
     │                                        │
     │ 1. Push: POST /sync/push               │
     │    { changes: [...], deviceId, lastPulledAt }
     │───────────────────────────────────────>│
     │                                        │
     │                  2. Server processes:  │
     │                     - Validate changes │
     │                     - Check versions   │
     │                     - Apply or reject  │
     │                                        │
     │ 3. Response: { applied, conflicts }    │
     │<───────────────────────────────────────│
     │                                        │
     │ 4. Pull: GET /sync/pull?since={ts}     │
     │───────────────────────────────────────>│
     │                                        │
     │                  5. Server returns all │
     │                     changes since ts   │
     │                                        │
     │ 6. Response: { changes, serverTime }   │
     │<───────────────────────────────────────│
     │                                        │
     │ 7. Client applies changes locally      │
     │    (with conflict resolution)          │
     │                                        │
```

### Push Request

```typescript
// POST /sync/push
interface PushRequest {
  deviceId: string;
  lastPulledAt: string;  // ISO timestamp
  changes: SyncChange[];
}

interface SyncChange {
  collection: string;    // "foodLogs", "weightLogs", etc.
  operation: "create" | "update" | "delete";
  documentId: string;
  version: number;       // Expected version (for optimistic locking)
  data: object;          // Full document for create/update
  timestamp: string;     // When change was made locally
}
```

### Push Response

```typescript
interface PushResponse {
  success: boolean;
  applied: string[];     // IDs of successfully applied changes
  conflicts: Conflict[]; // Changes that conflicted
  serverTime: string;    // Current server time
}

interface Conflict {
  documentId: string;
  clientVersion: number;
  serverVersion: number;
  serverData: object;    // Current server state
  resolution: "server_wins" | "client_wins" | "merge";
}
```

### Pull Request

```typescript
// GET /sync/pull?since=2026-01-15T10:00:00Z&collections=foodLogs,weightLogs
interface PullParams {
  since: string;         // ISO timestamp
  collections?: string;  // Comma-separated, or all if omitted
}
```

### Pull Response

```typescript
interface PullResponse {
  changes: ServerChange[];
  serverTime: string;
  hasMore: boolean;      // For pagination
  cursor?: string;       // For pagination
}

interface ServerChange {
  collection: string;
  documentId: string;
  operation: "upsert" | "delete";
  data: object;
  version: number;
  updatedAt: string;
}
```

## Conflict Resolution Strategy

### Default: Last-Write-Wins (LWW)

For most data, the most recent change wins:

```typescript
function resolveConflict(local: Document, remote: Document): Document {
  // Compare timestamps
  const localTime = new Date(local.updatedAt).getTime();
  const remoteTime = new Date(remote.updatedAt).getTime();

  if (localTime > remoteTime) {
    return local;  // Local wins
  } else if (remoteTime > localTime) {
    return remote; // Remote wins
  } else {
    // Same timestamp - use version number
    return local.version > remote.version ? local : remote;
  }
}
```

### Merge Strategy for Food Logs

For food logs, we can merge items instead of replacing:

```typescript
function mergeFoodLog(local: FoodLog, remote: FoodLog): FoodLog {
  // Start with the newer log metadata
  const base = local.updatedAt > remote.updatedAt ? local : remote;

  // Merge items by ID
  const itemMap = new Map<string, MealItem>();

  // Add all remote items
  for (const item of remote.items) {
    itemMap.set(item._id, item);
  }

  // Merge/override with local items (LWW per item)
  for (const item of local.items) {
    const existing = itemMap.get(item._id);
    if (!existing || item.updatedAt > existing.updatedAt) {
      itemMap.set(item._id, item);
    }
  }

  return {
    ...base,
    items: Array.from(itemMap.values()).filter(i => !i.deletedAt),
    totals: recalculateTotals(itemMap.values()),
  };
}
```

## Swift Implementation

### Local Database Schema (GRDB)

```swift
// Database/LocalModels.swift

import GRDB

struct LocalFoodLog: Codable, FetchableRecord, PersistableRecord {
    var id: String              // MongoDB ObjectId as string
    var userId: String
    var loggedDate: String      // YYYY-MM-DD
    var loggedAt: Date
    var mealType: String
    var mealName: String?
    var entryMethod: String
    var notes: String?

    // Sync metadata
    var version: Int
    var updatedAt: Date
    var deletedAt: Date?
    var lastSyncedAt: Date?
    var pendingSync: Bool       // True if has unsynced changes
    var deviceId: String

    // Embedded items stored as JSON
    var itemsJson: Data

    static let databaseTableName = "food_logs"
}

extension LocalFoodLog {
    var items: [LocalMealItem] {
        get { try! JSONDecoder().decode([LocalMealItem].self, from: itemsJson) }
        set { itemsJson = try! JSONEncoder().encode(newValue) }
    }
}

// Database setup
class LocalDatabase {
    static let shared = LocalDatabase()
    let dbQueue: DatabaseQueue

    init() {
        let path = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("dietapp.sqlite")
            .path

        dbQueue = try! DatabaseQueue(path: path)

        try! migrator.migrate(dbQueue)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "food_logs") { t in
                t.column("id", .text).primaryKey()
                t.column("userId", .text).notNull().indexed()
                t.column("loggedDate", .text).notNull().indexed()
                t.column("loggedAt", .datetime).notNull()
                t.column("mealType", .text).notNull()
                t.column("mealName", .text)
                t.column("entryMethod", .text).notNull()
                t.column("notes", .text)
                t.column("itemsJson", .blob).notNull()
                t.column("version", .integer).notNull().defaults(to: 1)
                t.column("updatedAt", .datetime).notNull()
                t.column("deletedAt", .datetime)
                t.column("lastSyncedAt", .datetime)
                t.column("pendingSync", .boolean).notNull().defaults(to: false)
                t.column("deviceId", .text).notNull()
            }

            // Index for sync queries
            try db.create(index: "idx_food_logs_sync",
                          on: "food_logs",
                          columns: ["userId", "pendingSync"])

            try db.create(index: "idx_food_logs_updated",
                          on: "food_logs",
                          columns: ["userId", "updatedAt"])
        }

        return migrator
    }
}
```

### Sync Manager

```swift
// Sync/SyncManager.swift

import Foundation
import GRDB

@MainActor
class SyncManager: ObservableObject {
    static let shared = SyncManager()

    @Published var isSyncing = false
    @Published var pendingChangesCount = 0
    @Published var lastSyncTime: Date?
    @Published var syncError: SyncError?

    private let db = LocalDatabase.shared.dbQueue
    private let api = APIClient.shared
    private let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

    // MARK: - Sync Lifecycle

    func performSync() async {
        guard !isSyncing else { return }

        isSyncing = true
        syncError = nil

        do {
            // 1. Push local changes
            let pushResult = try await pushLocalChanges()

            // 2. Handle conflicts from push
            if !pushResult.conflicts.isEmpty {
                try await resolveConflicts(pushResult.conflicts)
            }

            // 3. Pull remote changes
            let lastPulled = UserDefaults.standard.object(forKey: "lastSyncedAt") as? Date ?? .distantPast
            let pullResult = try await pullRemoteChanges(since: lastPulled)

            // 4. Apply pulled changes
            try await applyRemoteChanges(pullResult.changes)

            // 5. Update sync time
            UserDefaults.standard.set(Date(), forKey: "lastSyncedAt")
            lastSyncTime = Date()

            // 6. Update pending count
            await updatePendingCount()

        } catch {
            syncError = SyncError.syncFailed(error.localizedDescription)
        }

        isSyncing = false
    }

    // MARK: - Push

    private func pushLocalChanges() async throws -> PushResponse {
        // Get all pending changes
        let pendingLogs = try await db.read { db in
            try LocalFoodLog
                .filter(Column("pendingSync") == true)
                .fetchAll(db)
        }

        guard !pendingLogs.isEmpty else {
            return PushResponse(success: true, applied: [], conflicts: [], serverTime: ISO8601DateFormatter().string(from: Date()))
        }

        // Convert to sync changes
        let changes: [SyncChange] = pendingLogs.map { log in
            SyncChange(
                collection: "foodLogs",
                operation: log.deletedAt != nil ? .delete : (log.lastSyncedAt == nil ? .create : .update),
                documentId: log.id,
                version: log.version,
                data: log.toServerDocument(),
                timestamp: ISO8601DateFormatter().string(from: log.updatedAt)
            )
        }

        // Push to server
        let response: PushResponse = try await api.post("/sync/push", body: PushRequest(
            deviceId: deviceId,
            lastPulledAt: ISO8601DateFormatter().string(from: UserDefaults.standard.object(forKey: "lastSyncedAt") as? Date ?? .distantPast),
            changes: changes
        ))

        // Mark applied changes as synced
        try await db.write { db in
            for id in response.applied {
                try db.execute(sql: """
                    UPDATE food_logs
                    SET pendingSync = 0, lastSyncedAt = ?
                    WHERE id = ?
                """, arguments: [Date(), id])
            }
        }

        return response
    }

    // MARK: - Pull

    private func pullRemoteChanges(since: Date) async throws -> PullResponse {
        let sinceString = ISO8601DateFormatter().string(from: since)
        return try await api.get("/sync/pull?since=\(sinceString)")
    }

    // MARK: - Apply Changes

    private func applyRemoteChanges(_ changes: [ServerChange]) async throws {
        try await db.write { db in
            for change in changes {
                switch change.collection {
                case "foodLogs":
                    try applyFoodLogChange(change, in: db)
                case "weightLogs":
                    try applyWeightLogChange(change, in: db)
                // Add other collections...
                default:
                    break
                }
            }
        }
    }

    private func applyFoodLogChange(_ change: ServerChange, in db: Database) throws {
        if change.operation == "delete" {
            try db.execute(sql: "DELETE FROM food_logs WHERE id = ?", arguments: [change.documentId])
            return
        }

        // Check if we have a local version
        if let local = try LocalFoodLog.fetchOne(db, key: change.documentId) {
            // Conflict: we have local changes
            if local.pendingSync && local.updatedAt > Date(iso8601: change.updatedAt) {
                // Local is newer - keep local
                return
            }
        }

        // Apply remote change (upsert)
        let remote = LocalFoodLog.fromServerDocument(change.data, deviceId: deviceId)
        try remote.save(db)
    }

    // MARK: - Conflict Resolution

    private func resolveConflicts(_ conflicts: [Conflict]) async throws {
        try await db.write { db in
            for conflict in conflicts {
                switch conflict.resolution {
                case "server_wins":
                    // Replace local with server version
                    let remote = LocalFoodLog.fromServerDocument(conflict.serverData, deviceId: deviceId)
                    try remote.save(db)

                case "client_wins":
                    // Keep local, increment version and re-queue for sync
                    try db.execute(sql: """
                        UPDATE food_logs
                        SET version = version + 1, pendingSync = 1
                        WHERE id = ?
                    """, arguments: [conflict.documentId])

                case "merge":
                    // Merge logic for food logs
                    if let local = try LocalFoodLog.fetchOne(db, key: conflict.documentId) {
                        let remote = LocalFoodLog.fromServerDocument(conflict.serverData, deviceId: deviceId)
                        let merged = mergeFoodLogs(local: local, remote: remote)
                        try merged.save(db)
                    }
                }
            }
        }
    }

    private func mergeFoodLogs(local: LocalFoodLog, remote: LocalFoodLog) -> LocalFoodLog {
        var merged = local.updatedAt > remote.updatedAt ? local : remote

        // Merge items by ID, keeping newer versions
        var itemMap: [String: LocalMealItem] = [:]
        for item in remote.items { itemMap[item.id] = item }
        for item in local.items {
            if let existing = itemMap[item.id] {
                if item.updatedAt > existing.updatedAt {
                    itemMap[item.id] = item
                }
            } else {
                itemMap[item.id] = item
            }
        }

        merged.items = Array(itemMap.values).filter { $0.deletedAt == nil }
        merged.version = max(local.version, remote.version) + 1
        merged.pendingSync = true

        return merged
    }

    // MARK: - Helpers

    private func updatePendingCount() async {
        pendingChangesCount = try! await db.read { db in
            try LocalFoodLog.filter(Column("pendingSync") == true).fetchCount(db)
        }
    }
}
```

### Automatic Sync Triggers

```swift
// Sync/SyncCoordinator.swift

import Combine
import Network

class SyncCoordinator {
    static let shared = SyncCoordinator()

    private let networkMonitor = NWPathMonitor()
    private let syncDebouncer = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupNetworkMonitor()
        setupSyncDebouncer()
        setupAppLifecycleObservers()
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitor() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                // Network restored - trigger sync
                Task {
                    await SyncManager.shared.performSync()
                }
            }
        }
        networkMonitor.start(queue: .global(qos: .utility))
    }

    // MARK: - Debounced Sync

    private func setupSyncDebouncer() {
        // Debounce rapid changes - sync at most every 5 seconds
        syncDebouncer
            .debounce(for: .seconds(5), scheduler: RunLoop.main)
            .sink { [weak self] in
                Task {
                    await SyncManager.shared.performSync()
                }
            }
            .store(in: &cancellables)
    }

    func requestSync() {
        syncDebouncer.send()
    }

    // MARK: - App Lifecycle

    private func setupAppLifecycleObservers() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task {
                    await SyncManager.shared.performSync()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                // Quick sync before backgrounding
                Task {
                    await SyncManager.shared.performSync()
                }
            }
            .store(in: &cancellables)
    }
}
```

## Backend Implementation

### Sync Routes

```typescript
// routes/sync.ts

import { Router } from 'express';
import { requireAuth } from '../middleware/auth';
import { FoodLog, WeightLog, UserGoal } from '../models';

const router = Router();

// Push changes from client
router.post('/sync/push', requireAuth, async (req, res) => {
  const { deviceId, lastPulledAt, changes } = req.body;
  const userId = req.auth!.userId;

  const applied: string[] = [];
  const conflicts: Conflict[] = [];

  for (const change of changes) {
    try {
      const result = await processChange(change, userId, deviceId);

      if (result.success) {
        applied.push(change.documentId);
      } else if (result.conflict) {
        conflicts.push(result.conflict);
      }
    } catch (error) {
      console.error(`Error processing change ${change.documentId}:`, error);
    }
  }

  res.json({
    success: true,
    applied,
    conflicts,
    serverTime: new Date().toISOString(),
  });
});

async function processChange(
  change: SyncChange,
  userId: string,
  deviceId: string
): Promise<{ success: boolean; conflict?: Conflict }> {
  const Model = getModelForCollection(change.collection);

  // Get current server document
  const current = await Model.findById(change.documentId);

  // CREATE: Document shouldn't exist
  if (change.operation === 'create') {
    if (current) {
      // Already exists - conflict
      return {
        success: false,
        conflict: {
          documentId: change.documentId,
          clientVersion: change.version,
          serverVersion: current.version,
          serverData: current.toObject(),
          resolution: 'server_wins', // Existing document wins
        },
      };
    }

    // Create new document
    await Model.create({
      _id: change.documentId,
      userId,
      ...change.data,
      version: 1,
      updatedAt: new Date(),
      deviceId,
    });

    return { success: true };
  }

  // UPDATE/DELETE: Document must exist
  if (!current) {
    // Deleted on server - inform client
    return {
      success: false,
      conflict: {
        documentId: change.documentId,
        clientVersion: change.version,
        serverVersion: 0,
        serverData: null,
        resolution: 'server_wins',
      },
    };
  }

  // Version check (optimistic locking)
  if (current.version !== change.version) {
    // Conflict! Determine resolution
    const clientTime = new Date(change.timestamp).getTime();
    const serverTime = current.updatedAt.getTime();

    // Last-write-wins
    if (clientTime > serverTime) {
      // Client wins - apply change
      await Model.findByIdAndUpdate(change.documentId, {
        ...change.data,
        version: current.version + 1,
        updatedAt: new Date(),
        deviceId,
        deletedAt: change.operation === 'delete' ? new Date() : null,
      });

      return { success: true };
    } else {
      // Server wins
      return {
        success: false,
        conflict: {
          documentId: change.documentId,
          clientVersion: change.version,
          serverVersion: current.version,
          serverData: current.toObject(),
          resolution: 'server_wins',
        },
      };
    }
  }

  // Version matches - apply change
  if (change.operation === 'delete') {
    await Model.findByIdAndUpdate(change.documentId, {
      deletedAt: new Date(),
      version: current.version + 1,
      updatedAt: new Date(),
      deviceId,
    });
  } else {
    await Model.findByIdAndUpdate(change.documentId, {
      ...change.data,
      version: current.version + 1,
      updatedAt: new Date(),
      deviceId,
    });
  }

  return { success: true };
}

// Pull changes from server
router.get('/sync/pull', requireAuth, async (req, res) => {
  const userId = req.auth!.userId;
  const since = new Date(req.query.since as string || '1970-01-01');
  const collections = (req.query.collections as string)?.split(',') || [
    'foodLogs', 'weightLogs', 'userGoals', 'dailySummaries', 'recentFoods'
  ];

  const changes: ServerChange[] = [];

  for (const collection of collections) {
    const Model = getModelForCollection(collection);
    if (!Model) continue;

    const docs = await Model.find({
      userId,
      updatedAt: { $gt: since },
    }).sort({ updatedAt: 1 }).limit(1000);

    for (const doc of docs) {
      changes.push({
        collection,
        documentId: doc._id.toString(),
        operation: doc.deletedAt ? 'delete' : 'upsert',
        data: doc.toObject(),
        version: doc.version,
        updatedAt: doc.updatedAt.toISOString(),
      });
    }
  }

  res.json({
    changes,
    serverTime: new Date().toISOString(),
    hasMore: changes.length >= 1000,
  });
});

// Full sync (initial or recovery)
router.post('/sync/full', requireAuth, async (req, res) => {
  const userId = req.auth!.userId;

  const data: Record<string, any[]> = {};

  // Fetch all user data
  data.foodLogs = await FoodLog.find({ userId, deletedAt: null });
  data.weightLogs = await WeightLog.find({ userId, deletedAt: null });
  data.userGoals = await UserGoal.find({ userId, deletedAt: null });
  // ... other collections

  res.json({
    data,
    serverTime: new Date().toISOString(),
  });
});

export default router;
```

## Sync Status UI

```swift
// Views/SyncStatusView.swift

struct SyncStatusView: View {
    @ObservedObject var syncManager = SyncManager.shared

    var body: some View {
        HStack(spacing: 8) {
            statusIcon
            statusText
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }

    @ViewBuilder
    private var statusIcon: some View {
        if syncManager.isSyncing {
            ProgressView()
                .scaleEffect(0.7)
        } else if syncManager.pendingChangesCount > 0 {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.orange)
        } else if syncManager.syncError != nil {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
        } else {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.green)
        }
    }

    private var statusText: Text {
        if syncManager.isSyncing {
            return Text("Syncing...")
        } else if syncManager.pendingChangesCount > 0 {
            return Text("\(syncManager.pendingChangesCount) pending")
        } else if let error = syncManager.syncError {
            return Text("Sync error")
        } else if let lastSync = syncManager.lastSyncTime {
            return Text("Synced \(lastSync, style: .relative) ago")
        } else {
            return Text("Not synced")
        }
    }
}
```

## Consequences

### Positive

1. **Zero Cost**: No additional services needed
2. **Simple**: Straightforward REST-based sync
3. **Offline-First**: Full functionality without internet
4. **Debuggable**: Easy to trace sync issues
5. **Portable**: Works with any REST backend

### Negative

1. **Manual Implementation**: More code than PowerSync/Realm
2. **Eventually Consistent**: Brief windows where devices differ
3. **No Real-time**: Polling-based, not instant push
4. **Conflict Complexity**: Must handle edge cases manually

### Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Data loss from sync bugs | Soft deletes; version history; local backup |
| Sync storms (too many requests) | Debouncing; exponential backoff |
| Large initial sync | Pagination; progressive loading |
| Clock skew issues | Server timestamps are authoritative |

## Future Enhancements

1. **WebSocket Push**: Real-time notifications for remote changes
2. **Delta Sync**: Send only changed fields, not full documents
3. **Background Sync**: Use iOS Background Tasks API
4. **Selective Sync**: User chooses what to sync

## References

- [GRDB.swift Documentation](https://github.com/groue/GRDB.swift)
- [Offline-First Web Apps](https://offlinefirst.org/)
- [Designing Data-Intensive Applications (Kleppmann)](https://dataintensive.net/) - Chapter on replication
- [Local-First Software](https://www.inkandswitch.com/local-first/)
