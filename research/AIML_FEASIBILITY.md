# AI/ML Technical Feasibility Assessment
## Diet App - Agent 05 Analysis

---

## Executive Summary

This assessment evaluates AI/ML options for food recognition, natural language logging, and personalization. The overall verdict: **FEASIBLE with hybrid architecture** combining on-device speed with cloud accuracy.

**Key Insight**: Current industry accuracy is 60-80%, with Cal AI reporting catastrophic errors (8,000 cal for popcorn). Our opportunity: **AI convenience WITHOUT accuracy sacrifice** through multi-model ensemble and aggressive sanity checking.

---

## 1. Food Photo Recognition - Model Comparison

### Cloud APIs

| Provider | Accuracy | Latency | Cost/Call | Best For |
|----------|----------|---------|-----------|----------|
| **Gemini 1.5 Flash** | 85-90% | 500-1000ms | $0.002 | Primary (cost/accuracy balance) |
| Gemini 1.5 Pro | 88-93% | 800-1500ms | $0.007 | Complex cases |
| GPT-4V | 87-92% | 2000-4000ms | $0.03 | Portion reasoning |
| Claude Vision | 85-90% | 1000-2000ms | $0.025 | Complex scenes |
| Foodvisor | 82-88% | 300-600ms | $0.025 | Portion estimation |

### On-Device Options

| Option | Accuracy | Latency | Privacy | Complexity |
|--------|----------|---------|---------|------------|
| Apple Vision | 60-70% | <100ms | Excellent | Low |
| Core ML Custom | 80-90% | <200ms | Excellent | Very High |
| TensorFlow Lite | 75-85% | 100-300ms | Excellent | High |

### Primary Recommendation: **Gemini 1.5 Flash**
- Best cost/accuracy balance
- Multimodal understanding for complex scenes
- Strong multilingual support

---

## 2. Natural Language Parsing

### Test Phrase Handling

| Input | Challenge | Solution |
|-------|-----------|----------|
| "turkey sandwich with mayo and lettuce" | Multi-ingredient | LLM parsing |
| "Large coffee with oat milk and two pumps vanilla" | Size modifier + quantities | Nutritionix NLP |
| "About half a cup of rice with some chicken curry" | Approximate + composite | LLM reasoning |
| "A handful of almonds" | Vague quantity | Portion estimation |
| "Leftover pizza, maybe 2 slices" | Uncertainty expressed | Confidence-aware UI |

### Recommended: **Hybrid Approach**

```
User Input → Nutritionix NLP (fast, structured)
                    ↓
              Confidence Check
                    ↓
    High Confidence → Return result
    Low Confidence  → LLM enhancement → Return refined
```

**Accuracy Estimate**: 85-92% for common foods

---

## 3. Barcode + AI Integration

### Priority Order
1. **Barcode Match** (99%+ when matched)
2. **User's Personal History** ("You had this yesterday")
3. **Restaurant Database** (Nutritionix)
4. **AI Recognition** (fallback)

### Confidence Thresholds

| Confidence | Action |
|------------|--------|
| >90% | Auto-log with "tap to edit" |
| 70-90% | Show top 3 options |
| 50-70% | Show best guess + "doesn't look right" |
| <50% | Manual identification flow |

---

## 4. Portion Size Estimation - Critical Challenge

### Strategy Matrix

| Method | Accuracy Boost | User Friction | Recommendation |
|--------|----------------|---------------|----------------|
| **LiDAR Depth** | +25-35% | None | Enhancement for Pro phones |
| **User Confirmation UI** | +20-30% | Medium | Primary method |
| **Plate Size Detection** | +10-15% | None | Passive enhancement |
| **Reference Objects** | +15-20% | Low | Optional prompt |
| **Learning from Corrections** | +5-10% over time | Low | Always-on |

### Recommended: **Multi-pronged approach**
- Passive plate/context detection
- LiDAR when available (iPhone Pro)
- Quick portion selector UI after AI guess
- Learn from user corrections over time

---

## 5. Personalization Engine

### Features

**Predictive Quick-Add:**
```
Monday 8:00 AM → "Good morning! Quick add your usual?"
[Coffee ☕] [Oatmeal 🥣] [Toast 🍞] [Something else]
```

**Goal-Aware Suggestions:**
- "You have room for a light dinner"
- "Great workout! Time for protein"
- "You're 100g short on protein"

**Learned Corrections:**
- User adjusts pasta portions up 1.5x → auto-apply
- User prefers low-sodium → show first
- User forgets dressing → prompt "Did you add dressing?"

---

## 6. On-Device vs. Cloud - Hybrid Architecture

### Trade-offs

| Factor | On-Device | Cloud | Hybrid |
|--------|-----------|-------|--------|
| Privacy | Excellent | Requires transmission | Best of both |
| Latency | 50-200ms | 500-3000ms | 200-1000ms |
| Accuracy | 70-85% | 85-95% | 85-92% |
| Offline | Full | None | Partial |
| Cost | Free | $0.005-0.05/query | Reduced |

### Recommended Architecture

```
Input → On-Device Quick Check (Core ML)
            ↓
    Confidence > 85%? → Return (no API call)
            ↓
    Confidence < 85% → Cloud API → Return enhanced
```

**Benefits:**
- 60-70% resolved on-device (cost savings)
- Privacy for common/personal foods
- Cloud accuracy for difficult cases
- Works offline with degraded accuracy

---

## 7. Accuracy Improvement Strategy

### Target: 92%+ (simple foods), 85%+ (complex dishes)

### Strategies

1. **User Correction Feedback Loop**
   - "Was this correct?" prompt after eating
   - Corrections weighted 10x in training

2. **Multi-Model Ensemble**
   - Gemini: diverse cuisines
   - Foodvisor: Western foods, portions
   - Claude: complex/mixed dishes

3. **Sanity Checks (Prevent Cal AI Errors)**
   ```
   MAX_CALORIES_PER_ITEM = 3000
   MIN_CALORIES_PER_ITEM = 1
   Flag if outside 3x expected range
   ```

4. **Specialized Models for Problem Cuisines**
   - Indian, Chinese, Mexican, Japanese, Middle Eastern

---

## 8. Cost Projections

### Assumptions
- 10 photo analyses/user/day
- 65% resolved on-device, 35% cloud
- Blended API cost: ~$0.004/query

### Monthly Costs

| Users | Cloud Queries/Day | Monthly Cost |
|-------|-------------------|--------------|
| 1,000 | 3,500 | **$420** |
| 10,000 | 35,000 | **$4,200** |
| 100,000 | 350,000 | **$42,000** |

*Volume discounts can reduce by 20-50%*

### Cost Optimization
1. Target 70% on-device resolution
2. Use cheapest model meeting confidence threshold
3. Negotiate enterprise pricing at scale
4. Free tier = more on-device, premium = more cloud

---

## 9. Privacy-Preserving Design

### Privacy Tiers

**TIER 1: ON-DEVICE (Never Leaves Phone)**
- Personal food history
- Eating patterns and preferences
- Health goals and metrics
- Personalization model

**TIER 2: PROCESS & DISCARD**
- Photos analyzed → deleted immediately
- No photo storage
- Text queries not logged

**TIER 3: ANONYMIZED AGGREGATE (Opt-in)**
- Food type frequencies (no user linkage)
- Common correction patterns

---

## 10. Risk Register

### Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| AI accuracy below target | Medium | High | Multi-model ensemble |
| API provider changes | Low | High | Abstract API layer |
| On-device model too large | Medium | Medium | Quantization, progressive download |

### Accuracy Risks

| Risk | Mitigation |
|------|------------|
| Wildly inaccurate estimates | Sanity checks, reasonable bounds |
| Cultural food bias | Diverse training, specialized models |
| Portion estimation failures | User confirmation, LiDAR enhancement |

---

## 11. Final Architecture Recommendation

```
┌─────────────────────────────────────────────────┐
│                ON-DEVICE LAYER                   │
│  Core ML Quick Classify + Barcode Cache         │
│  + User History Match                            │
└────────────────────┬────────────────────────────┘
                     ↓
        High Confidence → Return (65% of queries)
        Low Confidence  → Cloud
                     ↓
┌─────────────────────────────────────────────────┐
│                 CLOUD LAYER                      │
│  Primary: Gemini 1.5 Flash (fast, cheap)        │
│  Secondary: Gemini Pro (complex cases)          │
│  Portion: Foodvisor API                          │
└────────────────────┬────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────┐
│            NUTRITIONAL DATABASE                  │
│  USDA + Open Food Facts + Nutritionix           │
└─────────────────────────────────────────────────┘
```

### Key Decisions for Review

| Decision | Recommendation | Trade-off |
|----------|----------------|-----------|
| Primary Cloud API | **Gemini 1.5 Flash** | Cost/accuracy balance |
| On-device model | **Core ML** | iOS-native |
| NLP Parser | **Hybrid** (Nutritionix + LLM) | Speed + accuracy |
| Photo Storage | **Process-and-delete** | Privacy first |
| Portion | **UI confirm + LiDAR** | Works all devices |

---

## Accuracy Targets

| Food Category | Industry | Our Target | How |
|--------------|----------|------------|-----|
| Simple foods | 85-95% | **95%+** | On-device cache |
| Packaged (barcode) | 99% | **99%** | Database |
| Restaurant meals | 70-80% | **85%+** | Menu integration |
| Mixed dishes | 60-75% | **80%+** | Ensemble |
| Non-Western cuisines | 50-70% | **80%+** | Specialized training |
| Portions | 60-70% | **80%+** | LiDAR + confirmation |

---

*Report prepared by Agent 05: AI/ML*
