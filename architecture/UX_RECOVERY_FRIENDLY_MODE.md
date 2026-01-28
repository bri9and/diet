# Recovery-Friendly Mode Specification
## "Mindful Tracking" - Detailed Design

---

## Overview

Mindful Tracking mode is designed for users who need structure around eating without triggering disordered eating patterns. This includes users in eating disorder recovery, those with a history of orthorexia, and anyone who finds numerical tracking anxiety-inducing.

**Critical Context**: Research shows 75% of ED patients in one study had used MyFitnessPal, and 73% said it contributed to their disorder. Our Mindful Mode must break this pattern.

---

## Feature Comparison Matrix

| Feature | Standard Mode | Simple Mode | Mindful Mode |
|---------|--------------|-------------|--------------|
| **Calorie display** | Shown everywhere | Shown everywhere | **Hidden completely** |
| **Macro grams** | P/C/F in grams | Protein only | **Hidden completely** |
| **Macro percentages** | Available | Hidden | **Hidden completely** |
| **Micronutrients** | Full panel | Hidden | **Hidden completely** |
| **Progress rings** | Calories + macros | Calories only | **Hidden completely** |
| **Daily targets** | Numeric goals | Simplified | **No numeric goals** |
| **Food logging** | Full nutrition shown | Cal + protein | **Food name only** |
| **Search results** | Cal + macros shown | Cal + protein | **No numbers** |
| **Meal totals** | Full breakdown | Simplified | **Item count only** |
| **Weekly insights** | Numeric trends | Simplified | **Pattern-based only** |
| **Weight tracking** | Optional | Optional | **Removed entirely** |
| **Body metrics** | Shown in profile | Shown | **Hidden from view** |
| **Streak display** | Never shown (all modes) | Never shown | **Never shown** |
| **Color coding** | Neutral (no red/green) | Neutral | **Neutral** |

---

## Detailed Behavioral Differences

### 1. Dashboard (Home Screen)

#### Standard Mode Dashboard
```
Good afternoon, Sarah

NUTRITION
Calories  ████████░░  1,850 / 2,400
Protein   ██████████░░  98g / 120g
Carbs     ███████░░░░░  195g / 280g
Fat       ███████░░░░   68g / 80g

TODAY'S MEALS
Breakfast              420 cal
Oatmeal with berries, coffee
```

#### Mindful Mode Dashboard
```
Good afternoon, Sarah

TODAY'S NOURISHMENT

You've enjoyed 3 meals and 1 snack today.

BREAKFAST
Oatmeal with berries, coffee

LUNCH
Grilled chicken salad, apple

DINNER
+ What sounds good for dinner?

HOW ARE YOU FEELING?
[Energized] [Satisfied] [Hungry] [Tired]
```

**Key Differences:**
- No nutrition summary card
- Meals described by foods, not numbers
- Focus on meal count and variety
- Optional feeling check-in replaces metrics
- Gentle prompt for next meal (not "add food")

---

### 2. Food Logging Experience

#### Standard Mode - Add Food
```
Greek Yogurt, 2% plain
Fage • 1 cup (227g)
150 cal • 15g protein • 8g carbs • 5g fat
[+]
```

#### Mindful Mode - Add Food
```
Greek Yogurt
Fage • 1 cup
Dairy • Protein-rich
[Add]
```

**Key Differences:**
- No calorie or macro numbers
- Food group tags instead (Dairy, Protein-rich, Whole grain, etc.)
- Serving size shown but no nutritional math
- "Add" instead of "+" (more intentional language)

---

### 3. Photo Review Screen

#### Standard Mode
```
We identified:

Grilled Chicken Breast
~6 oz (170g)
280 cal • 52g protein
████████████████ High confidence

Mixed Green Salad
~2 cups
45 cal • 3g protein

Total: 475 cal • 56g protein

[Log This Meal]
```

#### Mindful Mode
```
We identified:

Grilled Chicken
A good protein source

Mixed Greens
Lots of vitamins and fiber

Great variety in this meal!

[Add to Today]
```

**Key Differences:**
- No calories or macros shown
- Positive food group descriptors
- Affirming message about meal composition
- "Add to Today" instead of "Log This Meal"

---

### 4. Insights Screen

#### Standard Mode
```
YOUR WEEK AT A GLANCE
Days Logged: 6 of 7
Avg Calories: 2,150
Avg Protein: 105g

PATTERNS I NOTICED
↗ Protein intake 12% higher than last week
```

#### Mindful Mode
```
YOUR WEEK

You showed up 6 out of 7 days. Nice consistency!

PATTERNS I NOTICED

You've been including more variety this week.
I see lots of different vegetables showing up.

Your protein sources have been diverse:
chicken, fish, eggs, and beans.

REFLECTION
How has eating felt this week?
[Stressful] [Neutral] [Enjoyable]
```

**Key Differences:**
- No numeric metrics at all
- Qualitative observations about variety
- Focus on food groups and diversity
- Optional reflection prompt
- Positive, non-judgmental framing

---

### 5. Meal Detail View

#### Standard Mode
```
LUNCH - Today

Greek Salad         320 cal
Grilled Chicken     280 cal
Olive Oil Dressing   90 cal

Total: 690 cal
Protein: 48g | Carbs: 15g | Fat: 42g
```

#### Mindful Mode
```
LUNCH - Today

Greek Salad
Grilled Chicken
Olive Oil Dressing

3 items logged

Nice balance of protein and vegetables!
```

**Key Differences:**
- No calorie totals
- Simple item list
- Item count instead of nutrition summary
- Encouraging observation about meal composition

---

## Language Transformations

### Terminology Changes

| Standard Term | Mindful Mode Term |
|---------------|-------------------|
| Log food | Add food |
| Track | Note / Record |
| Calories | (removed) |
| Deficit/Surplus | (removed) |
| Goal | Intention |
| Target | (removed or "aim") |
| Log This Meal | Add to Today |
| Failed / Over | (never used in any mode) |
| Cheat meal | (never used in any mode) |
| Good food / Bad food | (never used in any mode) |

### Message Transformations

| Context | Standard Message | Mindful Message |
|---------|-----------------|-----------------|
| Empty day | "No meals logged yet" | "Nothing added yet. What sounds good?" |
| Returning user | "Welcome back!" | "Welcome back. Ready when you are." |
| Meal logged | "Logged! 475 cal" | "Added! Looks delicious." |
| Weekly summary | "You averaged 2,100 cal/day" | "You logged 18 meals this week" |
| Suggestion | "Try to hit your protein goal" | "Eggs would add variety to your week" |

---

## Visual Changes

### Color Palette (Mindful Mode)

No changes to the core neutral palette, but additional emphasis on:
- Warmer tones in cards and backgrounds
- Softer shadows
- Reduced visual density

### Progress Visualization

| Standard Mode | Mindful Mode |
|---------------|--------------|
| Circular progress ring | **Removed entirely** |
| Macro progress bars | **Removed entirely** |
| Percentage indicators | **Removed entirely** |
| Streak counters | **Already removed (all modes)** |

**Replacement visuals:**
- Simple checkmarks for meals added
- Food group variety indicators (dots or icons)
- Weekly consistency dots (neutral, no color coding)

### Information Density

Mindful Mode has intentionally reduced information density:
- Larger spacing between elements
- Fewer data points per screen
- More whitespace
- Focus on one thing at a time

---

## Features Completely Hidden

The following are not shown anywhere in Mindful Mode:

1. **Calorie numbers** - All calorie values removed
2. **Macro grams** - Protein/Carbs/Fat numbers hidden
3. **Micro percentages** - RDA percentages hidden
4. **Weight input/display** - Weight field removed from profile
5. **Body measurements** - All body metrics hidden
6. **BMI calculations** - Never shown
7. **TDEE/BMR numbers** - Never shown
8. **Calorie targets** - No daily goal
9. **Deficit/surplus math** - No calculations shown
10. **Comparative charts** - No "you vs. goal" visualizations

---

## Features Preserved (Modified)

| Feature | How It's Modified |
|---------|------------------|
| Food logging | Works normally, just no numbers displayed |
| Photo recognition | AI still works, just shows food names |
| Barcode scanning | Finds food, shows name only |
| Recipes | Shows ingredients, not nutrition |
| Favorites | List of foods, no calorie info |
| HealthKit sync | Optional, nutrition NOT written to Health |

---

## Mode Switching

### Entering Mindful Mode

**Trigger**: Settings > Tracking Mode > Mindful Tracking

**Confirmation dialog**:
```
Switch to Mindful Tracking?

This mode focuses on food variety and eating patterns,
without showing calories or nutrition numbers.

Your data is still saved, and you can switch back
anytime without losing anything.

[Switch to Mindful] [Cancel]
```

### Exiting Mindful Mode

**Confirmation dialog**:
```
Switch to [Full/Simple] Tracking?

This will show calorie and nutrition information
throughout the app.

Take your time deciding. There's no pressure
to track numbers.

[Switch Mode] [Stay in Mindful]
```

### Data Preservation

- All logged data is preserved regardless of mode
- Switching modes is instant and non-destructive
- Historical data can be viewed with numbers if user switches to Standard Mode
- No "you've been in Mindful Mode for X days" messaging

---

## Onboarding Differences

When user selects Mindful Mode during onboarding:

### Skipped Screens
- Body Metrics (optional, can skip entirely)
- Activity Level (not needed without calorie targets)

### Modified Screens

**Goals Screen - Mindful Version**:
```
What brings you here?

[ ] Build a better relationship with food
[ ] Add more variety to my meals
[ ] Be more mindful about eating
[ ] Track meals without the stress
[ ] Just curious

[Continue]
```

**Setup Complete - Mindful Version**:
```
You're all set!

There are no targets to hit here.
Just note what you eat when you want to.

Some people find it helpful to log meals
as a way to be present with their food.
Others use it to notice patterns.

Use this however serves you best.

[Start Exploring]
```

---

## Special Considerations

### Avoiding Workarounds

Users with disordered eating patterns may try to calculate numbers themselves. We cannot prevent this, but we can:

1. **Never show serving weights** in Mindful Mode (only "1 cup", "1 medium", etc.)
2. **Not show detailed ingredients** in restaurant foods
3. **Avoid exact portion sizes** where possible

### Professional Support Integration (Future)

Consider future integration for ED recovery:
- Optional therapist/dietitian view sharing
- Structured check-ins designed with professionals
- Ability for treatment team to adjust features

### Emergency Resources

If patterns suggest concerning behavior (future ML feature):
- Non-judgmental prompt to check in with feelings
- Optional resources for eating disorder support
- Never punitive, always supportive

---

## Testing Requirements

### User Testing Cohorts

1. **ED Recovery users**: Must feel safe using the app
2. **Anxious trackers**: Those who find numbers stressful
3. **Intuitive eaters**: Those who reject diet culture

### Validation Questions

- "Did you ever feel judged or anxious using this mode?"
- "Were you ever tempted to calculate numbers?"
- "Did the app ever make you feel like you should eat less?"
- "Would you recommend this to someone in recovery?"

---

## Implementation Notes

### Data Model

All nutrition data is still stored and synced. Mindful Mode is purely a display layer change.

```swift
struct UserPreferences {
    var trackingMode: TrackingMode // .full, .simple, .mindful
    // Nutrition data is always captured, just not displayed
}
```

### View Conditionals

```swift
if user.trackingMode != .mindful {
    CalorieProgressRing(calories: meal.calories, target: user.calorieTarget)
} else {
    MealVarietyIndicator(mealCount: day.meals.count)
}
```

---

*Document prepared by Agent 02: UX*
*Phase 3: Architecture*
