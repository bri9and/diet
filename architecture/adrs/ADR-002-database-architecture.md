# ADR-002: Database Architecture

**Status**: Accepted (Revised)
**Date**: 2026-01-27
**Decision Makers**: Sebastian (CEO/Product Owner), Backend Architecture Team

## Context

The diet tracking app requires a database that supports:
- User profiles with customizable nutrition goals
- Food logging with meals and individual items
- Family sharing with appropriate data isolation
- Offline-first synchronization via custom REST sync
- Efficient queries for daily/weekly/monthly aggregations
- Future AI-powered insights and recommendations
- **CRITICAL: Zero additional infrastructure cost** (self-hosted)

The previous PostgreSQL + Supabase approach was replaced due to cost constraints.

## Decision

We will use **MongoDB** (self-hosted on Sebastian's bare metal server) with:
- Document-oriented schema optimized for the app's access patterns
- Embedded documents where data is accessed together (meal items in food logs)
- References for shared data (foods, users in families)
- Timestamp-based versioning for offline sync
- Application-level authorization (replaces RLS)

## Database Schema Overview

### Entity Relationship Diagram

```
┌─────────────┐         ┌─────────────────┐         ┌─────────────┐
│   users     │◄────────│  familyMembers  │────────>│  families   │
│  (clerkId)  │         │                 │         │             │
└──────┬──────┘         └─────────────────┘         └──────┬──────┘
       │                                                    │
       │                                                    │
       ▼                                                    ▼
┌─────────────┐         ┌─────────────────┐         ┌─────────────┐
│ userGoals   │         │  familyInvites  │◄────────│             │
└─────────────┘         └─────────────────┘         └─────────────┘
       │
       │
       ▼
┌─────────────┐         ┌─────────────────┐         ┌─────────────┐
│  foodLogs   │────────>│ [items] (embed) │────────>│   foods     │
│             │         │                 │         │             │
└─────────────┘         └─────────────────┘         └─────────────┘
       │                                                   │
       ▼                                                   │
┌─────────────┐                                     ┌──────┴──────┐
│ weightLogs  │                                     │             │
└─────────────┘                                     ▼             ▼
                                             ┌──────────┐   ┌───────────┐
┌─────────────┐         ┌─────────────────┐  │  cache   │   │  custom   │
│dailySummary │         │  recentFoods    │  │ (source) │   │  (source) │
└─────────────┘         └─────────────────┘  └──────────┘   └───────────┘
```

## Collection Definitions

### 1. Users Collection

Users are linked to Clerk via `clerkId`. All profile and preference data.

```javascript
{
  _id: ObjectId,
  clerkId: String,           // Unique, indexed - from Clerk
  email: String,
  displayName: String,
  avatarUrl: String,
  timezone: String,
  unitSystem: "metric" | "imperial",
  language: String,
  subscriptionTier: "free" | "premium" | "family",
  subscriptionExpiresAt: Date,
  shareWithFamily: Boolean,
  aiProcessingConsent: Boolean,
  version: Number,           // For sync
  createdAt: Date,
  updatedAt: Date,
  deletedAt: Date            // Soft delete
}
```

### 2. Food Logs Collection (with embedded items)

**Key Design Decision**: Meal items are embedded within food logs because:
- They are always accessed together
- A food log typically has 1-10 items (small, bounded)
- Simplifies queries and sync

```javascript
{
  _id: ObjectId,
  userId: ObjectId,          // Reference to users
  loggedDate: String,        // "YYYY-MM-DD" for easy querying
  loggedAt: Date,
  mealType: "breakfast" | "lunch" | "dinner" | "snack",
  mealName: String,
  entryMethod: String,

  // EMBEDDED: Meal items
  items: [{
    _id: ObjectId,           // Unique ID per item
    foodId: ObjectId,        // Reference to foods (nullable for quick-add)
    quantity: Number,
    servingMultiplier: Number,
    nutrition: {             // Denormalized - preserves history
      calories: Number,
      proteinG: Number,
      carbsG: Number,
      fatG: Number,
      // ... other nutrients
    },
    foodSnapshot: {          // For offline display
      name: String,
      brand: String,
      servingDescription: String
    },
    quickAddName: String,    // For quick-add entries
    sortOrder: Number,
    createdAt: Date,
    updatedAt: Date,
    deletedAt: Date
  }],

  // COMPUTED: Meal totals
  totals: {
    calories: Number,
    proteinG: Number,
    carbsG: Number,
    fatG: Number,
    itemCount: Number
  },

  notes: String,
  version: Number,           // For sync
  createdAt: Date,
  updatedAt: Date,
  deletedAt: Date
}
```

### 3. Foods Collection

Shared food database combining cached API responses and custom user foods.

```javascript
{
  _id: ObjectId,
  source: "nutritionix" | "openfoodfacts" | "usda" | "custom",
  externalId: String,        // ID from external API
  barcode: String,           // UPC/EAN (sparse unique index)
  createdByUserId: ObjectId, // Only for custom foods
  isPublic: Boolean,
  name: String,
  brand: String,
  servingSize: Number,
  servingUnit: String,
  servingDescription: String,
  altServingSizes: [{
    size: Number,
    unit: String,
    description: String
  }],
  nutrition: {
    calories: Number,
    proteinG: Number,
    carbsG: Number,
    fatG: Number,
    fiberG: Number,
    sugarG: Number,
    sodiumMg: Number,
    // ... extended nutrients
  },
  extendedNutrition: Object, // Flexible for vitamins, minerals
  photoUrl: String,
  searchKeywords: [String],
  globalUseCount: Number,    // For search ranking
  cachedAt: Date,
  cacheExpiresAt: Date,      // TTL index for auto-cleanup
  createdAt: Date,
  updatedAt: Date,
  deletedAt: Date
}
```

### 4. Other Collections

- **userGoals**: Nutrition targets, body metrics, goal timeline
- **weightLogs**: Weight measurements with optional body composition
- **dailySummaries**: Pre-computed daily aggregates for charts
- **recentFoods**: User's frequently used foods with preferences
- **families**: Family group metadata
- **familyMembers**: Join table with sharing permissions
- **familyInvites**: Pending invitations with codes

See `/architecture/mongodb-schema.md` for complete collection definitions.

## Indexing Strategy

### Primary Indexes

```javascript
// Users - auth and lookup
db.users.createIndex({ clerkId: 1 }, { unique: true });
db.users.createIndex({ email: 1 });

// Food logs - primary access pattern
db.foodLogs.createIndex({ userId: 1, loggedDate: -1 });
db.foodLogs.createIndex({ userId: 1, updatedAt: -1 }); // Sync

// Foods - search and lookup
db.foods.createIndex({ source: 1, externalId: 1 }, { unique: true, sparse: true });
db.foods.createIndex({ barcode: 1 }, { unique: true, sparse: true });
db.foods.createIndex({ name: "text", brand: "text", searchKeywords: "text" });

// Weight logs
db.weightLogs.createIndex({ userId: 1, measuredDate: -1 });

// Daily summaries
db.dailySummaries.createIndex({ userId: 1, summaryDate: -1 }, { unique: true });

// Recent foods
db.recentFoods.createIndex({ userId: 1, lastUsedAt: -1 });

// Families
db.familyMembers.createIndex({ familyId: 1, userId: 1 }, { unique: true });
db.familyInvites.createIndex({ inviteCode: 1 }, { unique: true });
```

### TTL Indexes (Automatic Cleanup)

```javascript
// Expire cached foods after 90 days of no use
db.foods.createIndex(
  { cacheExpiresAt: 1 },
  { expireAfterSeconds: 0 }
);

// Expire old invites
db.familyInvites.createIndex(
  { expiresAt: 1 },
  { expireAfterSeconds: 0 }
);
```

## Data Access Patterns

### Pattern 1: Load Today's Dashboard

```javascript
// Get today's food logs with all items
const logs = await FoodLog.find({
  userId: userId,
  loggedDate: "2026-01-15",
  deletedAt: null
}).sort({ mealType: 1 });

// Totals are pre-computed in each log
const dayTotals = logs.reduce((acc, log) => ({
  calories: acc.calories + log.totals.calories,
  proteinG: acc.proteinG + log.totals.proteinG,
  // ...
}), { calories: 0, proteinG: 0 });
```

### Pattern 2: Search Foods

```javascript
// Text search with ranking
const results = await Food.find(
  { $text: { $search: query }, deletedAt: null },
  { score: { $meta: "textScore" } }
)
.sort({ score: { $meta: "textScore" }, globalUseCount: -1 })
.limit(20);

// Boost user's recent foods
const recentFoods = await RecentFood.find({ userId })
  .sort({ lastUsedAt: -1 })
  .limit(10)
  .populate('foodId');
```

### Pattern 3: Sync Changes

```javascript
// Pull changes since last sync
const changes = await Promise.all([
  FoodLog.find({ userId, updatedAt: { $gt: lastSync } }),
  WeightLog.find({ userId, updatedAt: { $gt: lastSync } }),
  UserGoal.find({ userId, updatedAt: { $gt: lastSync } }),
  DailySummary.find({ userId, updatedAt: { $gt: lastSync } })
]);
```

## Authorization (Application-Level)

Without PostgreSQL RLS, we implement authorization in the API middleware:

```typescript
// Middleware: Ensure user owns the resource
async function requireOwnership(Model: mongoose.Model) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const doc = await Model.findById(req.params.id);

    if (!doc) {
      return res.status(404).json({ error: 'Not found' });
    }

    if (doc.userId.toString() !== req.userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    req.resource = doc;
    next();
  };
}

// Usage
router.get('/food-logs/:id', requireOwnership(FoodLog), (req, res) => {
  res.json(req.resource);
});
```

### Family Data Access

```typescript
async function canViewFamilyData(viewerId: string, ownerId: string): Promise<boolean> {
  // Same user
  if (viewerId === ownerId) return true;

  // Check if they're in the same family with sharing enabled
  const viewerMemberships = await FamilyMember.find({
    userId: viewerId,
    status: 'active'
  });

  const ownerMemberships = await FamilyMember.find({
    userId: ownerId,
    status: 'active',
    shareFoodLogs: true
  });

  // Check for overlapping families
  const viewerFamilies = new Set(viewerMemberships.map(m => m.familyId.toString()));
  return ownerMemberships.some(m => viewerFamilies.has(m.familyId.toString()));
}
```

## Denormalization Strategy

### Why Denormalize Nutrition in Meal Items?

The `nutrition` object in meal items stores the **actual consumed values**, not a reference:

```javascript
// Good: Historical accuracy preserved
items: [{
  foodId: ObjectId("..."),
  nutrition: {
    calories: 350,  // Actual value when logged
    proteinG: 25
  }
}]

// Bad: Reference that could change
items: [{
  foodId: ObjectId("...")  // What if food data is updated?
}]
```

Benefits:
1. **Historical Accuracy**: If food data is corrected, old logs show what user actually believed they ate
2. **Offline Support**: No need to join with foods collection
3. **Audit Trail**: Clear record of nutrition at time of logging

### Pre-computed Totals

Each food log maintains `totals` that are updated when items change:

```javascript
// Update totals when items change
foodLog.totals = {
  calories: foodLog.items.reduce((sum, i) => sum + (i.nutrition?.calories || 0), 0),
  proteinG: foodLog.items.reduce((sum, i) => sum + (i.nutrition?.proteinG || 0), 0),
  // ...
  itemCount: foodLog.items.filter(i => !i.deletedAt).length
};
```

## Migration Notes

### From PostgreSQL to MongoDB

If migrating existing data:

1. **UUIDs to ObjectIds**: Generate new ObjectIds, maintain mapping
2. **Foreign Keys to References**: Store ObjectId references
3. **RLS to Application Logic**: Implement in API middleware
4. **Triggers to Application Logic**: Handle in save/update operations
5. **Joins to Lookups/Embeds**: Redesign based on access patterns

## Storage Estimates

At 10,000 MAU with average usage:

| Collection | Documents | Avg Size | Total |
|------------|-----------|----------|-------|
| users | 10,000 | 1 KB | 10 MB |
| foodLogs | 3,000,000 | 3 KB | 9 GB |
| foods | 100,000 | 2 KB | 200 MB |
| weightLogs | 100,000 | 0.3 KB | 30 MB |
| dailySummaries | 1,000,000 | 0.5 KB | 500 MB |
| recentFoods | 500,000 | 0.3 KB | 150 MB |
| families | 2,000 | 0.3 KB | 0.6 MB |
| familyMembers | 5,000 | 0.3 KB | 1.5 MB |
| **Total** | | | **~10 GB** |

This fits comfortably on self-hosted hardware.

## Consequences

### Positive

1. **Zero Cost**: Self-hosted on existing hardware
2. **Flexible Schema**: Easy to add fields, handle varying nutrition data
3. **Fast Queries**: Document model matches access patterns
4. **Offline-Friendly**: Embedded items simplify sync
5. **Scalable**: Horizontal scaling possible if needed

### Negative

1. **No RLS**: Security must be in application code
2. **Manual Backups**: Must configure backup scripts
3. **No Built-in Auth**: Using Clerk separately
4. **Ops Responsibility**: Sebastian maintains the database

### Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Data corruption | Daily backups to cloud storage |
| Authorization bugs | Comprehensive middleware tests |
| Performance issues | Proper indexing, monitoring |
| Disk failure | RAID or cloud backup |

## References

- [MongoDB Schema Design Best Practices](https://www.mongodb.com/docs/manual/core/data-model-design/)
- [MongoDB Indexes](https://www.mongodb.com/docs/manual/indexes/)
- [Full MongoDB Schema](/architecture/mongodb-schema.md)
- [Sync Protocol](/architecture/adrs/ADR-005-sync-protocol.md)
