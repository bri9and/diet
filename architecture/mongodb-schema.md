# Diet Tracking App - MongoDB Schema Design

**Version**: 2.0.0
**Date**: 2026-01-27
**Database**: MongoDB 7.0+

## Overview

This document defines the MongoDB collections, document structures, and indexes for the diet tracking app. The schema is designed for:

- **Document embedding** where appropriate (meal items within food logs)
- **References** for shared data (foods, families)
- **Efficient queries** for common access patterns
- **Offline-first sync** compatibility with simple timestamp-based reconciliation

## Design Principles

1. **Embed when possible**: Meal items are embedded in food logs (1:few relationship, always accessed together)
2. **Reference when shared**: Foods are referenced, not embedded (shared across users, updated independently)
3. **Denormalize for performance**: Store computed nutrition totals for quick dashboard loads
4. **Version documents**: Include `version` field for optimistic locking during sync
5. **Soft deletes**: Use `deletedAt` timestamp instead of hard deletes

---

## Collections

### 1. Users Collection

```javascript
// Collection: users
{
  _id: ObjectId("..."),

  // Clerk Integration
  clerkId: "user_2abc123...",      // Clerk user ID (unique, indexed)

  // Profile
  email: "user@example.com",
  displayName: "John Doe",
  avatarUrl: "https://...",

  // Preferences
  timezone: "America/Los_Angeles",
  unitSystem: "metric",            // "metric" | "imperial"
  language: "en",
  dateFormat: "yyyy-MM-dd",
  startOfWeek: 1,                  // 0=Sunday, 1=Monday

  // Privacy Settings
  shareWithFamily: false,
  aiProcessingConsent: true,
  analyticsConsent: true,

  // Subscription (manual tracking - no payment integration yet)
  subscriptionTier: "free",        // "free" | "premium" | "family"
  subscriptionExpiresAt: ISODate("2027-01-01"),

  // Feature Flags
  betaFeaturesEnabled: false,

  // Sync Metadata
  version: 1,                      // Incremented on each update
  lastSyncedAt: ISODate("..."),

  // Timestamps
  createdAt: ISODate("..."),
  updatedAt: ISODate("..."),
  deletedAt: null                  // Soft delete
}

// Indexes
db.users.createIndex({ clerkId: 1 }, { unique: true })
db.users.createIndex({ email: 1 })
db.users.createIndex({ deletedAt: 1 }, { partialFilterExpression: { deletedAt: null } })
```

### 2. User Goals Collection

```javascript
// Collection: userGoals
{
  _id: ObjectId("..."),
  userId: ObjectId("..."),         // Reference to users._id

  // Goal Classification
  goalType: "weight_loss",         // "weight_loss" | "weight_gain" | "maintenance" | "muscle_gain" | "custom"
  goalName: "Summer shred",        // Optional custom name

  // Daily Nutrition Targets
  caloriesTarget: 1800,
  proteinTargetG: 120,
  carbsTargetG: 180,
  fatTargetG: 60,
  fiberTargetG: 30,
  sugarLimitG: 50,
  sodiumLimitMg: 2300,
  waterTargetMl: 2500,

  // Body Metrics (for TDEE calculation)
  currentWeightKg: 85.0,
  targetWeightKg: 75.0,
  heightCm: 178,
  birthDate: ISODate("1990-05-15"),
  sex: "male",                     // "male" | "female" | "other"
  activityLevel: "moderate",       // "sedentary" | "light" | "moderate" | "active" | "very_active"
  bodyFatPercentage: 22.5,

  // Goal Timeline
  targetDate: ISODate("2026-06-01"),
  weeklyChangeKg: -0.5,            // Positive = gain, negative = loss

  // Macro Ratios (percentages, should sum to 100)
  macroRatios: {
    protein: 30,
    carbs: 40,
    fat: 30
  },

  // Status
  isActive: true,
  startedAt: ISODate("2026-01-01"),
  endedAt: null,

  // Sync Metadata
  version: 1,
  lastSyncedAt: ISODate("..."),

  // Timestamps
  createdAt: ISODate("..."),
  updatedAt: ISODate("..."),
  deletedAt: null
}

// Indexes
db.userGoals.createIndex({ userId: 1, isActive: 1 })
db.userGoals.createIndex({ userId: 1, deletedAt: 1 })
```

### 3. Foods Collection

```javascript
// Collection: foods
{
  _id: ObjectId("..."),

  // Source Identification
  source: "nutritionix",           // "nutritionix" | "openfoodfacts" | "usda" | "custom"
  externalId: "nix_abc123",        // ID from external API (indexed with source)
  barcode: "0123456789012",        // UPC/EAN barcode (unique sparse index)

  // For Custom Foods
  createdByUserId: ObjectId("..."), // Only for source="custom"
  isPublic: false,                  // Share with other users
  isVerified: false,                // Admin verified

  // Basic Information
  name: "Grilled Chicken Breast",
  brand: null,
  description: "Skinless, boneless chicken breast, grilled",
  category: "Protein",
  subcategory: "Poultry",

  // Serving Information
  servingSize: 100,
  servingUnit: "g",
  servingDescription: "1 breast (100g)",
  servingsPerContainer: null,

  // Alternative Servings
  altServingSizes: [
    { size: 28, unit: "g", description: "1 oz" },
    { size: 85, unit: "g", description: "3 oz" },
    { size: 170, unit: "g", description: "6 oz (large breast)" }
  ],

  // Primary Nutrition (per serving)
  nutrition: {
    calories: 165,
    proteinG: 31,
    carbsG: 0,
    fatG: 3.6,
    fiberG: 0,
    sugarG: 0,
    sodiumMg: 74,
    saturatedFatG: 1,
    transFatG: 0,
    cholesterolMg: 85,
    potassiumMg: 256
  },

  // Extended Nutrition (vitamins, minerals, etc.)
  extendedNutrition: {
    vitaminAIu: 21,
    vitaminCMg: 0,
    calciumMg: 11,
    ironMg: 1,
    vitaminDIu: 5,
    vitaminB12Mcg: 0.3,
    omega3G: 0.05,
    caffeineMg: 0
  },

  // Media
  photoUrl: "https://...",
  thumbnailUrl: "https://...",

  // Search Optimization
  searchKeywords: ["chicken", "breast", "grilled", "protein", "lean"],

  // Usage Statistics (for ranking in search)
  globalUseCount: 15420,

  // Cache Management (for API-sourced foods)
  cachedAt: ISODate("..."),
  cacheExpiresAt: ISODate("..."),

  // Timestamps
  createdAt: ISODate("..."),
  updatedAt: ISODate("..."),
  deletedAt: null
}

// Indexes
db.foods.createIndex({ source: 1, externalId: 1 }, { unique: true, sparse: true })
db.foods.createIndex({ barcode: 1 }, { unique: true, sparse: true })
db.foods.createIndex({ createdByUserId: 1 }, { sparse: true })
db.foods.createIndex({ name: "text", brand: "text", searchKeywords: "text" })
db.foods.createIndex({ globalUseCount: -1 })
db.foods.createIndex({ source: 1, isPublic: 1 })
db.foods.createIndex({ cacheExpiresAt: 1 }, { expireAfterSeconds: 0 }) // TTL index for cache cleanup
```

### 4. Food Logs Collection (with embedded meal items)

```javascript
// Collection: foodLogs
{
  _id: ObjectId("..."),
  userId: ObjectId("..."),

  // Temporal Information
  loggedDate: "2026-01-15",        // String YYYY-MM-DD for easy querying
  loggedAt: ISODate("2026-01-15T12:30:00Z"),

  // Meal Categorization
  mealType: "lunch",               // "breakfast" | "lunch" | "dinner" | "snack"
  mealName: null,                  // Optional: "Pre-workout", "Late night snack"

  // Entry Metadata
  entryMethod: "barcode",          // "manual" | "barcode" | "photo_ai" | "voice" | "quick_add" | "copy" | "recipe"

  // EMBEDDED: Meal Items (denormalized for offline-first)
  items: [
    {
      _id: ObjectId("..."),        // Unique ID for each item
      foodId: ObjectId("..."),     // Reference to foods._id (null for quick-add)

      // Quantity
      quantity: 1,
      servingMultiplier: 1.5,      // 1.5 = 150% of serving

      // DENORMALIZED Nutrition (actual consumed values - preserved for history)
      nutrition: {
        calories: 248,
        proteinG: 46.5,
        carbsG: 0,
        fatG: 5.4,
        fiberG: 0,
        sugarG: 0,
        sodiumMg: 111
      },

      // Quick-add fields (when foodId is null)
      quickAddName: null,
      quickAddDescription: null,

      // Food snapshot (for display when offline)
      foodSnapshot: {
        name: "Grilled Chicken Breast",
        brand: null,
        servingDescription: "1 breast (100g)"
      },

      // Display order
      sortOrder: 0,

      // Item metadata
      createdAt: ISODate("..."),
      updatedAt: ISODate("..."),
      deletedAt: null
    }
  ],

  // COMPUTED: Meal Totals (updated when items change)
  totals: {
    calories: 248,
    proteinG: 46.5,
    carbsG: 0,
    fatG: 5.4,
    fiberG: 0,
    sugarG: 0,
    sodiumMg: 111,
    itemCount: 1
  },

  // Notes and Context
  notes: null,
  mood: null,                      // "great" | "good" | "neutral" | "bad" | "terrible"
  hungerLevel: null,               // 1-5

  // Optional Location
  location: {
    name: "Home",
    lat: 37.7749,
    lng: -122.4194
  },

  // Sync Metadata
  version: 1,
  lastSyncedAt: ISODate("..."),

  // Timestamps
  createdAt: ISODate("..."),
  updatedAt: ISODate("..."),
  deletedAt: null
}

// Indexes
db.foodLogs.createIndex({ userId: 1, loggedDate: -1 })
db.foodLogs.createIndex({ userId: 1, loggedDate: 1, mealType: 1 })
db.foodLogs.createIndex({ userId: 1, deletedAt: 1, loggedDate: -1 })
db.foodLogs.createIndex({ "items.foodId": 1 })
db.foodLogs.createIndex({ userId: 1, updatedAt: -1 }) // For sync queries
```

### 5. Weight Logs Collection

```javascript
// Collection: weightLogs
{
  _id: ObjectId("..."),
  userId: ObjectId("..."),

  // Measurement
  weightKg: 84.5,
  measuredAt: ISODate("2026-01-15T07:30:00Z"),
  measuredDate: "2026-01-15",      // String for easy querying

  // Optional Body Composition
  bodyFatPercentage: 22.5,
  muscleMassKg: 35.2,
  waterPercentage: 55.0,
  boneMassKg: 3.1,

  // Source
  source: "smart_scale",           // "manual" | "smart_scale" | "apple_health" | "fitbit" | "garmin"

  // Notes
  notes: "After morning workout",

  // Sync Metadata
  version: 1,
  lastSyncedAt: ISODate("..."),

  // Timestamps
  createdAt: ISODate("..."),
  updatedAt: ISODate("..."),
  deletedAt: null
}

// Indexes
db.weightLogs.createIndex({ userId: 1, measuredDate: -1 })
db.weightLogs.createIndex({ userId: 1, deletedAt: 1 })
```

### 6. Daily Summaries Collection (Pre-computed)

```javascript
// Collection: dailySummaries
{
  _id: ObjectId("..."),
  userId: ObjectId("..."),
  summaryDate: "2026-01-15",       // String YYYY-MM-DD

  // Aggregated Nutrition Totals
  totals: {
    calories: 1650,
    proteinG: 95,
    carbsG: 180,
    fatG: 55,
    fiberG: 22,
    sugarG: 45,
    sodiumMg: 1800
  },

  // Per-meal Breakdowns
  mealBreakdown: {
    breakfast: { calories: 400, itemCount: 3 },
    lunch: { calories: 550, itemCount: 2 },
    dinner: { calories: 600, itemCount: 4 },
    snack: { calories: 100, itemCount: 1 }
  },

  // Counts
  totalMeals: 4,
  totalItems: 10,

  // Goal Snapshot (for historical comparison)
  goalSnapshot: {
    caloriesTarget: 1800,
    proteinTargetG: 120,
    carbsTargetG: 180,
    fatTargetG: 60
  },

  // Completion Metrics
  completion: {
    caloriesPercent: 91.67,
    proteinPercent: 79.17,
    carbsPercent: 100,
    fatPercent: 91.67
  },

  // Computation Metadata
  computedAt: ISODate("..."),
  isComplete: false,               // User marked day as complete

  // Sync Metadata
  version: 1,
  lastSyncedAt: ISODate("..."),

  // Timestamps
  createdAt: ISODate("..."),
  updatedAt: ISODate("...")
}

// Indexes
db.dailySummaries.createIndex({ userId: 1, summaryDate: -1 }, { unique: true })
db.dailySummaries.createIndex({ userId: 1, summaryDate: 1 }) // For range queries
```

### 7. Recent Foods Collection (User's Frequently Used)

```javascript
// Collection: recentFoods
{
  _id: ObjectId("..."),
  userId: ObjectId("..."),
  foodId: ObjectId("..."),         // Reference to foods._id

  // Usage Statistics
  useCount: 15,
  lastUsedAt: ISODate("..."),

  // Preferred Serving
  preferredQuantity: 1,
  preferredServingMultiplier: 1,

  // Meal Association
  commonMealType: "breakfast",     // Most common meal this food is logged to

  // Food Snapshot (for quick display)
  foodSnapshot: {
    name: "Greek Yogurt",
    brand: "Fage",
    calories: 100,
    servingDescription: "1 container (170g)"
  },

  // Sync Metadata
  version: 1,
  lastSyncedAt: ISODate("..."),

  // Timestamps
  createdAt: ISODate("..."),
  updatedAt: ISODate("...")
}

// Indexes
db.recentFoods.createIndex({ userId: 1, foodId: 1 }, { unique: true })
db.recentFoods.createIndex({ userId: 1, lastUsedAt: -1 })
db.recentFoods.createIndex({ userId: 1, useCount: -1 })
```

### 8. Families Collection

```javascript
// Collection: families
{
  _id: ObjectId("..."),

  // Family Information
  name: "Smith Family",
  description: "Our household diet tracking",
  createdByUserId: ObjectId("..."),

  // Settings
  maxMembers: 6,

  // Media
  avatarUrl: "https://...",

  // Sync Metadata
  version: 1,
  lastSyncedAt: ISODate("..."),

  // Timestamps
  createdAt: ISODate("..."),
  updatedAt: ISODate("..."),
  deletedAt: null
}

// Indexes
db.families.createIndex({ createdByUserId: 1 })
db.families.createIndex({ deletedAt: 1 })
```

### 9. Family Members Collection

```javascript
// Collection: familyMembers
{
  _id: ObjectId("..."),
  familyId: ObjectId("..."),
  userId: ObjectId("..."),

  // Role and Permissions
  role: "member",                  // "owner" | "admin" | "member" | "viewer"

  // What this member shares with family
  sharingSettings: {
    shareFoodLogs: true,
    shareGoals: false,
    shareWeight: false
  },

  // What this member can view from others
  viewPermissions: {
    canViewFoodLogs: true,
    canViewGoals: false,
    canViewWeight: false
  },

  // Membership Status
  status: "active",                // "active" | "suspended" | "left"
  joinedAt: ISODate("..."),
  leftAt: null,

  // Notifications
  notifyFamilyMeals: true,

  // Sync Metadata
  version: 1,
  lastSyncedAt: ISODate("..."),

  // Timestamps
  createdAt: ISODate("..."),
  updatedAt: ISODate("..."),
  deletedAt: null
}

// Indexes
db.familyMembers.createIndex({ familyId: 1, userId: 1 }, { unique: true })
db.familyMembers.createIndex({ userId: 1, status: 1 })
db.familyMembers.createIndex({ familyId: 1, status: 1 })
```

### 10. Family Invites Collection

```javascript
// Collection: familyInvites
{
  _id: ObjectId("..."),
  familyId: ObjectId("..."),

  // Invite Details
  invitedByUserId: ObjectId("..."),
  invitedEmail: "spouse@example.com",
  inviteCode: "ABC123XY",          // Short code for sharing

  // Invitation Message
  message: "Join our family's meal tracking!",

  // Proposed Role
  proposedRole: "member",          // "admin" | "member" | "viewer"

  // Status Tracking
  status: "pending",               // "pending" | "accepted" | "declined" | "expired" | "revoked"
  expiresAt: ISODate("2026-01-22"),
  respondedAt: null,
  acceptedByUserId: null,

  // Timestamps
  createdAt: ISODate("..."),
  updatedAt: ISODate("...")
}

// Indexes
db.familyInvites.createIndex({ inviteCode: 1 }, { unique: true })
db.familyInvites.createIndex({ invitedEmail: 1 })
db.familyInvites.createIndex({ familyId: 1 })
db.familyInvites.createIndex({ status: 1, expiresAt: 1 })
```

---

## Data Access Patterns

### Common Queries

```javascript
// 1. Get user's food logs for a date range
db.foodLogs.find({
  userId: ObjectId("..."),
  loggedDate: { $gte: "2026-01-01", $lte: "2026-01-31" },
  deletedAt: null
}).sort({ loggedDate: -1, mealType: 1 })

// 2. Get user's recent foods for quick logging
db.recentFoods.find({
  userId: ObjectId("...")
}).sort({ lastUsedAt: -1 }).limit(20)

// 3. Search foods by name
db.foods.find({
  $text: { $search: "chicken breast" },
  deletedAt: null
}, {
  score: { $meta: "textScore" }
}).sort({ score: { $meta: "textScore" }, globalUseCount: -1 }).limit(20)

// 4. Get family members' shared food logs for today
db.foodLogs.find({
  userId: { $in: [/* family member IDs with sharing enabled */] },
  loggedDate: "2026-01-15",
  deletedAt: null
})

// 5. Get daily summaries for chart (last 30 days)
db.dailySummaries.find({
  userId: ObjectId("..."),
  summaryDate: { $gte: "2025-12-16", $lte: "2026-01-15" }
}).sort({ summaryDate: 1 })

// 6. Sync query: Get all changes since last sync
db.foodLogs.find({
  userId: ObjectId("..."),
  updatedAt: { $gt: ISODate("2026-01-15T10:00:00Z") }
})
```

### Aggregation Pipelines

```javascript
// Compute daily summary from food logs
db.foodLogs.aggregate([
  { $match: { userId: ObjectId("..."), loggedDate: "2026-01-15", deletedAt: null } },
  { $unwind: "$items" },
  { $match: { "items.deletedAt": null } },
  { $group: {
    _id: "$mealType",
    calories: { $sum: "$items.nutrition.calories" },
    proteinG: { $sum: "$items.nutrition.proteinG" },
    carbsG: { $sum: "$items.nutrition.carbsG" },
    fatG: { $sum: "$items.nutrition.fatG" },
    itemCount: { $sum: 1 }
  }},
  { $group: {
    _id: null,
    totalCalories: { $sum: "$calories" },
    totalProteinG: { $sum: "$proteinG" },
    totalCarbsG: { $sum: "$carbsG" },
    totalFatG: { $sum: "$fatG" },
    mealBreakdown: { $push: { mealType: "$_id", calories: "$calories", itemCount: "$itemCount" } }
  }}
])

// Weekly averages
db.dailySummaries.aggregate([
  { $match: { userId: ObjectId("..."), summaryDate: { $gte: "2026-01-08", $lte: "2026-01-14" } } },
  { $group: {
    _id: null,
    avgCalories: { $avg: "$totals.calories" },
    avgProteinG: { $avg: "$totals.proteinG" },
    daysLogged: { $sum: 1 }
  }}
])
```

---

## Migration Notes

### From PostgreSQL/Supabase

1. **UUIDs to ObjectIds**: Generate new ObjectIds, maintain a mapping table during migration
2. **RLS to Application Logic**: Security moves from database to API middleware
3. **Triggers to Application Logic**: Daily summary computation moves to API/sync logic
4. **Foreign Keys to References**: Use ObjectId references with application-level validation

### Data Integrity

Without PostgreSQL's foreign key constraints, enforce referential integrity in the application layer:

```javascript
// Example: Before deleting a user, clean up related data
async function deleteUser(userId) {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    await FoodLog.deleteMany({ userId }, { session });
    await WeightLog.deleteMany({ userId }, { session });
    await UserGoal.deleteMany({ userId }, { session });
    await RecentFood.deleteMany({ userId }, { session });
    await DailySummary.deleteMany({ userId }, { session });
    await FamilyMember.deleteMany({ userId }, { session });
    await User.findByIdAndDelete(userId, { session });

    await session.commitTransaction();
  } catch (error) {
    await session.abortTransaction();
    throw error;
  } finally {
    session.endSession();
  }
}
```

---

## Size Estimates

### At 10,000 MAU

| Collection | Est. Documents | Avg Doc Size | Total Size |
|------------|----------------|--------------|------------|
| users | 10,000 | 1 KB | 10 MB |
| userGoals | 15,000 | 0.5 KB | 7.5 MB |
| foods | 100,000 | 2 KB | 200 MB |
| foodLogs | 3,000,000 | 3 KB | 9 GB |
| weightLogs | 100,000 | 0.3 KB | 30 MB |
| dailySummaries | 1,000,000 | 0.5 KB | 500 MB |
| recentFoods | 500,000 | 0.3 KB | 150 MB |
| families | 2,000 | 0.3 KB | 0.6 MB |
| familyMembers | 5,000 | 0.3 KB | 1.5 MB |
| familyInvites | 10,000 | 0.3 KB | 3 MB |
| **Total** | | | **~10 GB** |

This fits comfortably within a self-hosted MongoDB or requires MongoDB Atlas M10 (~$57/month) for cloud hosting. For the $50/month budget, self-hosting on bare metal is recommended.
