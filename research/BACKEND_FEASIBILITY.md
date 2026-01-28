# Backend Technical Feasibility Assessment
## Diet App - "The Best Diet App on the Market"

---

## Executive Summary

This document evaluates backend infrastructure options for a premium diet tracking app with offline-first architecture, AI photo recognition, and family sharing capabilities. The assessment covers backend services, food databases, authentication, sync strategies, and API design.

---

## 1. Backend Service Evaluation Matrix

### Comparison Table

| Criteria | Supabase | Firebase | PlanetScale + Auth | Neon + Auth | Custom Bun/Node |
|----------|----------|----------|-------------------|-------------|-----------------|
| **Offline Sync** | Limited (needs custom) | Excellent (built-in) | Manual implementation | Manual implementation | Full control |
| **Real-time** | Excellent (Postgres LISTEN/NOTIFY) | Excellent (native) | Requires additional service | Requires additional service | Needs WebSocket layer |
| **iOS SDK Quality** | Good (community) | Excellent (official) | N/A (REST only) | N/A (REST only) | Custom needed |
| **Developer Experience** | Excellent | Very Good | Good | Excellent | Depends on team |
| **Vendor Lock-in** | Medium (Postgres portable) | High (proprietary) | Low | Low | None |
| **Edge Functions** | Yes (Deno) | Yes (Node) | No | No | Self-hosted |
| **Row-Level Security** | Excellent (native) | Rules-based | Application layer | Application layer | Application layer |

### Cost Projections

| Scale | Supabase | Firebase | PlanetScale | Neon | Custom (Fly.io) |
|-------|----------|----------|-------------|------|-----------------|
| **1K MAU** | $25/mo (Pro) | ~$25/mo | $29/mo + auth | $19/mo + auth | ~$50/mo |
| **10K MAU** | $25-75/mo | ~$100-200/mo | $29-59/mo + auth | $19-69/mo + auth | ~$150/mo |
| **100K MAU** | $75-300/mo | ~$500-1500/mo | $59-299/mo + auth | $69-299/mo + auth | ~$500-1000/mo |

*Note: Firebase costs can spike unpredictably with read-heavy apps. Firestore charges per read operation.*

### Detailed Analysis

#### Supabase
**Pros:**
- PostgreSQL foundation means data is portable
- Excellent Row-Level Security for multi-tenant/family sharing
- Built-in Auth with Sign in with Apple support
- Real-time subscriptions via Postgres replication
- Edge Functions for serverless compute
- Self-hostable as escape hatch

**Cons:**
- No native offline sync (must build with client-side SQLite + custom sync)
- iOS SDK is community-maintained, not official
- Real-time has connection limits on lower tiers

**Risk Level:** Medium — Good balance of features and portability

#### Firebase/Firestore
**Pros:**
- Best-in-class offline sync (automatic, built-in)
- Excellent official iOS SDK
- Real-time listeners are seamless
- Massive scale capacity
- Cloud Functions ecosystem mature

**Cons:**
- Highest vendor lock-in (proprietary query language, data structure)
- Cost unpredictability at scale (read-based pricing)
- No relational data model (document-based)
- Complex queries require denormalization
- Migrating away is painful

**Risk Level:** High lock-in, but lowest implementation effort for offline-first

#### PlanetScale / Neon (Database-only options)
**Pros:**
- Serverless scaling
- Standard SQL (MySQL/Postgres)
- Low lock-in
- Neon has branching for dev/staging

**Cons:**
- Need separate auth solution (adds complexity + cost)
- Need separate real-time solution (Pusher, Ably, etc.)
- More integration work
- No built-in offline sync

**Risk Level:** Lower lock-in, higher implementation complexity

### Recommendation Spectrum

```
Speed to Market ←————————————————————————————→ Long-term Flexibility

Firebase ——— Supabase ——— PlanetScale/Neon ——— Custom
(fastest)    (balanced)   (modular)            (most control)
```

---

## 2. Food Database Strategy

### Option Analysis

#### USDA FoodData Central (Free)
**Data Quality:** High for raw ingredients
**Coverage:** ~380,000 foods (SR Legacy, Foundation, Branded)
**Update Frequency:** Quarterly
**Barcode Support:** Limited (branded foods only)
**Restaurant Data:** None
**International:** US-focused

**Recommendation:** Use as foundation/fallback for raw ingredients

#### Nutritionix API (Paid)
**Pricing:** $0.0025-0.005 per call (volume discounts)
**Data Quality:** Very high, professionally curated
**Coverage:** 1M+ foods including restaurants
**Barcode Support:** Excellent
**Restaurant Data:** Excellent (500k+ restaurant items)
**International:** Good (expanding)
**Natural Language:** Yes ("1 cup of rice")

**Recommendation:** Best option for user-facing searches and barcode scanning

#### Open Food Facts (Free, Crowdsourced)
**Data Quality:** Variable (community-moderated)
**Coverage:** 3M+ products globally
**Barcode Support:** Excellent (primary identifier)
**Restaurant Data:** Limited
**International:** Excellent

**Recommendation:** Good for barcode fallback, but needs verification layer

### Proposed Hybrid Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    Food Search Request                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Local Cache (SQLite on device)                  │
│         - User's recent foods (fast, offline)               │
│         - Custom foods created by user                       │
└─────────────────────────────────────────────────────────────┘
                              │ Cache miss
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Nutritionix API                           │
│         - Natural language search                            │
│         - Barcode lookup (primary)                          │
│         - Restaurant foods                                   │
└─────────────────────────────────────────────────────────────┘
                              │ Not found
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Open Food Facts (Barcode Fallback)             │
│         - International products                             │
│         - Flag as "unverified" in UI                        │
└─────────────────────────────────────────────────────────────┘
                              │ Not found
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    USDA FoodData Central                     │
│         - Generic/raw ingredients                            │
│         - Verified government data                           │
└─────────────────────────────────────────────────────────────┘
```

### Cost Projection (Nutritionix)

| MAU | Searches/User/Day | Monthly Calls | Monthly Cost |
|-----|-------------------|---------------|--------------|
| 1K | 10 | 300K | ~$750 |
| 10K | 10 | 3M | ~$6,000 |
| 100K | 10 | 30M | ~$30,000+ (negotiate) |

**Mitigation Strategies:**
1. Aggressive local caching (user's frequent foods)
2. Pre-cache popular foods in app bundle
3. Batch barcode lookups during sync
4. Consider licensing data dump vs. API calls at scale

---

## 3. Authentication Strategy

### Comparison Matrix

| Feature | Supabase Auth | Firebase Auth | Clerk | Auth0 |
|---------|--------------|---------------|-------|-------|
| **Sign in with Apple** | Yes | Yes | Yes | Yes |
| **Email/Password** | Yes | Yes | Yes | Yes |
| **Social Logins** | Yes | Yes | Yes | Yes |
| **iOS SDK** | Community | Official | Official | Official |
| **Pricing (10K MAU)** | Included | Free | $25/mo | $23/mo |
| **Pricing (100K MAU)** | Included | Free | ~$250/mo | ~$228/mo |
| **MFA** | Yes | Yes | Yes | Yes |
| **Session Management** | Basic | Basic | Excellent | Excellent |

### iOS Token Storage Guidance

Regardless of auth provider, tokens must be stored securely:

```
┌─────────────────────────────────────────────────────────────┐
│                    iOS Keychain Services                     │
│                                                              │
│  - Access Token: kSecAttrAccessibleAfterFirstUnlock         │
│  - Refresh Token: kSecAttrAccessibleAfterFirstUnlockThis... │
│  - Never store in UserDefaults                              │
│  - Never store in plain files                               │
└─────────────────────────────────────────────────────────────┘
```

### Recommendation

**If using Supabase:** Use Supabase Auth (included, well-integrated)
**If using Firebase:** Use Firebase Auth (included, excellent iOS SDK)
**If using custom/PlanetScale/Neon:** Consider Clerk (best DX, reasonable pricing)

**Critical Requirement:** Sign in with Apple is mandatory for iOS apps that offer third-party login.

---

## 4. Offline-First Architecture Design

### Local Storage Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    Device (iOS)                              │
├─────────────────────────────────────────────────────────────┤
│  SQLite Database (via GRDB.swift or similar)                │
│                                                              │
│  Tables:                                                     │
│  - food_log (user's logged meals)                           │
│  - weight_log (measurements)                                │
│  - favorite_foods (cached nutrition data)                   │
│  - meal_plans (generated plans)                             │
│  - grocery_lists (shopping items)                           │
│  - sync_queue (pending changes)                             │
│  - user_settings (preferences, goals)                       │
│                                                              │
│  Cached/Read-Only:                                          │
│  - common_foods (pre-bundled ~10K items)                    │
│  - units_conversions (measurement data)                     │
└─────────────────────────────────────────────────────────────┘
```

### What Works Offline vs. Requires Network

| Feature | Offline | Requires Network |
|---------|---------|------------------|
| Log meals (from cache/recent) | Yes | No |
| Log weight/measurements | Yes | No |
| View history/trends | Yes | No |
| Search cached foods | Yes | No |
| Search new foods | No | Yes |
| Barcode scan (cached) | Yes | No |
| Barcode scan (new) | No | Yes |
| AI photo recognition | No | Yes |
| Sync with family | No | Yes |
| HealthKit read/write | Yes | No |
| Meal plan generation | No | Yes (AI-powered) |
| Grocery list (view) | Yes | No |
| Grocery list (share) | No | Yes |

### Conflict Resolution Strategy

**Approach: Last-Write-Wins with Merge for Collections**

```
┌─────────────────────────────────────────────────────────────┐
│                    Conflict Scenarios                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Same food log entry edited on two devices:              │
│     → Last-write-wins (timestamp comparison)                │
│     → UI shows "edited on [device] at [time]"              │
│                                                              │
│  2. Food log deleted on one, edited on another:             │
│     → Delete wins (user intent was removal)                 │
│     → Optionally: soft-delete + "restore" option           │
│                                                              │
│  3. Family member logs same meal:                           │
│     → Both entries kept (not a conflict)                    │
│     → UI shows who logged what                              │
│                                                              │
│  4. Weight entry at same timestamp:                         │
│     → Keep both, let user resolve                           │
│     → Rare edge case                                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Firebase Advantage

Firebase/Firestore has this built-in with automatic offline persistence and sync. If offline-first is the primary concern, Firebase significantly reduces implementation complexity despite lock-in risks.

**Alternative:** Use PowerSync (open-source Postgres sync) with Supabase for similar capability with less lock-in.

---

## 5. API Design Evaluation

### Recommendation

**For iOS App:** REST with OpenAPI specification
- Generate Swift client from OpenAPI spec
- Simple, well-understood, good tooling
- HTTP caching for offline support

**GraphQL:** Consider only if data relationships become very complex and clients need flexibility.

---

## 6. Health Data & Privacy Considerations

### Security Requirements

| Requirement | Implementation |
|-------------|----------------|
| Encryption at rest | Database encryption (Supabase/Firebase default) |
| Encryption in transit | TLS 1.3 mandatory |
| Data deletion | User can delete all data (GDPR/CCPA) |
| Data export | User can export their data (GDPR) |
| No PII in logs | Structured logging with PII redaction |
| Audit trail | Track data access for compliance |

### HealthKit Data Flow

**Critical:** HealthKit data must NEVER leave the device unless explicitly required for a feature AND user consents.

```
┌─────────────────────────────────────────────────────────────┐
│                    HealthKit Data Flow                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  HealthKit ──► App (local only by default)                  │
│                                                              │
│  If user enables sync:                                       │
│  App ──► Encrypt ──► Server (with explicit consent)         │
│                                                              │
│  Never sync:                                                 │
│  - Raw HealthKit identifiers                                │
│  - Third-party app data from HealthKit                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Preliminary Architecture Recommendation

### Option A: Supabase-Centric (Recommended for Balance)

```
┌─────────────────────────────────────────────────────────────┐
│                         iOS App                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   SwiftUI   │  │   SQLite    │  │     HealthKit       │ │
│  │     UI      │  │   (GRDB)    │  │    Integration      │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       Supabase                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │    Auth     │  │  Postgres   │  │     Realtime        │ │
│  │ (Apple SSO) │  │   (RLS)     │  │   (Family Sync)     │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              Edge Functions (Deno)                      ││
│  │  - TDEE calculation                                     ││
│  │  - Meal plan generation                                 ││
│  │  - Food search aggregation                              ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
   │ Nutritionix │    │   OpenAI    │    │   Apple     │
   │     API     │    │  Vision API │    │   APNs     │
   └─────────────┘    └─────────────┘    └─────────────┘
```

### Option B: Firebase-Centric (Fastest Offline Implementation)

Higher lock-in, but best-in-class offline sync out of the box.

---

## 8. Key Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Nutritionix API costs at scale | High | High | Aggressive caching, negotiate bulk pricing |
| Offline sync complexity | High | Medium | Use Firebase (built-in) or PowerSync |
| Firebase vendor lock-in | Medium | High | Abstract data layer |
| Food database accuracy disputes | Medium | Medium | Clear "verified" vs "community" indicators |
| HealthKit sync edge cases | Medium | High | Extensive testing, conservative sync |

---

## 9. Cost Summary (Monthly Estimates at 10K MAU)

| Service | Low Estimate | High Estimate |
|---------|--------------|---------------|
| Backend (Supabase Pro) | $25 | $75 |
| Auth (included) | $0 | $0 |
| Food API (Nutritionix) | $3,000 | $6,000 |
| AI Vision (per-call) | $500 | $1,500 |
| Push Notifications | $0 | $50 |
| Monitoring/Logging | $50 | $100 |
| **Total** | **$3,575** | **$7,725** |

---

## 10. Questions for Other Agents

### For iOS Agent
1. Local database preference? GRDB.swift, Core Data, or Realm?
2. Offline sync library preference? Custom, PowerSync, or Firebase?
3. State management approach? (affects data layer design)
4. Background sync requirements?
5. Widget data needs?

### For AI/ML Agent
1. Photo recognition latency requirements?
2. Food identification confidence thresholds?
3. Model deployment preference? Cloud API vs. on-device?
4. Training data needs?
5. Meal plan generation approach?

---

## 11. Conclusion & Primary Recommendation

### Primary: Supabase + PowerSync

**Rationale:**
- PostgreSQL provides data portability and powerful queries
- Row-Level Security perfect for family/household sharing
- Supabase Auth includes Sign in with Apple
- PowerSync adds SQLite-based offline sync without Firebase lock-in
- Edge Functions handle backend logic
- Reasonable cost structure that scales predictably

### Alternative: Firebase (if timeline critical)

Accept lock-in for speed to market if needed.

---

*Document prepared by Agent 03: Backend*
*Ready for Manager review and cross-agent discussion*
