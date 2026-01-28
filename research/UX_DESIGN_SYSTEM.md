# UX Design System & Wireframes
## Diet App - Agent 02 Comprehensive Design Document

---

## Design Philosophy

**Core Principle**: Every design decision must pass the test: "Does this create guilt or friction?" If yes, redesign it.

**Positioning**: "The diet app that adapts to you—without the guilt."

---

## 1. User Personas

### Persona 1: Marcus Chen - The Data-Driven Optimizer
- **Age**: 34, Software Engineer
- **Goal**: Optimize body composition for competitive powerlifting
- **Current apps**: MacroFactor (loves adaptive TDEE), Cronometer (loves micronutrient depth)
- **Pain points**: Logging takes too long, wants AI photo + precision data combined
- **Needs**: Accuracy, detailed micronutrients, HealthKit sync, no gamification

### Persona 2: Sarah Mitchell - The Busy Professional
- **Age**: 29, Marketing Manager
- **Goal**: Lose 15 lbs sustainably while managing busy schedule
- **Current apps**: Tried MFP (too tedious), Noom (too expensive, coaching felt generic)
- **Pain points**: No time for manual entry, forgot to log, guilt when missing days
- **Needs**: Photo logging, quick-add, gentle reminders (not nagging), forgiveness for lapses

### Persona 3: Jordan Rivera - The Mindful Eater
- **Age**: 26, recovering from restrictive eating patterns
- **Goal**: Build healthy relationship with food while maintaining some structure
- **Current apps**: Quit all apps due to triggering content
- **Pain points**: Red/green colors trigger anxiety, calorie numbers cause obsession, streaks cause panic
- **Needs**: Recovery-friendly mode, no calorie display, focus on food variety, no punishment

### Persona 4: David Okonkwo - The Health Journey Beginner
- **Age**: 45, recently diagnosed with pre-diabetes
- **Goal**: Learn about nutrition, reduce A1C through diet changes
- **Current apps**: None (overwhelmed by options)
- **Pain points**: Doesn't know macros from micros, intimidated by complex apps
- **Needs**: Guided onboarding, education without condescension, simple progress indicators

---

## 2. Design System Foundation

### Color Palette (Guilt-Free)

| Color | Hex | Usage |
|-------|-----|-------|
| **Deep Teal** | #1A5F5F | Primary actions, headers |
| **Soft Sage** | #8FBC8B | Positive states (NOT "good food") |
| **Warm Sand** | #F5E6D3 | Backgrounds, cards |
| **Terracotta** | #CD7F5C | Accents, warmth |
| **Soft Charcoal** | #3D3D3D | Primary text |
| **Warm Gray** | #7A7A7A | Secondary text |
| **Off-White** | #FAFAF8 | Backgrounds |

**PROHIBITED**: Red/green for food judgment, aggressive warning colors

### Typography

- **Headlines**: SF Pro Display (iOS), Product Sans (Android), Bold
- **Body**: SF Pro Text (iOS), Roboto (Android), Regular
- **Numbers**: SF Pro Rounded, Medium (friendly, not clinical)

### Progress Visualization (Neutral)

Instead of red/green fill bars:
- **Filled portion**: Deep Teal (consistent regardless of amount)
- **Unfilled portion**: Light gray
- **Labels**: Always show actual numbers, not just visual

### Spacing Grid
- Base unit: 8pt
- Touch targets: Minimum 44x44pt
- Card padding: 16pt
- Section spacing: 24pt

---

## 3. Core Interaction Patterns

### A. Meal Logging (<30 seconds target)

**Photo Flow:**
1. Tap FAB → Camera opens
2. Take photo → AI processes (1-2s)
3. Review identified items → One-tap adjust if needed
4. "Log This Meal" → Done

**Quick-Add Flow:**
1. Tap FAB → Recent/Favorites appear
2. One-tap to log → Done

**Voice Flow:**
1. Tap mic → "I had a chicken salad"
2. AI parses → Review → Log

### B. Onboarding (<3 minutes)

Screen flow:
1. Welcome (personalization promise)
2. Tracking Mode (Full/Light/Mindful)
3. Goals (supportive language only)
4. Activity Level
5. Dietary Preferences
6. Notifications (user control emphasized)
7. Setup Complete → First meal logging

### C. Missed Day Recovery (NO GUILT)

When user returns after absence:
- "Welcome back, [Name]!" (warm, not accusatory)
- NO mention of missed days or broken streaks
- "Pick up where you left off" (easy re-engagement)
- Optional: "What's for breakfast?" quick-add prompt

### D. Progress Visualization

- **Weekly trends** over daily perfection
- **Patterns** highlighted ("Tuesdays tend to be lower fiber")
- **Positive framing** ("Nice consistency!" not "You failed 2 days")
- **Suggestions** based on patterns (not criticisms)

---

## 4. Key Wireframes

### Home Dashboard

```
┌─────────────────────────────────────────┐
│  Today, Mon Jan 27 ▼          [Avatar] │
├─────────────────────────────────────────┤
│  Good afternoon, [Name]                 │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ NUTRITION                        │   │
│  │ Calories  ████████░░  1,850      │   │
│  │                        / 2,400   │   │
│  │ Protein   ██████████░░  98g      │   │
│  │ Carbs     ███████░░░░░  195g     │   │
│  │ Fat       ███████░░░░   68g      │   │
│  └─────────────────────────────────┘   │
│                                         │
│  TODAY'S MEALS                          │
│  ┌─────────────────────────────────┐   │
│  │ ☀ Breakfast              420 cal│   │
│  │ Oatmeal with berries, coffee    │   │
│  └─────────────────────────────────┘   │
│  ┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐   │
│    + Add dinner                         │
│  └─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘   │
│                                         │
│                              ┌───┐     │
│                              │ + │ FAB │
│                              └───┘     │
├─────────────────────────────────────────┤
│ [Home]    [Insights]   [More]          │
└─────────────────────────────────────────┘
```

### Logging Entry Point

```
┌─────────────────────────────────────────┐
│  [×]           Add Food                 │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │ [🔍] Search foods...            │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │[Camera] │ │ [Mic]   │ │[Barcode]│   │
│  │  Photo  │ │  Voice  │ │  Scan   │   │
│  └─────────┘ └─────────┘ └─────────┘   │
│                                         │
│  RECENT                                 │
│  ┌─────────────────────────────────┐   │
│  │ Greek Yogurt, 2% plain    [+]   │   │
│  │ 150 cal • 15g protein           │   │
│  └─────────────────────────────────┘   │
│                                         │
│  FAVORITES                              │
│  ┌─────────────────────────────────┐   │
│  │ Morning Oatmeal Bowl      [+]   │   │
│  │ 380 cal • 12g protein           │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### Photo Results Review

```
┌─────────────────────────────────────────┐
│  [←]         Review Meal               │
├─────────────────────────────────────────┤
│    ┌─────────────────────────────┐     │
│    │     [Captured Photo]        │     │
│    └─────────────────────────────┘     │
│                                         │
│  We identified:                         │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ Grilled Chicken Breast          │   │
│  │ ~6 oz (170g)              [Edit]│   │
│  │ 280 cal • 52g protein           │   │
│  │ ████████████████ High confidence│   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ Mixed Green Salad               │   │
│  │ ~2 cups                   [Edit]│   │
│  │ 45 cal • 3g protein             │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [+ Add missing item]                  │
│                                         │
│  Total: 475 cal • 56g protein          │
│                                         │
│    ┌─────────────────────────────┐     │
│    │        Log This Meal        │     │
│    └─────────────────────────────┘     │
└─────────────────────────────────────────┘
```

### Weekly Insights

```
┌─────────────────────────────────────────┐
│  [←]           Insights                │
├─────────────────────────────────────────┤
│  [This Week ▼]                         │
│                                         │
│  YOUR WEEK AT A GLANCE                 │
│  ┌─────────────────────────────────┐   │
│  │  Days Logged: 6 of 7            │   │
│  │  ████████████████████████░░░░   │   │
│  │  Nice consistency!              │   │
│  └─────────────────────────────────┘   │
│                                         │
│  PATTERNS I NOTICED                    │
│  ┌─────────────────────────────────┐   │
│  │ ↗ Protein intake 12% higher     │   │
│  │   than last week                │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 📅 Tuesdays tend to be lower    │   │
│  │   fiber days                    │   │
│  └─────────────────────────────────┘   │
│                                         │
│  SUGGESTIONS                           │
│  ┌─────────────────────────────────┐   │
│  │ High-fiber ideas for Tuesdays:  │   │
│  │ • Lentil soup                   │   │
│  │ • Chickpea salad                │   │
│  │ [See recipes →]                 │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

---

## 5. Accessibility Requirements

### WCAG 2.1 AA Compliance

- **Color contrast**: 4.5:1 minimum for text
- **Touch targets**: 44x44pt minimum
- **Screen reader**: Full VoiceOver/TalkBack support
- **Dynamic Type**: Support up to xxxLarge
- **Reduced Motion**: Respect system setting

### Cognitive Accessibility

- Reading level: 8th grade or below
- Consistent navigation patterns
- Clear error messages with solutions
- Progressive disclosure for complex features

### ED-Sensitive Mode (Mindful Tracking)

When enabled:
- Hide calorie numbers entirely
- No weight tracking
- Focus on food variety and satisfaction
- No comparative language
- Affirmations instead of metrics

---

## 6. Design Phase Gate Checklist

- [x] User personas validated against research
- [x] Core flows wireframed and reviewed
- [x] Design system established (colors, typography, spacing)
- [x] Wireframes for onboarding + daily logging
- [x] Accessibility considerations documented
- [ ] **Sebastian review and approval** ← PENDING

---

*Document prepared by Agent 02: UX*
*Ready for Manager synthesis and CEO review*
