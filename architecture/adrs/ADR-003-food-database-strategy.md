# ADR-003: Food Database Strategy

**Status**: Accepted
**Date**: 2026-01-27
**Decision Makers**: Sebastian (Product Owner), Backend Architecture Team

## Context

A diet tracking app's core value depends on its food database. Users need to:
- Search for foods by name quickly and accurately
- Scan barcodes for packaged products
- Log restaurant meals and branded foods
- Get accurate, detailed nutritional information
- Work offline with recently used foods

No single food database covers all use cases. We need a strategy that balances:
- Data coverage (branded, generic, restaurant)
- Accuracy and freshness
- API costs
- Offline availability
- User experience (speed, relevance)

## Decision

We will implement a **three-tier fallback chain** with intelligent caching:

### Primary: Nutritionix
- Best-in-class branded food and restaurant data
- Excellent natural language parsing
- Barcode database
- Higher cost but highest quality

### Secondary: Open Food Facts
- Free, open-source database
- Strong international coverage
- Excellent for packaged products with barcodes
- Community-maintained

### Tertiary: USDA FoodData Central
- Free government database
- Best for generic/unbranded foods
- Scientific accuracy
- No branded products

### Integration Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         iOS App                                  │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────────────┐ │
│  │ Local Cache  │   │ Recent Foods │   │ Custom Foods (Local) │ │
│  │  (SQLite)    │   │   (Synced)   │   │      (Synced)        │ │
│  └──────┬───────┘   └──────┬───────┘   └──────────┬───────────┘ │
│         │                  │                      │             │
│         └──────────────────┼──────────────────────┘             │
│                            │                                     │
│                    ┌───────▼───────┐                            │
│                    │ Search Router │                            │
│                    └───────┬───────┘                            │
└────────────────────────────┼────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │ Supabase Edge   │
                    │    Functions    │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│  Nutritionix  │   │ Open Food     │   │  USDA FDC    │
│   (Primary)   │   │ Facts (Free)  │   │   (Free)     │
└───────────────┘   └───────────────┘   └───────────────┘
```

## Search Strategy by Input Type

### Text Search

```
1. Check local cache first (< 24 hours old)
2. Check user's recent foods (synced)
3. Check user's custom foods (synced)
4. If online:
   a. Nutritionix natural language search (1 API call)
   b. If < 5 results, supplement with Open Food Facts
   c. Merge, deduplicate, rank by relevance
5. If offline:
   - Return local results only
   - Queue search for when online
```

### Barcode Scan

```
1. Check local barcode cache
2. Check Open Food Facts (free, good barcode coverage)
3. If not found: Check Nutritionix
4. Cache result locally
5. If not found anywhere:
   - Prompt user to create custom food
   - Offer to submit to Open Food Facts
```

### AI Photo Recognition

```
1. Send photo to Edge Function
2. Edge Function calls AI (Claude/GPT-4V)
3. AI returns food identification + estimated portions
4. Search each identified food via text search flow
5. Delete photo immediately (process-and-delete)
6. Return structured meal data
```

## Caching Strategy

### Cache Layers

| Layer | Storage | TTL | Contents |
|-------|---------|-----|----------|
| L1: Memory | App RAM | Session | Last 20 searches |
| L2: Local SQLite | Device | 7 days | All searched/logged foods |
| L3: PostgreSQL | Supabase | 30 days | Popular foods (>10 users) |
| L4: CDN | Edge | 24 hours | Top 1000 foods |

### Cache Invalidation Rules

1. **Popular foods** (logged by >10 users in 30 days):
   - Cache in PostgreSQL for 30 days
   - Refresh from source weekly
   - Serve from cache first

2. **User-specific foods** (individual history):
   - Cache locally for 7 days
   - Sync custom foods via PowerSync
   - Recent foods list syncs across devices

3. **Barcode lookups**:
   - Cache indefinitely (product info rarely changes)
   - Background refresh every 90 days

### Cache Key Structure

```
foods:{source}:{external_id}
foods:barcode:{upc}
search:{query_hash}:{timestamp_day}
```

## API Integration Details

### Nutritionix Configuration

```typescript
// Edge Function: nutritionix-search
const NUTRITIONIX_CONFIG = {
  baseUrl: 'https://trackapi.nutritionix.com/v2',
  endpoints: {
    search: '/search/instant',
    nutrients: '/natural/nutrients',
    barcode: '/search/item'
  },
  headers: {
    'x-app-id': process.env.NUTRITIONIX_APP_ID,
    'x-app-key': process.env.NUTRITIONIX_API_KEY
  },
  rateLimit: {
    requestsPerDay: 500, // Free tier
    requestsPerDay_premium: 10000
  }
};

// Natural language search
async function searchNutritionix(query: string) {
  const response = await fetch(`${NUTRITIONIX_CONFIG.baseUrl}/search/instant`, {
    method: 'GET',
    headers: NUTRITIONIX_CONFIG.headers,
    params: {
      query,
      detailed: true,
      branded: true,
      common: true
    }
  });

  return {
    branded: response.branded,
    common: response.common
  };
}
```

### Open Food Facts Configuration

```typescript
// Edge Function: openfoodfacts-search
const OFF_CONFIG = {
  baseUrl: 'https://world.openfoodfacts.org',
  endpoints: {
    search: '/cgi/search.pl',
    product: '/api/v0/product'
  },
  // No API key needed - open source!
  rateLimit: {
    requestsPerSecond: 10 // Be nice to the free service
  }
};

// Barcode lookup (primary use case for OFF)
async function lookupBarcode(barcode: string) {
  const response = await fetch(
    `${OFF_CONFIG.baseUrl}/api/v0/product/${barcode}.json`
  );

  if (response.status === 1) {
    return normalizeOFFProduct(response.product);
  }
  return null;
}
```

### USDA FoodData Central Configuration

```typescript
// Edge Function: usda-search
const USDA_CONFIG = {
  baseUrl: 'https://api.nal.usda.gov/fdc/v1',
  apiKey: process.env.USDA_API_KEY, // Free, but required
  endpoints: {
    search: '/foods/search',
    food: '/food'
  }
};

// Generic food search
async function searchUSDA(query: string) {
  const response = await fetch(`${USDA_CONFIG.baseUrl}/foods/search`, {
    method: 'POST',
    headers: { 'X-Api-Key': USDA_CONFIG.apiKey },
    body: JSON.stringify({
      query,
      dataType: ['Foundation', 'SR Legacy'],
      pageSize: 10
    })
  });

  return response.foods.map(normalizeUSDAFood);
}
```

## Data Normalization

All food sources must normalize to our standard schema:

```typescript
interface NormalizedFood {
  // Identifiers
  source: 'nutritionix' | 'openfoodfacts' | 'usda' | 'custom';
  externalId: string;
  barcode?: string;

  // Basic info
  name: string;
  brand?: string;
  category?: string;

  // Serving
  servingSize: number;
  servingUnit: string;
  servingDescription?: string;

  // Core nutrition (per serving)
  calories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;

  // Extended nutrition
  fiberG?: number;
  sugarG?: number;
  sodiumMg?: number;
  saturatedFatG?: number;
  cholesterolMg?: number;

  // Media
  photoUrl?: string;
  thumbnailUrl?: string;
}
```

### Source-Specific Normalization

```typescript
function normalizeNutritionixFood(item: any): NormalizedFood {
  return {
    source: 'nutritionix',
    externalId: item.nix_item_id || item.food_name,
    barcode: item.upc,
    name: item.food_name,
    brand: item.brand_name,
    servingSize: item.serving_weight_grams,
    servingUnit: 'g',
    servingDescription: item.serving_unit,
    calories: item.nf_calories,
    proteinG: item.nf_protein,
    carbsG: item.nf_total_carbohydrate,
    fatG: item.nf_total_fat,
    fiberG: item.nf_dietary_fiber,
    sugarG: item.nf_sugars,
    sodiumMg: item.nf_sodium,
    photoUrl: item.photo?.highres,
    thumbnailUrl: item.photo?.thumb
  };
}

function normalizeOFFProduct(product: any): NormalizedFood {
  const nutriments = product.nutriments;
  return {
    source: 'openfoodfacts',
    externalId: product.code,
    barcode: product.code,
    name: product.product_name,
    brand: product.brands,
    category: product.categories_tags?.[0],
    servingSize: parseFloat(product.serving_size) || 100,
    servingUnit: 'g',
    servingDescription: product.serving_size,
    calories: nutriments['energy-kcal_serving'] || nutriments['energy-kcal_100g'],
    proteinG: nutriments.proteins_serving || nutriments.proteins_100g,
    carbsG: nutriments.carbohydrates_serving || nutriments.carbohydrates_100g,
    fatG: nutriments.fat_serving || nutriments.fat_100g,
    fiberG: nutriments.fiber_serving || nutriments.fiber_100g,
    sugarG: nutriments.sugars_serving || nutriments.sugars_100g,
    sodiumMg: (nutriments.sodium_serving || nutriments.sodium_100g) * 1000,
    photoUrl: product.image_url,
    thumbnailUrl: product.image_small_url
  };
}

function normalizeUSDAFood(food: any): NormalizedFood {
  const nutrients = food.foodNutrients.reduce((acc, n) => {
    acc[n.nutrientId] = n.value;
    return acc;
  }, {});

  return {
    source: 'usda',
    externalId: food.fdcId.toString(),
    name: food.description,
    brand: food.brandName,
    servingSize: 100,
    servingUnit: 'g',
    calories: nutrients[1008] || 0,  // Energy (kcal)
    proteinG: nutrients[1003] || 0,   // Protein
    carbsG: nutrients[1005] || 0,     // Carbohydrate
    fatG: nutrients[1004] || 0,       // Total fat
    fiberG: nutrients[1079],          // Fiber
    sugarG: nutrients[2000],          // Total sugars
    sodiumMg: nutrients[1093]         // Sodium
  };
}
```

## Fallback Chain Implementation

```typescript
async function searchFoods(query: string, options: SearchOptions): Promise<NormalizedFood[]> {
  const results: NormalizedFood[] = [];

  // 1. Local cache (always check first)
  const cached = await localCache.search(query);
  if (cached.length > 0) {
    results.push(...cached);
  }

  // 2. User's recent/custom foods
  const userFoods = await searchUserFoods(query);
  results.push(...userFoods);

  // If offline, return what we have
  if (!navigator.onLine) {
    return deduplicateAndRank(results, query);
  }

  // 3. Nutritionix (primary - best quality)
  try {
    const nxResults = await searchNutritionix(query);
    results.push(...nxResults);

    // If Nutritionix returns enough results, skip others
    if (nxResults.length >= 10) {
      return deduplicateAndRank(results, query);
    }
  } catch (error) {
    console.error('Nutritionix search failed:', error);
    // Continue to fallbacks
  }

  // 4. Open Food Facts (supplement branded)
  try {
    const offResults = await searchOpenFoodFacts(query);
    results.push(...offResults);
  } catch (error) {
    console.error('OFF search failed:', error);
  }

  // 5. USDA (generic foods)
  if (results.length < 15) {
    try {
      const usdaResults = await searchUSDA(query);
      results.push(...usdaResults);
    } catch (error) {
      console.error('USDA search failed:', error);
    }
  }

  // Cache all results locally
  await localCache.store(results);

  return deduplicateAndRank(results, query);
}
```

## Consequences

### Positive

1. **Best Coverage**: Three sources cover branded, generic, and international foods
2. **Cost Optimization**: Free sources reduce Nutritionix API calls
3. **Offline Support**: Aggressive caching enables offline use
4. **Fallback Resilience**: If one API fails, others continue working
5. **Data Quality**: Nutritionix first ensures best results for common queries

### Negative

1. **Complexity**: Three APIs mean three different formats to handle
2. **Data Inconsistency**: Same food may have different nutrition across sources
3. **Maintenance**: API changes require updates to normalization logic
4. **Latency**: Fallback chain adds time when primary fails

### Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Nutritionix API costs | Aggressive caching; tiered access; Open Food Facts for barcodes |
| Open Food Facts data quality | Prefer Nutritionix; use OFF mainly for barcodes |
| API rate limiting | Local caching; request queuing; exponential backoff |
| Nutrition data accuracy | Show source to users; allow corrections |

## Cost Projections

### At 10,000 Monthly Active Users

Assumptions:
- Average user: 5 food logs/day, 3 items/log = 15 items/day
- Cache hit rate: 70% (repeat foods)
- Barcode scans: 5/user/week (mostly cached)

| Source | Requests/Month | Cost |
|--------|----------------|------|
| Nutritionix | ~100K (after cache) | ~$500-1,500 |
| Open Food Facts | Unlimited | Free |
| USDA | Unlimited | Free |
| **Total Food DB** | | **~$500-1,500/month** |

## References

- [Nutritionix API Documentation](https://developer.nutritionix.com/docs)
- [Open Food Facts API](https://wiki.openfoodfacts.org/API)
- [USDA FoodData Central API](https://fdc.nal.usda.gov/api-guide.html)
