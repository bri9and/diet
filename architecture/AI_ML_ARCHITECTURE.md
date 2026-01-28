# AI/ML Architecture Specification
## Diet App - Phase 3: Architecture
### Agent 05: AI/ML

---

## Executive Summary

This document provides the complete AI/ML architecture for the diet app, covering food recognition, natural language processing, personalization, and quality assurance systems. The architecture prioritizes **accuracy over speed**, **privacy over convenience**, and **cost efficiency through intelligent routing**.

**Core Philosophy**: AI convenience WITHOUT accuracy sacrifice. We prevent Cal AI-style catastrophic errors (8,000 cal popcorn) through multi-layer sanity checking while maintaining sub-2-second response times.

---

## 1. AI Pipeline Architecture

### 1.1 Complete Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FOOD RECOGNITION PIPELINE                          │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐
│   INPUT LAYER   │
│  Photo/Text/    │
│    Barcode      │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ON-DEVICE PREPROCESSING                               │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────────────────────┐   │
│  │ Image Quality │  │ Scene Type    │  │ Quick Classification          │   │
│  │ Assessment    │  │ Detection     │  │ (Core ML MobileNet)           │   │
│  │ - Blur check  │  │ - Single food │  │ - Top 500 common foods        │   │
│  │ - Lighting    │  │ - Plate/meal  │  │ - Confidence score            │   │
│  │ - Crop valid  │  │ - Restaurant  │  │ - <200ms latency              │   │
│  └───────────────┘  └───────────────┘  └───────────────────────────────┘   │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          CONFIDENCE ROUTER                                   │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │  Confidence ≥ 90%  →  HIGH: Return local result immediately         │  │
│   │                                                                      │  │
│   │  Confidence 70-89% →  MEDIUM: Cloud verify (async), show local      │  │
│   │                                                                      │  │
│   │  Confidence < 70%  →  LOW: Route to Cloud API                       │  │
│   │                                                                      │  │
│   │  Network unavailable → OFFLINE: Return local with confidence badge  │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    ▼                          ▼
┌───────────────────────────────┐  ┌──────────────────────────────────────────┐
│     HIGH CONFIDENCE PATH      │  │         LOW/MEDIUM CONFIDENCE PATH        │
│  ┌─────────────────────────┐  │  │  ┌────────────────────────────────────┐  │
│  │ Return cached/local     │  │  │  │ Primary: Gemini 1.5 Flash          │  │
│  │ result immediately      │  │  │  │ - Vision analysis                   │  │
│  │                         │  │  │  │ - Portion estimation                │  │
│  │ Target: 65%+ of queries │  │  │  │ - 500-1000ms latency               │  │
│  └─────────────────────────┘  │  │  └────────────────────────────────────┘  │
└───────────────────────────────┘  │                                           │
                                   │  ┌────────────────────────────────────┐  │
                                   │  │ Fallback: Gemini 1.5 Pro           │  │
                                   │  │ - Complex scenes                    │  │
                                   │  │ - Multi-item plates                 │  │
                                   │  │ - Low Flash confidence              │  │
                                   │  └────────────────────────────────────┘  │
                                   └───────────────────┬──────────────────────┘
                                                       │
                                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     NUTRITIONAL DATABASE LOOKUP                              │
│                                                                              │
│  Priority Order:                                                             │
│  1. User's Personal History (exact match from their logs)                   │
│  2. Local Cache (previously looked up foods)                                │
│  3. Nutritionix API (verified, comprehensive)                               │
│  4. Open Food Facts (barcode fallback, international)                       │
│  5. USDA FoodData Central (raw ingredients)                                 │
│  6. AI-Generated Estimate (last resort, clearly flagged)                    │
│                                                                              │
│  Output: food_item, calories, protein, carbs, fat, fiber, serving_size      │
└────────────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SANITY CHECK & VALIDATION ENGINE                          │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ RULE ENGINE                                                          │   │
│  │ ├─ Calorie bounds check (category-specific min/max)                 │   │
│  │ ├─ Macro ratio validation (protein + carbs + fat ≈ calories)        │   │
│  │ ├─ Portion reasonableness (size vs. category norms)                 │   │
│  │ ├─ Historical comparison (user's typical portions)                  │   │
│  │ └─ Cross-reference validation (multiple source agreement)           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ ANOMALY DETECTION                                                    │   │
│  │ ├─ Statistical outlier detection (>3σ from category mean)           │   │
│  │ ├─ Impossible combinations (e.g., 0 cal with macros)                │   │
│  │ └─ AI hallucination patterns (unusually specific false confidence)  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FINAL RESULT                                       │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ PASS: High confidence, sanity checks passed                          │   │
│  │ → Return result with "tap to edit" option                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ MEDIUM: Sanity passed but lower confidence                           │   │
│  │ → Show top 3 options for user selection                              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ FLAG: Sanity check triggered                                         │   │
│  │ → Show warning: "This seems unusual - please verify"                 │   │
│  │ → Require explicit user confirmation                                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ FAIL: Low confidence + sanity failures                               │   │
│  │ → Manual entry flow with AI suggestions                              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Stage-by-Stage Specification

#### Stage 1: Input Processing

**Input Types:**
| Type | Format | Preprocessing |
|------|--------|---------------|
| Photo | JPEG/HEIC, max 4MB | Resize to 1024x1024, EXIF strip |
| Text | UTF-8 string, max 500 chars | Normalize whitespace, lowercase |
| Barcode | EAN-13, UPC-A, QR | Extract numeric code |
| Voice | Audio buffer | Transcribe via iOS Speech |

**Output Format:**
```swift
struct InputProcessingResult {
    let inputType: InputType  // .photo, .text, .barcode, .voice
    let processedData: Data   // Normalized input
    let metadata: InputMetadata // Timestamp, device, location hint
    let qualityScore: Float   // 0.0-1.0 for photos
    let processingTime: TimeInterval
}
```

**Error Handling:**
- Blurry photo (quality < 0.3): Prompt retake with guidance
- Empty/unintelligible text: Show clarification prompt
- Invalid barcode: Fallback to photo analysis
- Network timeout: Queue for retry, return cached if available

**Latency Budget:** 50-100ms

---

#### Stage 2: On-Device Preprocessing

**Image Quality Assessment:**
```swift
struct ImageQualityAssessment {
    let blurScore: Float      // 0.0 (sharp) to 1.0 (blurry)
    let brightnessScore: Float // Optimal range: 0.3-0.7
    let contrastScore: Float   // Minimum acceptable: 0.2
    let cropValidity: Bool     // Food visible in frame
    let overallScore: Float    // Weighted combination

    var isAcceptable: Bool {
        blurScore < 0.4 &&
        brightnessScore > 0.2 && brightnessScore < 0.8 &&
        contrastScore > 0.15 &&
        cropValidity
    }
}
```

**Scene Type Detection:**
| Scene Type | Characteristics | Processing Path |
|------------|-----------------|-----------------|
| Single Food | One distinct item | Standard classification |
| Plate/Meal | Multiple items on plate | Multi-item analysis |
| Restaurant | Menu/branding visible | Restaurant database lookup |
| Packaged | Barcode/label visible | OCR + barcode extraction |
| Beverage | Liquid in container | Beverage-specific model |

**Quick Classification (Core ML):**
- Model: Custom MobileNetV3 fine-tuned on food images
- Input: 224x224 RGB image
- Output: Top 5 predictions with confidence scores
- Classes: 500 most common foods
- Latency: <200ms on iPhone 12+

**Output Format:**
```swift
struct OnDeviceResult {
    let sceneType: SceneType
    let qualityAssessment: ImageQualityAssessment
    let predictions: [FoodPrediction] // Top 5
    let confidence: Float // Highest prediction confidence
    let shouldRouteToCloud: Bool
    let processingTime: TimeInterval
}

struct FoodPrediction {
    let foodId: String
    let name: String
    let confidence: Float
    let category: FoodCategory
}
```

**Error Handling:**
- Model load failure: Fallback to cloud-only mode
- Low quality image: Return with quality warning
- No food detected: Prompt "Is this food?" confirmation

**Latency Budget:** 150-200ms

---

#### Stage 3: Confidence Router

**Routing Logic:**
```swift
func routeRequest(_ result: OnDeviceResult, networkStatus: NetworkStatus) -> RoutingDecision {
    let confidence = result.confidence

    // Offline mode
    if networkStatus == .unavailable {
        return .localWithBadge(confidence: confidence)
    }

    // High confidence - local result
    if confidence >= 0.90 {
        return .localImmediate
    }

    // Medium confidence - local with async verification
    if confidence >= 0.70 {
        return .localWithAsyncVerification
    }

    // Low confidence - cloud required
    if confidence >= 0.50 {
        return .cloudPrimary  // Gemini Flash
    }

    // Very low confidence - complex scene
    return .cloudFallback  // Gemini Pro
}
```

**Routing Decisions:**
| Decision | Action | Expected % |
|----------|--------|------------|
| localImmediate | Return local result, no API call | 35% |
| localWithAsyncVerification | Show local, verify in background | 30% |
| cloudPrimary | Call Gemini Flash | 25% |
| cloudFallback | Call Gemini Pro | 8% |
| localWithBadge | Offline mode, show uncertainty | 2% |

**Output Format:**
```swift
enum RoutingDecision {
    case localImmediate
    case localWithAsyncVerification
    case cloudPrimary
    case cloudFallback
    case localWithBadge(confidence: Float)
}
```

**Latency Budget:** <10ms (logic only)

---

#### Stage 4: Nutritional Database Lookup

**Priority Cascade:**
```swift
func lookupNutrition(for food: IdentifiedFood) async -> NutritionResult {
    // 1. User's personal history (instant, personalized portions)
    if let cached = await userHistoryCache.lookup(food) {
        return .cached(cached, source: .userHistory)
    }

    // 2. Local food cache (previously fetched)
    if let cached = await localFoodCache.lookup(food) {
        return .cached(cached, source: .localCache)
    }

    // 3. Nutritionix API (verified, comprehensive)
    if let result = await nutritionixAPI.lookup(food) {
        await localFoodCache.store(result)
        return .fetched(result, source: .nutritionix)
    }

    // 4. Open Food Facts (international barcodes)
    if let barcode = food.barcode,
       let result = await openFoodFactsAPI.lookup(barcode) {
        return .fetched(result, source: .openFoodFacts, verified: false)
    }

    // 5. USDA FoodData Central (raw ingredients)
    if let result = await usdaAPI.lookup(food) {
        return .fetched(result, source: .usda)
    }

    // 6. AI-generated estimate (last resort)
    return .estimated(await generateAIEstimate(food), source: .aiEstimate)
}
```

**Output Format:**
```swift
struct NutritionData {
    let foodId: String
    let name: String
    let servingSize: ServingSize
    let calories: Int
    let protein: Float      // grams
    let carbohydrates: Float // grams
    let fat: Float          // grams
    let fiber: Float?       // grams, optional
    let sugar: Float?       // grams, optional
    let sodium: Float?      // mg, optional
    let source: DataSource
    let verified: Bool
    let confidence: Float
}

struct ServingSize {
    let amount: Float
    let unit: String        // "g", "ml", "oz", "cup", etc.
    let description: String // "1 medium apple", "1 cup cooked"
}
```

**Error Handling:**
- API timeout: Return cached/estimated with warning
- No match found: Prompt manual entry with suggestions
- Multiple matches: Show selection UI

**Latency Budget:** 100-500ms (cached), 500-1500ms (API)

---

#### Stage 5: Sanity Check & Validation

See Section 4 for complete specification.

**Output Format:**
```swift
struct ValidationResult {
    let status: ValidationStatus  // .passed, .warning, .failed
    let confidence: Float
    let warnings: [ValidationWarning]
    let suggestedCorrections: [CorrectionSuggestion]?
}

enum ValidationStatus {
    case passed          // All checks passed
    case warning         // Minor issues, proceed with notice
    case requiresReview  // User must confirm
    case failed          // Cannot proceed, manual entry required
}
```

**Latency Budget:** <50ms

---

#### Stage 6: Final Result Assembly

**Output Format:**
```swift
struct FoodRecognitionResult {
    let food: NutritionData
    let confidence: ConfidenceLevel
    let source: RecognitionSource
    let alternatives: [NutritionData]?  // Top 3 if ambiguous
    let validationResult: ValidationResult
    let userAction: RequiredUserAction
    let processingMetrics: ProcessingMetrics
}

enum ConfidenceLevel {
    case high       // ≥90%, auto-log enabled
    case medium     // 70-89%, show for confirmation
    case low        // 50-69%, show alternatives
    case veryLow    // <50%, manual entry suggested
}

enum RequiredUserAction {
    case none                    // Auto-loggable
    case tapToEdit               // Show with edit option
    case selectFromOptions       // Must choose from list
    case confirmUnusual          // Sanity warning, confirm
    case manualEntry             // Cannot determine
}

struct ProcessingMetrics {
    let totalLatency: TimeInterval
    let onDeviceLatency: TimeInterval
    let cloudLatency: TimeInterval?
    let databaseLatency: TimeInterval
    let routingDecision: RoutingDecision
    let cacheHit: Bool
}
```

**Total Pipeline Latency Targets:**
| Path | Target | Max |
|------|--------|-----|
| Local only (cache hit) | 300ms | 500ms |
| Local + async verify | 350ms | 600ms |
| Cloud (Gemini Flash) | 1200ms | 2000ms |
| Cloud (Gemini Pro) | 1800ms | 3000ms |

---

## 2. Gemini Integration Specification

### 2.1 API Configuration

**Endpoints:**
```yaml
gemini_flash:
  model: "gemini-1.5-flash-002"
  endpoint: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-002:generateContent"
  use_case: "Primary food recognition, portion estimation"

gemini_pro:
  model: "gemini-1.5-pro-002"
  endpoint: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-002:generateContent"
  use_case: "Complex scenes, multi-item plates, cultural cuisines"
```

**Authentication:**
```swift
// API key stored in iOS Keychain, NEVER hardcoded
struct GeminiConfig {
    static let apiKeyIdentifier = "com.dietapp.gemini.apikey"

    static func getAPIKey() throws -> String {
        guard let key = KeychainWrapper.standard.string(forKey: apiKeyIdentifier) else {
            throw GeminiError.missingAPIKey
        }
        return key
    }
}
```

**Request Configuration:**
```swift
struct GeminiRequestConfig {
    let temperature: Float = 0.1  // Low for consistency
    let topP: Float = 0.8
    let topK: Int = 40
    let maxOutputTokens: Int = 1024
    let candidateCount: Int = 1

    let safetySettings: [SafetySetting] = [
        SafetySetting(category: .harassment, threshold: .blockNone),
        SafetySetting(category: .hateSpeech, threshold: .blockNone),
        SafetySetting(category: .sexuallyExplicit, threshold: .blockNone),
        SafetySetting(category: .dangerousContent, threshold: .blockNone)
    ]
}
```

### 2.2 Prompt Engineering

#### Photo Analysis Prompt

```
SYSTEM PROMPT (Food Recognition):

You are a nutrition analysis AI assistant for a diet tracking app. Your task is to identify foods in photos and estimate their nutritional content.

CRITICAL RULES:
1. ALWAYS be conservative with calorie estimates - it's better to slightly underestimate than wildly overestimate
2. NEVER estimate more than 2000 calories for a single food item unless it's clearly a very large meal
3. If uncertain, provide a range rather than a single number
4. Clearly distinguish between the food item and any container/plate
5. Consider typical serving sizes - most people don't eat extreme portions

OUTPUT FORMAT (JSON only, no markdown):
{
  "foods": [
    {
      "name": "string - common name of the food",
      "category": "string - fruit|vegetable|protein|grain|dairy|beverage|snack|meal|dessert|other",
      "portion": {
        "amount": number,
        "unit": "string - g|ml|oz|cup|piece|slice|serving",
        "description": "string - human readable, e.g., '1 medium apple'"
      },
      "nutrition_estimate": {
        "calories": number,
        "protein_g": number,
        "carbs_g": number,
        "fat_g": number,
        "fiber_g": number | null,
        "confidence": number between 0.0 and 1.0
      },
      "preparation_notes": "string | null - e.g., 'fried', 'with sauce', 'plain'"
    }
  ],
  "scene_description": "string - brief description of what's in the image",
  "overall_confidence": number between 0.0 and 1.0,
  "warnings": ["string"] | null - any concerns about accuracy
}

PORTION SIZE GUIDELINES:
- Small: Less than typical restaurant portion
- Medium: Typical restaurant/home portion
- Large: 1.5x typical portion
- Extra Large: 2x+ typical portion

When estimating from photos:
- A standard dinner plate is ~10-11 inches diameter
- A standard bowl holds ~2 cups
- A fist is approximately 1 cup
- Palm of hand (no fingers) is approximately 3oz protein

USER PROMPT:
Analyze this food photo and provide nutritional information. Be accurate but conservative with estimates.
[IMAGE ATTACHED]
```

#### Portion Refinement Prompt

```
SYSTEM PROMPT (Portion Refinement):

You are helping refine a portion size estimate for food tracking. The user has identified a food item and you need to help determine the accurate portion.

Context provided:
- Food item name
- Initial AI estimate
- Optional: User's correction or description
- Optional: Reference object in image (if any)

Your task:
1. Consider the user's input about portion size
2. Provide a refined estimate
3. Explain your reasoning briefly

OUTPUT FORMAT (JSON only):
{
  "refined_portion": {
    "amount": number,
    "unit": "string",
    "description": "string"
  },
  "nutrition_adjusted": {
    "calories": number,
    "protein_g": number,
    "carbs_g": number,
    "fat_g": number
  },
  "confidence": number,
  "reasoning": "string - brief explanation"
}

USER PROMPT:
Food: {food_name}
Initial estimate: {initial_portion}
User says: "{user_description}"
Reference: {reference_object_if_any}

Provide refined portion estimate.
```

#### NLP Food Parsing Prompt

```
SYSTEM PROMPT (Natural Language Food Parsing):

You are parsing natural language food descriptions into structured data for a diet tracking app.

CRITICAL RULES:
1. Extract EVERY food item mentioned
2. Handle approximate quantities ("about", "roughly", "maybe")
3. Recognize brand names and restaurant items
4. Parse modifiers (large, small, extra, light, etc.)
5. Handle compound descriptions ("coffee with oat milk and two pumps vanilla")

OUTPUT FORMAT (JSON only):
{
  "parsed_items": [
    {
      "original_text": "string - the portion of input describing this item",
      "food_name": "string - normalized food name",
      "quantity": {
        "amount": number,
        "unit": "string",
        "is_approximate": boolean
      },
      "modifiers": ["string"] | null,
      "brand": "string" | null,
      "preparation": "string" | null,
      "confidence": number
    }
  ],
  "unparsed_text": "string | null - any text that couldn't be interpreted",
  "clarification_needed": boolean,
  "clarification_question": "string" | null
}

EXAMPLES:

Input: "turkey sandwich with mayo and lettuce on wheat bread"
Output:
{
  "parsed_items": [
    {
      "original_text": "turkey sandwich with mayo and lettuce on wheat bread",
      "food_name": "turkey sandwich",
      "quantity": {"amount": 1, "unit": "sandwich", "is_approximate": false},
      "modifiers": ["with mayo", "with lettuce", "wheat bread"],
      "brand": null,
      "preparation": null,
      "confidence": 0.95
    }
  ],
  "unparsed_text": null,
  "clarification_needed": false
}

Input: "Large coffee with oat milk and two pumps vanilla from starbucks"
Output:
{
  "parsed_items": [
    {
      "original_text": "Large coffee with oat milk and two pumps vanilla from starbucks",
      "food_name": "coffee",
      "quantity": {"amount": 1, "unit": "large", "is_approximate": false},
      "modifiers": ["oat milk", "2 pumps vanilla syrup"],
      "brand": "Starbucks",
      "preparation": null,
      "confidence": 0.9
    }
  ]
}

Input: "About half a cup of rice with some chicken curry"
Output:
{
  "parsed_items": [
    {
      "original_text": "About half a cup of rice",
      "food_name": "rice",
      "quantity": {"amount": 0.5, "unit": "cup", "is_approximate": true},
      "modifiers": null,
      "brand": null,
      "preparation": "cooked",
      "confidence": 0.85
    },
    {
      "original_text": "some chicken curry",
      "food_name": "chicken curry",
      "quantity": {"amount": 1, "unit": "serving", "is_approximate": true},
      "modifiers": null,
      "brand": null,
      "preparation": null,
      "confidence": 0.7
    }
  ],
  "clarification_needed": true,
  "clarification_question": "How much chicken curry? (e.g., half cup, one cup, small bowl)"
}

USER PROMPT:
Parse this food description: "{user_input}"
```

### 2.3 Response Parsing

```swift
struct GeminiResponseParser {

    func parsePhotoAnalysis(_ response: GeminiResponse) throws -> [ParsedFoodItem] {
        guard let text = response.candidates.first?.content.parts.first?.text else {
            throw ParsingError.emptyResponse
        }

        // Extract JSON from response (handle potential markdown wrapping)
        let jsonString = extractJSON(from: text)

        guard let data = jsonString.data(using: .utf8) else {
            throw ParsingError.invalidEncoding
        }

        let decoded = try JSONDecoder().decode(PhotoAnalysisResponse.self, from: data)

        // Validate response structure
        guard !decoded.foods.isEmpty else {
            throw ParsingError.noFoodsDetected
        }

        // Apply sanity checks to each item
        return decoded.foods.map { food in
            var item = ParsedFoodItem(from: food)
            item.validationResult = SanityChecker.validate(item)
            return item
        }
    }

    private func extractJSON(from text: String) -> String {
        // Handle cases where model wraps JSON in markdown code blocks
        if text.contains("```json") {
            let pattern = "```json\\s*([\\s\\S]*?)\\s*```"
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct PhotoAnalysisResponse: Codable {
    let foods: [FoodAnalysis]
    let sceneDescription: String
    let overallConfidence: Float
    let warnings: [String]?

    enum CodingKeys: String, CodingKey {
        case foods
        case sceneDescription = "scene_description"
        case overallConfidence = "overall_confidence"
        case warnings
    }
}

struct FoodAnalysis: Codable {
    let name: String
    let category: String
    let portion: PortionInfo
    let nutritionEstimate: NutritionEstimate
    let preparationNotes: String?

    enum CodingKeys: String, CodingKey {
        case name, category, portion
        case nutritionEstimate = "nutrition_estimate"
        case preparationNotes = "preparation_notes"
    }
}
```

### 2.4 Error Handling & Retries

```swift
struct GeminiClient {
    private let maxRetries = 3
    private let baseDelay: TimeInterval = 1.0

    func analyze(image: UIImage) async throws -> PhotoAnalysisResponse {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                return try await performRequest(image: image)
            } catch let error as GeminiError {
                lastError = error

                switch error {
                case .rateLimited:
                    // Exponential backoff with jitter
                    let delay = baseDelay * pow(2, Double(attempt)) + Double.random(in: 0...0.5)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue

                case .serverError:
                    // Retry with backoff
                    let delay = baseDelay * pow(2, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue

                case .invalidResponse, .contentFiltered:
                    // Don't retry, these won't change
                    throw error

                case .networkError:
                    // Retry once for transient network issues
                    if attempt < 1 {
                        try await Task.sleep(nanoseconds: 500_000_000)
                        continue
                    }
                    throw error

                case .timeout:
                    // Retry with longer timeout
                    continue

                default:
                    throw error
                }
            }
        }

        throw lastError ?? GeminiError.unknown
    }
}

enum GeminiError: Error {
    case missingAPIKey
    case invalidRequest
    case rateLimited
    case serverError(statusCode: Int)
    case networkError(underlying: Error)
    case timeout
    case invalidResponse
    case contentFiltered
    case unknown
}
```

### 2.5 Rate Limiting Strategy

```swift
class GeminiRateLimiter {
    // Gemini API limits (as of 2025):
    // - Free tier: 60 RPM (requests per minute)
    // - Pay-as-you-go: 1000 RPM

    private let maxRequestsPerMinute: Int
    private var requestTimestamps: [Date] = []
    private let queue = DispatchQueue(label: "com.dietapp.ratelimiter")

    init(tier: GeminiTier) {
        switch tier {
        case .free:
            maxRequestsPerMinute = 60
        case .payAsYouGo:
            maxRequestsPerMinute = 1000
        case .enterprise:
            maxRequestsPerMinute = 5000
        }
    }

    func shouldThrottle() -> Bool {
        queue.sync {
            // Remove timestamps older than 1 minute
            let oneMinuteAgo = Date().addingTimeInterval(-60)
            requestTimestamps.removeAll { $0 < oneMinuteAgo }

            return requestTimestamps.count >= maxRequestsPerMinute
        }
    }

    func recordRequest() {
        queue.sync {
            requestTimestamps.append(Date())
        }
    }

    func estimatedWaitTime() -> TimeInterval? {
        queue.sync {
            guard requestTimestamps.count >= maxRequestsPerMinute else {
                return nil
            }

            let oldestRelevant = requestTimestamps[requestTimestamps.count - maxRequestsPerMinute]
            let waitUntil = oldestRelevant.addingTimeInterval(60)
            let waitTime = waitUntil.timeIntervalSinceNow

            return waitTime > 0 ? waitTime : nil
        }
    }
}
```

---

## 3. Core ML Model Specification

### 3.1 Model Architecture

**Selected Architecture: MobileNetV3-Large (Fine-tuned)**

| Specification | Value |
|--------------|-------|
| Base Model | MobileNetV3-Large |
| Input Size | 224 x 224 x 3 (RGB) |
| Output Classes | 500 (expandable) |
| Model Size | ~25MB (quantized) |
| Inference Time | <100ms (iPhone 12+) |
| Memory Footprint | ~150MB runtime |

**Why MobileNetV3:**
- Optimized for mobile inference
- Excellent accuracy/speed tradeoff
- Well-supported by Core ML
- Small enough for on-device updates

**Class Categories (500 total):**
```
Fruits (50):        apple, banana, orange, strawberry, blueberry, ...
Vegetables (50):    broccoli, carrot, spinach, tomato, cucumber, ...
Proteins (60):      chicken breast, salmon, steak, eggs, tofu, ...
Grains (40):        rice, pasta, bread, oatmeal, quinoa, ...
Dairy (30):         milk, cheese, yogurt, butter, ice cream, ...
Beverages (40):     coffee, tea, juice, soda, water, smoothie, ...
Snacks (50):        chips, crackers, popcorn, nuts, cookies, ...
Meals (80):         pizza, burger, salad, sandwich, sushi, tacos, ...
Desserts (40):      cake, pie, brownie, donut, chocolate, ...
Condiments (30):    ketchup, mustard, mayo, salsa, dressing, ...
Other (30):         soup, sauce, dip, spread, ...
```

### 3.2 Input Requirements

```swift
struct CoreMLInputProcessor {
    static let inputSize = CGSize(width: 224, height: 224)
    static let pixelMean: [Float] = [0.485, 0.456, 0.406]  // ImageNet normalization
    static let pixelStd: [Float] = [0.229, 0.224, 0.225]

    func preprocess(_ image: UIImage) throws -> MLMultiArray {
        // 1. Resize to 224x224 with aspect fill + center crop
        guard let resized = resize(image, to: Self.inputSize) else {
            throw PreprocessingError.resizeFailed
        }

        // 2. Convert to pixel buffer
        guard let pixelBuffer = resized.pixelBuffer() else {
            throw PreprocessingError.pixelBufferCreationFailed
        }

        // 3. Normalize with ImageNet stats
        let normalized = normalize(pixelBuffer, mean: Self.pixelMean, std: Self.pixelStd)

        return normalized
    }

    private func resize(_ image: UIImage, to size: CGSize) -> UIImage? {
        // Center crop to square, then resize
        let aspectRatio = image.size.width / image.size.height
        var cropRect: CGRect

        if aspectRatio > 1 {
            // Wider than tall - crop sides
            let newWidth = image.size.height
            let xOffset = (image.size.width - newWidth) / 2
            cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: image.size.height)
        } else {
            // Taller than wide - crop top/bottom
            let newHeight = image.size.width
            let yOffset = (image.size.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: yOffset, width: image.size.width, height: newHeight)
        }

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return nil
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
```

### 3.3 Output Format

```swift
struct CoreMLOutput {
    let predictions: [FoodClassPrediction]
    let processingTime: TimeInterval
    let modelVersion: String

    struct FoodClassPrediction {
        let classId: Int
        let className: String
        let confidence: Float  // 0.0 to 1.0
        let category: FoodCategory
    }

    var topPrediction: FoodClassPrediction? {
        predictions.first
    }

    var isHighConfidence: Bool {
        guard let top = topPrediction else { return false }
        return top.confidence >= 0.90
    }

    var needsCloudVerification: Bool {
        guard let top = topPrediction else { return true }
        return top.confidence < 0.70
    }
}

class FoodClassifier {
    private let model: VNCoreMLModel
    private let classLabels: [Int: (name: String, category: FoodCategory)]

    func classify(_ image: UIImage) async throws -> CoreMLOutput {
        let startTime = CFAbsoluteTimeGetCurrent()

        guard let cgImage = image.cgImage else {
            throw ClassificationError.invalidImage
        }

        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let results = request.results as? [VNClassificationObservation] else {
            throw ClassificationError.noResults
        }

        let predictions = results.prefix(5).compactMap { observation -> CoreMLOutput.FoodClassPrediction? in
            guard let classId = Int(observation.identifier),
                  let labelInfo = classLabels[classId] else {
                return nil
            }

            return CoreMLOutput.FoodClassPrediction(
                classId: classId,
                className: labelInfo.name,
                confidence: observation.confidence,
                category: labelInfo.category
            )
        }

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        return CoreMLOutput(
            predictions: Array(predictions),
            processingTime: processingTime,
            modelVersion: "1.0.0"
        )
    }
}
```

### 3.4 Model Size Constraints

**Size Budget:**
| Component | Max Size |
|-----------|----------|
| Core ML Model | 25MB |
| Class Labels JSON | 500KB |
| Portion Estimation Model | 10MB |
| Total On-Device ML | <40MB |

**Quantization Strategy:**
```
Original Float32 Model: ~85MB
↓
INT8 Quantization: ~22MB (74% reduction)
↓
Neural Engine Optimized: ~25MB final
```

### 3.5 Model Update Strategy

```swift
class ModelUpdateManager {
    private let currentModelVersion = "1.0.0"
    private let modelUpdateURL = URL(string: "https://api.dietapp.com/models/food-classifier")!

    struct ModelManifest: Codable {
        let version: String
        let downloadURL: URL
        let checksum: String
        let size: Int64
        let releaseNotes: String
        let minAppVersion: String
    }

    func checkForUpdates() async throws -> ModelManifest? {
        let manifestURL = modelUpdateURL.appendingPathComponent("manifest.json")
        let (data, _) = try await URLSession.shared.data(from: manifestURL)
        let manifest = try JSONDecoder().decode(ModelManifest.self, from: data)

        // Check if update available and compatible
        guard manifest.version > currentModelVersion,
              isAppVersionCompatible(manifest.minAppVersion) else {
            return nil
        }

        return manifest
    }

    func downloadAndInstall(_ manifest: ModelManifest) async throws {
        // 1. Download in background
        let (tempURL, _) = try await URLSession.shared.download(from: manifest.downloadURL)

        // 2. Verify checksum
        let downloadedChecksum = try computeSHA256(of: tempURL)
        guard downloadedChecksum == manifest.checksum else {
            throw ModelUpdateError.checksumMismatch
        }

        // 3. Compile Core ML model
        let compiledURL = try MLModel.compileModel(at: tempURL)

        // 4. Move to app's model directory
        let modelDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Models")

        try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)

        let destinationURL = modelDir.appendingPathComponent("FoodClassifier.mlmodelc")

        // Atomic replace
        _ = try FileManager.default.replaceItemAt(destinationURL, withItemAt: compiledURL)

        // 5. Update version tracking
        UserDefaults.standard.set(manifest.version, forKey: "installedModelVersion")

        // 6. Reload model
        try await reloadModel()
    }

    // Update checks:
    // - On app launch (if >24h since last check)
    // - On background refresh
    // - Never during active use
}
```

---

## 4. Sanity Check System

### 4.1 Design Philosophy

**Goal**: Prevent Cal AI-style catastrophic errors while maintaining user trust.

**Principles:**
1. Never auto-log anything that seems unreasonable
2. Flag unusual values, don't silently correct
3. Learn from user behavior to reduce false positives
4. Err on the side of caution (false positives > false negatives)

### 4.2 Calorie Bounds by Category

```swift
struct CalorieBounds {
    let category: FoodCategory
    let minPerServing: Int
    let maxPerServing: Int
    let typicalRange: ClosedRange<Int>
    let absoluteMax: Int  // Never exceed regardless of portion

    static let bounds: [FoodCategory: CalorieBounds] = [
        .fruit: CalorieBounds(
            category: .fruit,
            minPerServing: 15,
            maxPerServing: 200,
            typicalRange: 50...120,
            absoluteMax: 400
        ),
        .vegetable: CalorieBounds(
            category: .vegetable,
            minPerServing: 5,
            maxPerServing: 150,
            typicalRange: 20...80,
            absoluteMax: 300
        ),
        .protein: CalorieBounds(
            category: .protein,
            minPerServing: 50,
            maxPerServing: 800,
            typicalRange: 150...400,
            absoluteMax: 1500
        ),
        .grain: CalorieBounds(
            category: .grain,
            minPerServing: 50,
            maxPerServing: 600,
            typicalRange: 100...350,
            absoluteMax: 1000
        ),
        .dairy: CalorieBounds(
            category: .dairy,
            minPerServing: 20,
            maxPerServing: 500,
            typicalRange: 80...250,
            absoluteMax: 800
        ),
        .beverage: CalorieBounds(
            category: .beverage,
            minPerServing: 0,
            maxPerServing: 600,
            typicalRange: 0...200,
            absoluteMax: 1000
        ),
        .snack: CalorieBounds(
            category: .snack,
            minPerServing: 50,
            maxPerServing: 600,
            typicalRange: 100...350,
            absoluteMax: 1000
        ),
        .meal: CalorieBounds(
            category: .meal,
            minPerServing: 200,
            maxPerServing: 1500,
            typicalRange: 400...900,
            absoluteMax: 2500
        ),
        .dessert: CalorieBounds(
            category: .dessert,
            minPerServing: 50,
            maxPerServing: 800,
            typicalRange: 150...450,
            absoluteMax: 1500
        ),
        .condiment: CalorieBounds(
            category: .condiment,
            minPerServing: 0,
            maxPerServing: 200,
            typicalRange: 10...100,
            absoluteMax: 400
        )
    ]
}
```

### 4.3 Validation Rules Engine

```swift
class SanityChecker {

    struct ValidationResult {
        let passed: Bool
        let warnings: [SanityWarning]
        let suggestedCorrections: [Correction]?
        let requiresUserConfirmation: Bool
    }

    enum SanityWarning {
        case caloriesAboveMax(actual: Int, max: Int)
        case caloriesBelowMin(actual: Int, min: Int)
        case macrosMismatchCalories(calculatedCals: Int, reportedCals: Int)
        case unusualPortion(size: String, typical: String)
        case statisticalOutlier(zScore: Float)
        case impossibleCombination(reason: String)
        case lowConfidenceEstimate(confidence: Float)
    }

    func validate(_ item: FoodItem) -> ValidationResult {
        var warnings: [SanityWarning] = []
        var corrections: [Correction] = []

        // Rule 1: Calorie bounds check
        if let bounds = CalorieBounds.bounds[item.category] {
            if item.calories > bounds.absoluteMax {
                warnings.append(.caloriesAboveMax(actual: item.calories, max: bounds.absoluteMax))
                corrections.append(.suggestCalories(bounds.maxPerServing))
            }
            if item.calories < bounds.minPerServing && item.calories > 0 {
                warnings.append(.caloriesBelowMin(actual: item.calories, min: bounds.minPerServing))
            }
        }

        // Rule 2: Macro ratio validation
        // Protein: 4 cal/g, Carbs: 4 cal/g, Fat: 9 cal/g
        let calculatedCalories = Int(
            item.protein * 4 +
            item.carbohydrates * 4 +
            item.fat * 9
        )
        let calorieDifference = abs(calculatedCalories - item.calories)
        let tolerancePercent = 0.15  // 15% tolerance

        if Float(calorieDifference) > Float(item.calories) * Float(tolerancePercent) && item.calories > 50 {
            warnings.append(.macrosMismatchCalories(
                calculatedCals: calculatedCalories,
                reportedCals: item.calories
            ))
        }

        // Rule 3: Portion reasonableness
        if let portionWarning = checkPortionReasonableness(item) {
            warnings.append(portionWarning)
        }

        // Rule 4: Statistical outlier detection
        if let zScore = calculateZScore(item), abs(zScore) > 3.0 {
            warnings.append(.statisticalOutlier(zScore: zScore))
        }

        // Rule 5: Impossible combinations
        if let impossibleReason = checkImpossibleCombinations(item) {
            warnings.append(.impossibleCombination(reason: impossibleReason))
        }

        // Rule 6: Confidence threshold
        if item.confidence < 0.5 {
            warnings.append(.lowConfidenceEstimate(confidence: item.confidence))
        }

        // Determine if user confirmation required
        let hasCriticalWarning = warnings.contains { warning in
            switch warning {
            case .caloriesAboveMax, .impossibleCombination, .statisticalOutlier:
                return true
            default:
                return false
            }
        }

        return ValidationResult(
            passed: warnings.isEmpty,
            warnings: warnings,
            suggestedCorrections: corrections.isEmpty ? nil : corrections,
            requiresUserConfirmation: hasCriticalWarning
        )
    }

    private func checkPortionReasonableness(_ item: FoodItem) -> SanityWarning? {
        // Category-specific portion checks
        switch item.category {
        case .beverage:
            // Beverages > 1 liter are unusual for single serving
            if item.portion.amountInMl > 1000 {
                return .unusualPortion(size: item.portion.description, typical: "200-500ml")
            }
        case .fruit:
            // More than 5 pieces of fruit is unusual
            if item.portion.unit == "piece" && item.portion.amount > 5 {
                return .unusualPortion(size: item.portion.description, typical: "1-3 pieces")
            }
        case .meal:
            // Meals over 2000 calories should be flagged
            if item.calories > 2000 {
                return .unusualPortion(size: "\(item.calories) cal", typical: "400-1200 cal")
            }
        default:
            break
        }
        return nil
    }

    private func checkImpossibleCombinations(_ item: FoodItem) -> String? {
        // Zero calories but has macros
        if item.calories == 0 && (item.protein > 1 || item.carbohydrates > 1 || item.fat > 1) {
            return "Zero calories but contains macronutrients"
        }

        // More fat than total weight
        if let weightInGrams = item.portion.weightInGrams {
            if item.fat > weightInGrams {
                return "Fat content exceeds total weight"
            }
            if item.protein > weightInGrams {
                return "Protein content exceeds total weight"
            }
        }

        // Negative values
        if item.calories < 0 || item.protein < 0 || item.carbohydrates < 0 || item.fat < 0 {
            return "Negative nutritional values"
        }

        return nil
    }

    private func calculateZScore(_ item: FoodItem) -> Float? {
        // Compare against category statistics
        guard let stats = CategoryStatistics.stats[item.category] else {
            return nil
        }

        let zScore = (Float(item.calories) - stats.meanCalories) / stats.stdDevCalories
        return zScore
    }
}

struct CategoryStatistics {
    let category: FoodCategory
    let meanCalories: Float
    let stdDevCalories: Float

    static let stats: [FoodCategory: CategoryStatistics] = [
        .fruit: CategoryStatistics(category: .fruit, meanCalories: 80, stdDevCalories: 40),
        .vegetable: CategoryStatistics(category: .vegetable, meanCalories: 45, stdDevCalories: 30),
        .protein: CategoryStatistics(category: .protein, meanCalories: 250, stdDevCalories: 100),
        .grain: CategoryStatistics(category: .grain, meanCalories: 200, stdDevCalories: 80),
        .dairy: CategoryStatistics(category: .dairy, meanCalories: 150, stdDevCalories: 80),
        .beverage: CategoryStatistics(category: .beverage, meanCalories: 100, stdDevCalories: 100),
        .snack: CategoryStatistics(category: .snack, meanCalories: 200, stdDevCalories: 100),
        .meal: CategoryStatistics(category: .meal, meanCalories: 650, stdDevCalories: 250),
        .dessert: CategoryStatistics(category: .dessert, meanCalories: 300, stdDevCalories: 150),
        .condiment: CategoryStatistics(category: .condiment, meanCalories: 50, stdDevCalories: 40)
    ]
}
```

### 4.4 Human Review Triggers

```swift
enum ReviewTrigger {
    case caloriesExceedAbsoluteMax
    case statisticalOutlierDetected
    case impossibleCombination
    case veryLowConfidence
    case multipleWarnings
    case userReportedError
}

class ReviewDecisionEngine {

    func shouldRequireReview(
        item: FoodItem,
        validationResult: SanityChecker.ValidationResult,
        userHistory: UserFoodHistory?
    ) -> (required: Bool, trigger: ReviewTrigger?) {

        // Always require review for impossible combinations
        if validationResult.warnings.contains(where: {
            if case .impossibleCombination = $0 { return true }
            return false
        }) {
            return (true, .impossibleCombination)
        }

        // Always require review for extreme outliers
        if let outlierWarning = validationResult.warnings.first(where: {
            if case .statisticalOutlier(let zScore) = $0, abs(zScore) > 4.0 {
                return true
            }
            return false
        }) {
            return (true, .statisticalOutlierDetected)
        }

        // Require review if calories exceed absolute max
        if validationResult.warnings.contains(where: {
            if case .caloriesAboveMax = $0 { return true }
            return false
        }) {
            return (true, .caloriesExceedAbsoluteMax)
        }

        // Require review for very low confidence with no similar history
        if item.confidence < 0.4 {
            if let history = userHistory, !history.hasLoggedSimilar(to: item) {
                return (true, .veryLowConfidence)
            }
        }

        // Require review if multiple warnings
        if validationResult.warnings.count >= 3 {
            return (true, .multipleWarnings)
        }

        return (false, nil)
    }
}
```

### 4.5 Sanity Check UI Responses

| Validation Status | UI Response | Auto-log? |
|------------------|-------------|-----------|
| All checks passed, high confidence | "Logged: [Food]" with undo option | Yes |
| All checks passed, medium confidence | Show with "Is this correct?" prompt | No |
| Minor warnings | Show with yellow indicator, editable | No |
| Major warning (unusual amount) | "This seems unusual - please verify" | No |
| Critical failure | "We couldn't determine this accurately" + manual entry | No |

---

## 5. Personalization Engine

### 5.1 Architecture Overview

**All personalization runs ON-DEVICE for privacy.**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      ON-DEVICE PERSONALIZATION ENGINE                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    USER BEHAVIOR TRACKER                               │  │
│  │  - Food logging patterns (time, frequency, types)                     │  │
│  │  - Portion size adjustments (user corrections)                        │  │
│  │  - Favorite foods and meals                                           │  │
│  │  - Meal timing patterns                                               │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                    │                                         │
│                                    ▼                                         │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    PREFERENCE LEARNING MODEL                           │  │
│  │  - Food preference scoring                                            │  │
│  │  - Portion size personalization                                       │  │
│  │  - Time-of-day patterns                                               │  │
│  │  - Day-of-week patterns                                               │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                    │                                         │
│                                    ▼                                         │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    PREDICTION ENGINE                                   │  │
│  │  - Meal suggestions                                                   │  │
│  │  - Quick-add recommendations                                          │  │
│  │  - Portion size defaults                                              │  │
│  │  - Forgotten food reminders                                           │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 User Preference Learning

```swift
class PreferenceLearner {

    struct UserPreferences: Codable {
        var foodPreferences: [String: FoodPreference]  // foodId -> preference
        var portionAdjustments: [String: Float]        // foodId -> multiplier
        var mealTimings: [MealType: TimeRange]         // typical meal times
        var dayPatterns: [Int: [String]]               // dayOfWeek -> common foods
    }

    struct FoodPreference: Codable {
        let foodId: String
        var logCount: Int
        var lastLogged: Date
        var averageRating: Float?  // If user provides feedback
        var corrections: Int       // How often user edits this item

        var preferenceScore: Float {
            // Higher score = more likely to suggest
            let recencyBonus = min(1.0, 30.0 / max(1, Date().timeIntervalSince(lastLogged) / 86400))
            let frequencyScore = min(1.0, Float(logCount) / 30.0)
            let correctionPenalty = Float(corrections) / Float(max(1, logCount)) * 0.3

            return (frequencyScore * 0.5 + Float(recencyBonus) * 0.3 + (averageRating ?? 0.7) * 0.2) - correctionPenalty
        }
    }

    private var preferences: UserPreferences
    private let storage: LocalStorage

    func recordFoodLogged(_ food: FoodItem) {
        var pref = preferences.foodPreferences[food.id] ?? FoodPreference(
            foodId: food.id,
            logCount: 0,
            lastLogged: Date(),
            averageRating: nil,
            corrections: 0
        )

        pref.logCount += 1
        pref.lastLogged = Date()

        preferences.foodPreferences[food.id] = pref

        // Update day patterns
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        var dayFoods = preferences.dayPatterns[dayOfWeek] ?? []
        if !dayFoods.contains(food.id) {
            dayFoods.append(food.id)
            preferences.dayPatterns[dayOfWeek] = dayFoods
        }

        savePreferences()
    }

    func recordCorrection(originalFood: FoodItem, correctedFood: FoodItem) {
        // Track that user corrected this item
        if var pref = preferences.foodPreferences[originalFood.id] {
            pref.corrections += 1
            preferences.foodPreferences[originalFood.id] = pref
        }

        // Learn portion adjustment
        if originalFood.name == correctedFood.name {
            let portionRatio = correctedFood.portion.amount / originalFood.portion.amount
            updatePortionAdjustment(for: originalFood.id, ratio: portionRatio)
        }

        savePreferences()
    }

    private func updatePortionAdjustment(for foodId: String, ratio: Float) {
        let existingAdjustment = preferences.portionAdjustments[foodId] ?? 1.0
        // Weighted average favoring recent corrections
        let newAdjustment = existingAdjustment * 0.7 + ratio * 0.3
        preferences.portionAdjustments[foodId] = newAdjustment
    }
}
```

### 5.3 Meal Prediction Algorithm

```swift
class MealPredictor {

    private let preferenceLearner: PreferenceLearner
    private let userHistory: UserFoodHistory

    struct PredictionContext {
        let currentTime: Date
        let dayOfWeek: Int
        let recentMeals: [LoggedMeal]  // Last 24 hours
        let currentCalories: Int
        let calorieGoal: Int
    }

    func predictQuickAddOptions(context: PredictionContext) -> [QuickAddSuggestion] {
        var suggestions: [QuickAddSuggestion] = []

        // 1. Time-based meal type prediction
        let mealType = predictMealType(from: context.currentTime)

        // 2. Get foods commonly eaten at this time
        let timeBasedFoods = getTimeBasedFoods(mealType: mealType, dayOfWeek: context.dayOfWeek)

        // 3. Score each food based on multiple factors
        let scoredFoods = timeBasedFoods.map { food -> (FoodItem, Float) in
            let score = calculateSuggestionScore(
                food: food,
                context: context,
                mealType: mealType
            )
            return (food, score)
        }

        // 4. Sort by score and take top results
        let topFoods = scoredFoods
            .sorted { $0.1 > $1.1 }
            .prefix(5)

        for (food, score) in topFoods {
            // Apply learned portion adjustment
            let adjustedPortion = applyPortionAdjustment(food)

            suggestions.append(QuickAddSuggestion(
                food: adjustedPortion,
                reason: generateReason(food: food, mealType: mealType, context: context),
                confidence: score
            ))
        }

        // 5. Add "Something else" option
        suggestions.append(QuickAddSuggestion(
            food: nil,
            reason: "Search for something different",
            confidence: 1.0
        ))

        return suggestions
    }

    private func calculateSuggestionScore(
        food: FoodItem,
        context: PredictionContext,
        mealType: MealType
    ) -> Float {
        var score: Float = 0.0

        // Factor 1: User preference (0-0.3)
        if let pref = preferenceLearner.preferences.foodPreferences[food.id] {
            score += pref.preferenceScore * 0.3
        }

        // Factor 2: Time-of-day match (0-0.25)
        let timeMatch = calculateTimeMatch(food: food, mealType: mealType)
        score += timeMatch * 0.25

        // Factor 3: Day-of-week pattern (0-0.2)
        let dayMatch = calculateDayMatch(food: food, dayOfWeek: context.dayOfWeek)
        score += dayMatch * 0.2

        // Factor 4: Nutritional fit (0-0.15)
        let remainingCalories = context.calorieGoal - context.currentCalories
        let nutritionalFit = calculateNutritionalFit(food: food, remaining: remainingCalories)
        score += nutritionalFit * 0.15

        // Factor 5: Recency (0-0.1) - slightly favor things not eaten today
        let recencyScore = calculateRecencyScore(food: food, recentMeals: context.recentMeals)
        score += recencyScore * 0.1

        return score
    }

    private func generateReason(food: FoodItem, mealType: MealType, context: PredictionContext) -> String {
        // Generate human-readable reason for suggestion

        if let pref = preferenceLearner.preferences.foodPreferences[food.id] {
            if pref.logCount >= 10 {
                return "One of your favorites"
            }
        }

        // Check if eaten at this time before
        let dayOfWeek = Calendar.current.component(.weekday, from: context.currentTime)
        if preferenceLearner.preferences.dayPatterns[dayOfWeek]?.contains(food.id) == true {
            let dayName = Calendar.current.weekdaySymbols[dayOfWeek - 1]
            return "You often have this on \(dayName)s"
        }

        switch mealType {
        case .breakfast:
            return "Quick breakfast option"
        case .lunch:
            return "Based on your lunch patterns"
        case .dinner:
            return "Popular dinner choice"
        case .snack:
            return "Light snack option"
        }
    }
}
```

### 5.4 Portion Adjustment Learning

```swift
class PortionLearner {

    struct PortionHistory: Codable {
        var adjustments: [PortionAdjustment]
        var learnedMultiplier: Float

        struct PortionAdjustment: Codable {
            let originalAmount: Float
            let correctedAmount: Float
            let timestamp: Date
        }
    }

    private var portionHistories: [String: PortionHistory] = [:]  // foodId -> history

    func learnFromCorrection(foodId: String, original: Float, corrected: Float) {
        var history = portionHistories[foodId] ?? PortionHistory(
            adjustments: [],
            learnedMultiplier: 1.0
        )

        let adjustment = PortionHistory.PortionAdjustment(
            originalAmount: original,
            correctedAmount: corrected,
            timestamp: Date()
        )

        history.adjustments.append(adjustment)

        // Keep only last 20 adjustments
        if history.adjustments.count > 20 {
            history.adjustments.removeFirst()
        }

        // Recalculate learned multiplier using weighted average
        // More recent corrections have higher weight
        var totalWeight: Float = 0
        var weightedSum: Float = 0

        for (index, adj) in history.adjustments.enumerated() {
            let recencyWeight = Float(index + 1) / Float(history.adjustments.count)
            let ratio = adj.correctedAmount / adj.originalAmount

            totalWeight += recencyWeight
            weightedSum += ratio * recencyWeight
        }

        history.learnedMultiplier = weightedSum / totalWeight

        portionHistories[foodId] = history
    }

    func getAdjustedPortion(for foodId: String, basePortion: Float) -> Float {
        guard let history = portionHistories[foodId] else {
            return basePortion
        }

        // Only apply if we have enough data points and consistent pattern
        guard history.adjustments.count >= 3 else {
            return basePortion
        }

        // Check consistency (standard deviation of multipliers)
        let multipliers = history.adjustments.map { $0.correctedAmount / $0.originalAmount }
        let stdDev = standardDeviation(multipliers)

        // Only apply if adjustments are consistent (low std dev)
        if stdDev < 0.3 {
            return basePortion * history.learnedMultiplier
        }

        return basePortion
    }
}
```

### 5.5 Privacy-Preserving Approach

**All personalization data stays on-device:**

```swift
struct PrivacyPolicy {

    // Data that NEVER leaves the device:
    static let localOnlyData: Set<String> = [
        "food_preferences",
        "portion_adjustments",
        "meal_timing_patterns",
        "eating_habits",
        "health_goals",
        "weight_history",
        "food_log_details",
        "personalization_model"
    ]

    // Data that MAY be sent to cloud (anonymized, with consent):
    static let optionalCloudData: Set<String> = [
        "aggregate_food_frequencies",  // No user linkage
        "correction_patterns",         // Helps improve AI
        "error_reports"               // With user consent
    ]
}

class PersonalizationStorage {
    private let fileProtection = FileProtectionType.completeUntilFirstUserAuthentication
    private let encryptionKey: SymmetricKey  // Derived from device + user

    private var storageURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Personalization")
    }

    func save(_ preferences: UserPreferences) throws {
        let data = try JSONEncoder().encode(preferences)
        let encryptedData = try encrypt(data)

        try FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true)

        let fileURL = storageURL.appendingPathComponent("preferences.encrypted")
        try encryptedData.write(to: fileURL)

        // Apply file protection
        try (fileURL as NSURL).setResourceValue(
            fileProtection,
            forKey: .fileProtectionKey
        )
    }

    func load() throws -> UserPreferences {
        let fileURL = storageURL.appendingPathComponent("preferences.encrypted")
        let encryptedData = try Data(contentsOf: fileURL)
        let decryptedData = try decrypt(encryptedData)
        return try JSONDecoder().decode(UserPreferences.self, from: decryptedData)
    }

    // Export for user data portability (GDPR)
    func exportUserData() throws -> Data {
        let preferences = try load()
        return try JSONEncoder().encode(preferences)
    }

    // Complete data deletion
    func deleteAllData() throws {
        try FileManager.default.removeItem(at: storageURL)
    }
}
```

---

## 6. Cost Control Architecture

### 6.1 On-Device Resolution Targets

**Goal: Resolve 65%+ of queries without cloud API calls**

```
Query Distribution Target:
├── On-device immediate (cached/high confidence): 35%
├── On-device with background verify: 30%
│   └── (No user-facing API call, verification happens silently)
├── Cloud API (Gemini Flash): 25%
├── Cloud API (Gemini Pro): 8%
└── Manual entry (no API): 2%

Effective cloud API rate: ~33% of queries (25% + 8%)
```

### 6.2 Model Tiering Logic

```swift
class ModelTierRouter {

    enum ModelTier {
        case onDevice      // Free, <200ms
        case geminiFlash   // $0.002/query, 500-1000ms
        case geminiPro     // $0.007/query, 800-1500ms
    }

    struct TieringDecision {
        let tier: ModelTier
        let reason: String
        let estimatedCost: Float
    }

    func selectTier(
        onDeviceResult: CoreMLOutput,
        sceneAnalysis: SceneAnalysis,
        userTier: UserSubscriptionTier
    ) -> TieringDecision {

        // Rule 1: High confidence on-device = use local
        if onDeviceResult.isHighConfidence {
            return TieringDecision(
                tier: .onDevice,
                reason: "High confidence local classification",
                estimatedCost: 0
            )
        }

        // Rule 2: User's frequently logged food = use local
        if let match = findUserHistoryMatch(onDeviceResult.topPrediction) {
            return TieringDecision(
                tier: .onDevice,
                reason: "Matched user history",
                estimatedCost: 0
            )
        }

        // Rule 3: Simple scene + medium confidence = Gemini Flash
        if sceneAnalysis.complexity == .simple && onDeviceResult.topPrediction?.confidence ?? 0 >= 0.5 {
            return TieringDecision(
                tier: .geminiFlash,
                reason: "Simple scene, medium confidence",
                estimatedCost: 0.002
            )
        }

        // Rule 4: Complex scene = Gemini Pro
        if sceneAnalysis.complexity == .complex {
            return TieringDecision(
                tier: .geminiPro,
                reason: "Complex scene analysis needed",
                estimatedCost: 0.007
            )
        }

        // Rule 5: Multi-item plate = Gemini Pro
        if sceneAnalysis.itemCount > 3 {
            return TieringDecision(
                tier: .geminiPro,
                reason: "Multiple items detected",
                estimatedCost: 0.007
            )
        }

        // Rule 6: Non-Western cuisine detected = Gemini Pro
        if sceneAnalysis.cuisineType.isNonWestern {
            return TieringDecision(
                tier: .geminiPro,
                reason: "Specialized cuisine analysis",
                estimatedCost: 0.007
            )
        }

        // Default: Gemini Flash
        return TieringDecision(
            tier: .geminiFlash,
            reason: "Default cloud analysis",
            estimatedCost: 0.002
        )
    }
}
```

### 6.3 Caching Strategy

```swift
class FoodCache {

    // Three-tier caching strategy
    struct CacheConfig {
        static let memoryCacheSize = 100          // Hot cache: 100 items in memory
        static let diskCacheSize = 10_000         // Warm cache: 10K items on disk
        static let preloadedCacheSize = 50_000    // Cold cache: 50K items in app bundle

        static let memoryTTL: TimeInterval = 3600          // 1 hour
        static let diskTTL: TimeInterval = 86400 * 7       // 7 days
        static let preloadedTTL: TimeInterval = .infinity  // Until app update
    }

    private var memoryCache: [String: CachedFood] = [:]
    private let diskCache: DiskCache
    private let preloadedCache: PreloadedFoodDatabase

    func lookup(_ query: FoodQuery) async -> CacheLookupResult {
        // 1. Check memory cache (instant)
        if let cached = memoryCache[query.key], !cached.isExpired {
            return .hit(cached.food, source: .memory)
        }

        // 2. Check disk cache (~10ms)
        if let cached = await diskCache.get(query.key), !cached.isExpired {
            // Promote to memory cache
            memoryCache[query.key] = cached
            return .hit(cached.food, source: .disk)
        }

        // 3. Check preloaded database (~20ms)
        if let food = preloadedCache.lookup(query) {
            // Promote to disk cache for personalization
            await diskCache.set(query.key, CachedFood(food: food))
            memoryCache[query.key] = CachedFood(food: food)
            return .hit(food, source: .preloaded)
        }

        return .miss
    }

    func warmCache(for user: User) async {
        // Preload user's frequently eaten foods into memory
        let frequentFoods = await userHistory.getFrequentFoods(limit: 50)

        for food in frequentFoods {
            memoryCache[food.cacheKey] = CachedFood(food: food)
        }

        // Preload time-based predictions
        let predictions = await mealPredictor.getPredictedFoods(for: Date())

        for food in predictions {
            if memoryCache[food.cacheKey] == nil {
                memoryCache[food.cacheKey] = CachedFood(food: food)
            }
        }
    }
}

struct PreloadedFoodDatabase {
    // Bundled with app, contains ~50K most common foods
    // Updated with app releases

    private let database: [String: FoodItem]  // Loaded lazily from JSON
    private let searchIndex: FTS5Index        // Full-text search index

    func lookup(_ query: FoodQuery) -> FoodItem? {
        switch query {
        case .barcode(let code):
            return database[code]
        case .name(let name):
            return searchIndex.search(name).first
        case .id(let id):
            return database[id]
        }
    }
}
```

### 6.4 Batch Processing for Non-Urgent Queries

```swift
class BatchProcessor {

    // Batch non-urgent operations to reduce API calls

    struct BatchConfig {
        static let maxBatchSize = 10
        static let maxWaitTime: TimeInterval = 5.0  // Max 5 seconds wait
        static let batchableOperations: Set<OperationType> = [
            .backgroundVerification,
            .nutritionLookup,
            .cacheWarm
        ]
    }

    private var pendingOperations: [BatchableOperation] = []
    private var batchTimer: Timer?

    func queue(_ operation: BatchableOperation) {
        pendingOperations.append(operation)

        if pendingOperations.count >= BatchConfig.maxBatchSize {
            executeBatch()
        } else if batchTimer == nil {
            batchTimer = Timer.scheduledTimer(
                withTimeInterval: BatchConfig.maxWaitTime,
                repeats: false
            ) { [weak self] _ in
                self?.executeBatch()
            }
        }
    }

    private func executeBatch() {
        batchTimer?.invalidate()
        batchTimer = nil

        let operations = pendingOperations
        pendingOperations = []

        Task {
            // Group operations by type
            let grouped = Dictionary(grouping: operations) { $0.type }

            // Execute each group efficiently
            for (type, ops) in grouped {
                switch type {
                case .backgroundVerification:
                    await batchVerify(ops)
                case .nutritionLookup:
                    await batchLookupNutrition(ops)
                case .cacheWarm:
                    await batchWarmCache(ops)
                }
            }
        }
    }

    private func batchVerify(_ operations: [BatchableOperation]) async {
        // Combine multiple verification requests into single API call
        let foods = operations.compactMap { $0.food }

        // Create batch prompt
        let batchPrompt = """
        Verify these food identifications (respond with JSON array):
        \(foods.map { "- \($0.name): \($0.calories) cal" }.joined(separator: "\n"))
        """

        // Single API call for batch
        let results = try? await geminiClient.analyze(prompt: batchPrompt)

        // Distribute results back to operations
        // ...
    }
}
```

### 6.5 Cost Projections

```
Monthly Cost Estimates (at scale):

┌─────────────────────────────────────────────────────────────────────────────┐
│                        COST PROJECTION MODEL                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Assumptions:                                                                │
│  - 10 photo analyses per user per day                                       │
│  - 65% on-device resolution rate                                            │
│  - 25% Gemini Flash ($0.002/query)                                          │
│  - 10% Gemini Pro ($0.007/query)                                            │
│                                                                              │
│  ┌─────────┬──────────────┬───────────────┬──────────────────────────────┐ │
│  │  MAU    │ Cloud Queries│ Monthly Cost  │ Per User/Month               │ │
│  ├─────────┼──────────────┼───────────────┼──────────────────────────────┤ │
│  │  1,000  │     105,000  │    $315       │ $0.32                        │ │
│  │ 10,000  │   1,050,000  │  $3,150       │ $0.32                        │ │
│  │ 50,000  │   5,250,000  │ $15,750       │ $0.32                        │ │
│  │100,000  │  10,500,000  │ $31,500       │ $0.32                        │ │
│  └─────────┴──────────────┴───────────────┴──────────────────────────────┘ │
│                                                                              │
│  Cost Breakdown:                                                             │
│  - Gemini Flash: 75% of cloud queries × $0.002 = $0.0015/cloud query        │
│  - Gemini Pro:   25% of cloud queries × $0.007 = $0.00175/cloud query       │
│  - Blended cloud rate: ~$0.003/query                                        │
│  - Effective rate (with 65% on-device): ~$0.001/analysis                    │
│                                                                              │
│  Optimization Levers:                                                        │
│  1. Increase on-device resolution (65% → 75%) = -28% cost                   │
│  2. Negotiate volume pricing at scale = -20-40% cost                        │
│  3. Improve Flash/Pro routing (reduce Pro usage) = -15% cost                │
│  4. Cache hit improvements = -10% cost                                      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 6.6 Free vs Premium Tier Strategy

```swift
enum UserSubscriptionTier {
    case free
    case premium

    var dailyCloudQuota: Int {
        switch self {
        case .free: return 5      // 5 cloud analyses/day
        case .premium: return 100  // Effectively unlimited
        }
    }

    var modelAccess: Set<ModelTier> {
        switch self {
        case .free: return [.onDevice, .geminiFlash]
        case .premium: return [.onDevice, .geminiFlash, .geminiPro]
        }
    }

    var cacheWarmingEnabled: Bool {
        switch self {
        case .free: return false
        case .premium: return true
        }
    }
}

class QuotaManager {

    func checkQuota(user: User) -> QuotaStatus {
        let today = Calendar.current.startOfDay(for: Date())
        let usedToday = getUsageCount(user: user, since: today)
        let quota = user.subscriptionTier.dailyCloudQuota

        if usedToday >= quota {
            return .exceeded(nextReset: tomorrow())
        } else if usedToday >= quota - 2 {
            return .nearLimit(remaining: quota - usedToday)
        } else {
            return .available(remaining: quota - usedToday)
        }
    }

    func handleQuotaExceeded(user: User) -> QuotaExceededAction {
        if user.subscriptionTier == .free {
            return .offerUpgrade(
                message: "You've used all 5 photo analyses today. Upgrade for unlimited!",
                fallback: .onDeviceOnly
            )
        } else {
            // Premium users shouldn't hit quota, log for investigation
            logUnexpectedQuotaHit(user: user)
            return .allowWithWarning
        }
    }
}
```

---

## 7. Integration Points with Other Agents

### 7.1 iOS Agent Integration (Agent 04)

**Camera Integration:**
```swift
// iOS Agent provides camera capture
// AI/ML Agent provides processing
protocol AIPhotoAnalyzer {
    func analyze(_ image: UIImage) async throws -> FoodRecognitionResult
    func getQuickAddSuggestions(context: MealContext) async -> [QuickAddSuggestion]
}

// Integration in iOS camera flow
class CameraViewController: UIViewController {
    let analyzer: AIPhotoAnalyzer

    func capturePhoto() async {
        guard let image = await captureImage() else { return }

        // Show loading state
        showAnalyzing()

        // AI analysis
        let result = try await analyzer.analyze(image)

        // Handle result based on confidence
        switch result.userAction {
        case .none:
            autoLog(result.food)
        case .tapToEdit:
            showEditableResult(result)
        case .selectFromOptions:
            showOptions(result.alternatives ?? [result.food])
        case .confirmUnusual:
            showConfirmation(result, warning: result.validationResult.warnings.first)
        case .manualEntry:
            showManualEntry(suggestions: result.alternatives)
        }
    }
}
```

**HealthKit Integration:**
```swift
// When user logs food, AI provides nutrition data
// iOS Agent writes to HealthKit
struct NutritionHealthKitBridge {
    func writeNutrition(_ food: NutritionData, to healthKit: HKHealthStore) async throws {
        let types: [HKQuantityTypeIdentifier: Double] = [
            .dietaryEnergyConsumed: Double(food.calories),
            .dietaryProtein: Double(food.protein),
            .dietaryCarbohydrates: Double(food.carbohydrates),
            .dietaryFatTotal: Double(food.fat)
        ]

        for (type, value) in types {
            let quantityType = HKQuantityType(type)
            let quantity = HKQuantity(unit: type.defaultUnit, doubleValue: value)
            let sample = HKQuantitySample(
                type: quantityType,
                quantity: quantity,
                start: Date(),
                end: Date()
            )
            try await healthKit.save(sample)
        }
    }
}
```

### 7.2 Backend Agent Integration (Agent 03)

**API Endpoints Required:**

```yaml
# Food Recognition API
POST /api/v1/food/analyze
  Request:
    - image: base64 encoded JPEG
    - hints: { mealType, recentFoods }
  Response:
    - foods: [FoodItem]
    - confidence: Float
    - source: String

# NLP Parsing API
POST /api/v1/food/parse
  Request:
    - text: String
    - context: { mealType, locale }
  Response:
    - parsedItems: [ParsedFoodItem]
    - clarificationNeeded: Bool

# Nutrition Lookup API (proxied through backend for key security)
GET /api/v1/nutrition/lookup
  Query:
    - query: String (food name or barcode)
    - source: String (nutritionix, usda, openfoodfacts)
  Response:
    - nutrition: NutritionData
    - alternatives: [NutritionData]
```

**Database Requirements:**

```sql
-- User food history (for personalization, stored locally + synced)
CREATE TABLE user_food_log (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    food_id VARCHAR(255),
    food_name VARCHAR(255),
    calories INTEGER,
    protein REAL,
    carbs REAL,
    fat REAL,
    portion_amount REAL,
    portion_unit VARCHAR(50),
    logged_at TIMESTAMP WITH TIME ZONE,
    source VARCHAR(50),  -- 'photo', 'search', 'barcode', 'voice'
    ai_confidence REAL,
    was_corrected BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Food cache (shared across users)
CREATE TABLE food_cache (
    food_id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255),
    calories INTEGER,
    protein REAL,
    carbs REAL,
    fat REAL,
    serving_size JSONB,
    source VARCHAR(50),
    verified BOOLEAN,
    last_updated TIMESTAMP WITH TIME ZONE,
    lookup_count INTEGER DEFAULT 0
);
```

### 7.3 UX Agent Integration (Agent 02)

**UI States for AI Results:**

| AI State | UI Component | User Action |
|----------|--------------|-------------|
| Analyzing | Shimmer animation + "Analyzing..." | Wait |
| High confidence | Food card with checkmark | Tap to edit (optional) |
| Medium confidence | Food card with "Is this correct?" | Confirm or edit |
| Low confidence | Multiple cards carousel | Select one |
| Sanity warning | Warning banner + food card | Must confirm |
| Failed | "We couldn't identify this" | Manual search |

**Animation Timings:**
- Photo capture → Analysis start: <100ms
- Analysis shimmer: 800-2000ms (matches actual processing)
- Result fade-in: 300ms
- Confidence indicator: Animate to final value over 500ms

---

## 8. Testing Strategy

### 8.1 AI Accuracy Testing

```swift
class AIAccuracyTestSuite {

    struct TestCase {
        let imageURL: URL
        let expectedFoods: [String]
        let expectedCalorieRange: ClosedRange<Int>
        let difficulty: Difficulty
    }

    enum Difficulty {
        case simple      // Single item, clear photo
        case medium      // Plate with 2-3 items
        case complex     // Mixed dishes, cultural foods
        case adversarial // Edge cases, unusual angles
    }

    // Test datasets
    let testCases: [TestCase] = [
        // Simple foods (target: 95%+ accuracy)
        TestCase(imageURL: "apple_clear.jpg", expectedFoods: ["apple"], expectedCalorieRange: 70...110, difficulty: .simple),
        TestCase(imageURL: "banana_peeled.jpg", expectedFoods: ["banana"], expectedCalorieRange: 80...120, difficulty: .simple),

        // Plates (target: 85%+ accuracy)
        TestCase(imageURL: "chicken_rice_broccoli.jpg", expectedFoods: ["chicken", "rice", "broccoli"], expectedCalorieRange: 400...600, difficulty: .medium),

        // Complex/cultural (target: 80%+ accuracy)
        TestCase(imageURL: "chicken_tikka_masala.jpg", expectedFoods: ["chicken tikka masala"], expectedCalorieRange: 350...550, difficulty: .complex),

        // Adversarial (target: 70%+ accuracy)
        TestCase(imageURL: "blurry_sandwich.jpg", expectedFoods: ["sandwich"], expectedCalorieRange: 300...600, difficulty: .adversarial),
    ]

    func runAccuracyTest() async -> TestReport {
        var results: [TestResult] = []

        for testCase in testCases {
            let image = UIImage(contentsOfFile: testCase.imageURL.path)!
            let result = try await analyzer.analyze(image)

            let accuracy = calculateAccuracy(
                predicted: result.food,
                expected: testCase.expectedFoods,
                expectedCalories: testCase.expectedCalorieRange
            )

            results.append(TestResult(testCase: testCase, accuracy: accuracy, result: result))
        }

        return TestReport(results: results)
    }
}
```

### 8.2 Sanity Check Testing

```swift
class SanityCheckTestSuite {

    // Test that sanity checks catch known bad cases
    let adversarialCases: [(FoodItem, ShouldFlag)] = [
        // Should flag: Impossible calories
        (FoodItem(name: "popcorn", calories: 8000, category: .snack), true),

        // Should flag: Macros don't add up
        (FoodItem(name: "chicken", calories: 200, protein: 100, carbs: 0, fat: 0), true),

        // Should NOT flag: Normal food
        (FoodItem(name: "apple", calories: 95, category: .fruit), false),

        // Should flag: Negative calories
        (FoodItem(name: "celery", calories: -50, category: .vegetable), true),
    ]

    func testSanityChecks() {
        for (food, shouldFlag) in adversarialCases {
            let result = SanityChecker().validate(food)

            if shouldFlag {
                XCTAssertFalse(result.passed, "Should have flagged: \(food.name)")
            } else {
                XCTAssertTrue(result.passed, "Should not have flagged: \(food.name)")
            }
        }
    }
}
```

---

## 9. Monitoring & Observability

### 9.1 Key Metrics

```swift
struct AIMetrics {
    // Accuracy metrics
    var correctPredictions: Int
    var totalPredictions: Int
    var userCorrections: Int

    var accuracy: Float {
        Float(correctPredictions - userCorrections) / Float(totalPredictions)
    }

    // Latency metrics
    var onDeviceLatencyP50: TimeInterval
    var onDeviceLatencyP95: TimeInterval
    var cloudLatencyP50: TimeInterval
    var cloudLatencyP95: TimeInterval

    // Cost metrics
    var onDeviceResolutionRate: Float  // Target: 65%
    var flashUsageRate: Float
    var proUsageRate: Float
    var dailyAPICost: Float

    // Sanity check metrics
    var sanityCheckTriggerRate: Float  // Target: <5%
    var falsePositiveRate: Float       // Target: <1%
    var missedBadEstimates: Int        // Target: 0
}
```

### 9.2 Alerting Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| Accuracy (7-day) | <85% | <80% |
| Cloud latency P95 | >2.5s | >4s |
| On-device resolution | <60% | <50% |
| Sanity false positives | >3% | >5% |
| API error rate | >1% | >5% |
| Daily cost spike | +50% | +100% |

---

## 10. Security Considerations

### 10.1 API Key Management

```swift
// NEVER hardcode API keys
// Store in iOS Keychain, fetched securely at runtime

class SecureAPIKeyManager {
    private static let geminiKeyIdentifier = "com.dietapp.gemini.key"

    static func getGeminiKey() throws -> String {
        guard let key = KeychainWrapper.standard.string(forKey: geminiKeyIdentifier) else {
            throw APIKeyError.notFound
        }
        return key
    }

    // Key is provisioned during authenticated session from backend
    static func provisionKey(_ key: String) throws {
        let success = KeychainWrapper.standard.set(
            key,
            forKey: geminiKeyIdentifier,
            withAccessibility: .afterFirstUnlockThisDeviceOnly
        )
        if !success {
            throw APIKeyError.storageFailed
        }
    }
}
```

### 10.2 Image Privacy

```swift
class ImagePrivacyManager {

    // Photos are processed and immediately discarded
    // NEVER stored on device or server unless user explicitly saves

    func processAndDiscard(_ image: UIImage) async -> FoodRecognitionResult {
        // Process
        let result = try await analyzer.analyze(image)

        // Image reference is released after this scope
        // No persistence, no upload logging

        return result
    }

    // If user wants to save photo (for food journal)
    func saveWithConsent(_ image: UIImage, result: FoodRecognitionResult) async {
        // Requires explicit user action
        // Stored locally only (never uploaded)
        // User can delete at any time

        let photoData = image.jpegData(compressionQuality: 0.8)
        try await localPhotoStorage.save(
            photoData,
            for: result.food.id,
            encryptionEnabled: true
        )
    }
}
```

---

## Appendix A: Response to Other Agents' Questions

### Backend Agent (Agent 03) Questions:

1. **Photo recognition latency requirements?**
   - Target: <2 seconds end-to-end for cloud path
   - On-device only: <500ms
   - User perception: Show analyzing state after 300ms

2. **Food identification confidence thresholds?**
   - ≥90%: Auto-log enabled
   - 70-89%: Show for confirmation
   - 50-69%: Show alternatives
   - <50%: Manual entry suggested

3. **Model deployment preference?**
   - Hybrid: Core ML on-device for speed + cloud for accuracy
   - See Section 1 for routing logic

4. **Training data needs?**
   - Not building custom models initially
   - Using pre-trained MobileNetV3 + Gemini APIs
   - Future: May collect anonymized corrections for fine-tuning (with consent)

5. **Meal plan generation approach?**
   - On-device personalization engine for suggestions
   - Cloud AI for complex meal planning (premium feature)
   - See Section 5 for personalization details

---

*Document prepared by Agent 05: AI/ML*
*Phase 3: Architecture*
*Ready for Manager review and cross-agent integration*
