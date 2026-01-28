# Widget Design Specifications
## iOS Home Screen, Lock Screen & Interactive Widgets

---

## Overview

Widgets extend the app experience to the home screen and lock screen, providing at-a-glance nutrition information and quick logging capabilities. All widgets must:

1. Update efficiently (respect 40-70 refresh budget)
2. Support Mindful Mode (hide numbers appropriately)
3. Be accessible (VoiceOver, Dynamic Type)
4. Deep link to relevant app sections

---

## 1. Small Home Screen Widget (2x2)

### Purpose
Show daily calorie progress at a glance. One-tap opens app to dashboard.

### Layout Specification

```
┌─────────────────────────┐
│  [App Icon]  [Weekday]  │
│                         │
│     ╭───────────╮       │
│     │  1,850    │       │
│     │ ─────────  │       │
│     │   2,400   │       │
│     ╰───────────╯       │
│                         │
│   Progress Ring (teal)  │
└─────────────────────────┘
```

### Dimensions
- Widget size: 169 x 169 pt (iPhone 14 Pro)
- Padding: 16pt all sides
- Progress ring: 80pt diameter
- Font sizes:
  - Weekday: SF Pro Text, 13pt, Secondary color
  - Current calories: SF Pro Rounded, 28pt, Bold, Primary color
  - Target: SF Pro Text, 15pt, Regular, Tertiary color

### Content

**Standard Mode**:
- Center: Current calories consumed
- Ring: Filled percentage of daily goal
- Label: Day of week ("Monday")
- Small app icon in corner

**Mindful Mode**:
- Center: Meal count ("3 meals")
- Ring: Hidden (use simple dots instead)
- Label: Day of week

### Data Requirements
- `dailyCaloriesConsumed: Int`
- `dailyCalorieTarget: Int`
- `mealCount: Int` (Mindful Mode)
- `trackingMode: TrackingMode`

### Tap Action
Deep link: `dietapp://dashboard/today`

### Refresh Strategy
- On meal log
- On app foreground
- Timeline: Hourly during waking hours (6am-10pm)

### Accessibility

VoiceOver label (Standard): "Today's nutrition. 1,850 of 2,400 calories consumed."

VoiceOver label (Mindful): "Today's meals. 3 meals logged."

---

## 2. Medium Home Screen Widget (4x2)

### Purpose
Show calorie + macro breakdown. Quick visual of daily progress.

### Layout Specification

```
┌─────────────────────────────────────────────────┐
│  [Icon] Today             Mon, Jan 27          │
│                                                 │
│  ╭─────────╮   Protein ████████░░░░  98g       │
│  │ 1,850   │   Carbs   ██████░░░░░░ 195g       │
│  │ / 2,400 │   Fat     ███████░░░░░  68g       │
│  ╰─────────╯                                   │
│     Ring                                        │
└─────────────────────────────────────────────────┘
```

### Dimensions
- Widget size: 360 x 169 pt (iPhone 14 Pro)
- Left section: 120pt wide (ring + numbers)
- Right section: Remaining space (macro bars)
- Progress ring: 64pt diameter
- Bar height: 8pt
- Bar corner radius: 4pt

### Content

**Standard Mode**:
- Left: Calorie ring with current/target
- Right: Three macro progress bars with grams
- Header: "Today" + full date

**Simple Mode**:
- Left: Calorie ring
- Right: Protein bar only

**Mindful Mode**:
- Left: Meal count with checkmarks
- Right: "Great variety today!" or meal list
- No numbers

### Data Requirements
- `dailyCaloriesConsumed: Int`
- `dailyCalorieTarget: Int`
- `proteinConsumed: Int`
- `proteinTarget: Int`
- `carbsConsumed: Int`
- `carbsTarget: Int`
- `fatConsumed: Int`
- `fatTarget: Int`
- `mealCount: Int`
- `trackingMode: TrackingMode`

### Color Coding
- All bars use Deep Teal fill (#1A5F5F)
- Background: Warm Sand (#F5E6D3) or system background
- No red/green for over/under (neutral design)

### Tap Action
Deep link: `dietapp://dashboard/today`

### Accessibility

VoiceOver label: "Today's nutrition. 1,850 of 2,400 calories. 98 grams protein, 195 grams carbs, 68 grams fat."

---

## 3. Large Home Screen Widget (4x4)

### Purpose
Comprehensive daily view with meals and quick-add option.

### Layout Specification

```
┌─────────────────────────────────────────────────┐
│  [Icon] Today's Progress            Mon, Jan 27│
├─────────────────────────────────────────────────┤
│                                                 │
│  ╭───────╮  Calories  ██████████░░  1,850      │
│  │ Ring  │  Protein   ████████░░░░    98g      │
│  ╰───────╯  Carbs     ██████░░░░░░   195g      │
│             Fat       ███████░░░░░    68g      │
│                                                 │
├─────────────────────────────────────────────────┤
│  TODAY'S MEALS                                  │
│                                                 │
│  ☀ Breakfast                          420 cal  │
│  ☀ Lunch                              650 cal  │
│  ○ Dinner                        + Add dinner  │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Dimensions
- Widget size: 360 x 376 pt (iPhone 14 Pro)
- Top section: ~40% (nutrition summary)
- Bottom section: ~60% (meal list)
- Meal row height: 44pt

### Content

**Standard Mode**:
- Top: Calorie ring + macro bars with values
- Bottom: Meal list with calories per meal
- Empty meal slots show "+ Add [meal]"

**Simple Mode**:
- Top: Calorie ring + protein bar only
- Bottom: Meal list with calories only

**Mindful Mode**:
- Top: Replaced with motivational message
- Bottom: Meal list with food names only (no calories)

### Meal Display Logic
- Show up to 4 meal types: Breakfast, Lunch, Dinner, Snacks
- Logged meals: Icon (sun/moon) + meal name + total calories
- Empty meals: Dashed circle + "+ Add [meal]"
- If >4 meals logged, show summary "+ 2 more snacks"

### Tap Actions
- Widget header: `dietapp://dashboard/today`
- Individual meal: `dietapp://meal/{mealId}`
- Add meal button: `dietapp://add-food?meal=dinner`

### Interactive Elements (iOS 17+)
- "+ Add dinner" button can trigger quick-add sheet
- See Section 5 for interactive widget details

### Accessibility

VoiceOver: Each meal row is a separate accessibility element with action "View meal" or "Add meal".

---

## 4. Lock Screen Widgets

### 4.1 Circular Widget (Small)

**Purpose**: Calories remaining at a glance

**Layout**:
```
    ╭───────╮
    │  550  │
    │ left  │
    ╰───────╯
```

**Content**:
- Number: Calories remaining (target - consumed)
- Label: "left" or "cal"

**Mindful Mode**:
- Number: Meal count
- Label: "meals"

**Dimensions**: 50pt diameter

**Tap Action**: Opens app to dashboard

### 4.2 Rectangular Widget (Medium)

**Purpose**: Quick progress overview

**Layout**:
```
┌─────────────────────────┐
│ Calories   [███████░░░] │
│ 1,850 / 2,400           │
└─────────────────────────┘
```

**Content**:
- Label: "Calories"
- Progress bar
- Fraction: Current / Target

**Mindful Mode**:
- Label: "Today"
- Text: "3 meals logged"
- No progress bar

**Dimensions**: 148 x 44pt

**Tap Action**: Opens app to dashboard

### 4.3 Inline Widget

**Purpose**: Minimal text-only widget

**Layout**:
```
[Icon] 1,850 / 2,400 cal
```

**Content**: Icon + calories consumed/target

**Mindful Mode**: "[Icon] 3 meals today"

**Tap Action**: Opens app to dashboard

---

## 5. Interactive Widget (iOS 17+)

### Quick Log Widget (Medium Size)

**Purpose**: Log favorite foods without opening the app

**Layout**:
```
┌─────────────────────────────────────────────────┐
│  Quick Log                      Today: 1,850   │
├─────────────────────────────────────────────────┤
│                                                 │
│  [Greek Yogurt]  [Banana]  [Coffee]  [+ More]  │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Interactive Elements**:
- 3 favorite food buttons
- "+ More" button

**Button Behavior**:
1. Tap "Greek Yogurt"
2. Intent fires to log food
3. Button shows checkmark briefly
4. Calories update
5. Haptic feedback

### Implementation Notes

```swift
struct QuickLogWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "QuickLog", intent: LogFoodIntent.self, provider: Provider()) { entry in
            QuickLogWidgetView(entry: entry)
        }
    }
}

struct LogFoodIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Food"

    @Parameter(title: "Food")
    var food: FoodEntity

    func perform() async throws -> some IntentResult {
        // Log food to database
        return .result()
    }
}
```

**Limitations**:
- Cannot open camera from widget
- Cannot search (only predefined options)
- Cannot enter custom amounts

**Fallback Behavior**:
- If logging fails, tap opens app with food pre-selected
- Show error state briefly, then revert

### Water Logging Widget (Small Size)

**Purpose**: Quick water intake logging

**Layout**:
```
┌─────────────────────────┐
│     💧 6 / 8 cups       │
│                         │
│      [ + 1 cup ]        │
│                         │
└─────────────────────────┘
```

**Interactive Elements**:
- "+ 1 cup" button
- Optional: glass size selector

**Button Behavior**:
1. Tap "+ 1 cup"
2. Count increments with animation
3. Progress bar fills
4. Haptic feedback
5. Writes to HealthKit

---

## 6. Widget Appearance Variants

### Light Mode
- Background: System white or Warm Sand (#F5E6D3)
- Text: Soft Charcoal (#3D3D3D)
- Progress: Deep Teal (#1A5F5F)
- Secondary: Warm Gray (#7A7A7A)

### Dark Mode
- Background: System dark gray
- Text: Off-White (#FAFAF8)
- Progress: Deep Teal (slightly lighter for contrast)
- Secondary: Medium gray

### Vibrant (Lock Screen)
- Use system vibrant materials
- High contrast for visibility
- Simplified graphics

---

## 7. Widget Gallery Metadata

### Small Widget
- **Display Name**: Daily Progress
- **Description**: See your calorie progress at a glance.

### Medium Widget
- **Display Name**: Nutrition Overview
- **Description**: Track calories and macros throughout the day.

### Large Widget
- **Display Name**: Today's Meals
- **Description**: View your meals and quickly add new ones.

### Quick Log Widget
- **Display Name**: Quick Log
- **Description**: Log your favorite foods with one tap.

### Lock Screen Circular
- **Display Name**: Calories Left
- **Description**: See remaining calories on your lock screen.

### Lock Screen Rectangular
- **Display Name**: Daily Calories
- **Description**: Progress toward your daily calorie goal.

---

## 8. Data Refresh Strategy

### Refresh Triggers

1. **App Foreground**: Refresh all widgets
2. **Meal Logged**: Refresh immediately via WidgetCenter
3. **Timeline Policy**: Hourly during 6am-10pm, every 4 hours otherwise
4. **HealthKit Update**: Refresh if weight changes (affects targets)

### Implementation

```swift
// After logging a meal
WidgetCenter.shared.reloadAllTimelines()

// Timeline provider
struct Provider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!

        let entry = NutritionEntry(date: currentDate, data: fetchNutritionData())
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))

        completion(timeline)
    }
}
```

### Budget Management
- Max 40-70 refreshes per day
- Prioritize user-triggered refreshes
- Batch background updates

---

## 9. Placeholder & Loading States

### Placeholder (Before Data)
- Show skeleton of widget layout
- Use placeholder values: "---" for numbers
- Show app name/icon

### Loading State
- Brief, use cached data when possible
- No spinners in widgets (feels slow)

### Error State
- Show last known data with "Last updated: [time]"
- Never show error messages in widget

---

## 10. Accessibility Requirements

### VoiceOver
- Every widget fully accessible
- Meaningful labels (not "button")
- Action descriptions for interactive elements

### Dynamic Type
- Support up to XXL size
- Layout adapts (reduce content if needed)
- Never clip text

### Reduce Transparency
- Solid backgrounds when enabled
- Maintain contrast ratios

### Reduce Motion
- No animated transitions in widgets
- Static progress indicators

---

## 11. Mindful Mode Widget Variants

### Small Widget (Mindful)
```
┌─────────────────────────┐
│       Monday            │
│                         │
│     ✓ ✓ ✓ ○            │
│    3 of 4 meals         │
│                         │
└─────────────────────────┘
```

### Medium Widget (Mindful)
```
┌─────────────────────────────────────────────────┐
│  [Icon] Today                       Mon, Jan 27│
│                                                 │
│  3 meals logged                                 │
│  Nice variety today!                           │
│                                                 │
│  ✓ Breakfast  ✓ Lunch  ○ Dinner               │
└─────────────────────────────────────────────────┘
```

### Large Widget (Mindful)
```
┌─────────────────────────────────────────────────┐
│  [Icon] Today's Meals               Mon, Jan 27│
├─────────────────────────────────────────────────┤
│                                                 │
│  You've had a great variety of foods today.   │
│                                                 │
├─────────────────────────────────────────────────┤
│  ✓ Breakfast: Oatmeal, berries                 │
│  ✓ Lunch: Chicken salad                        │
│  ○ Dinner: What sounds good?                   │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 12. Technical Specifications

### Supported Widget Families
- `.systemSmall` - 2x2 grid
- `.systemMedium` - 4x2 grid
- `.systemLarge` - 4x4 grid
- `.accessoryCircular` - Lock screen circular
- `.accessoryRectangular` - Lock screen rectangular
- `.accessoryInline` - Lock screen inline

### Minimum iOS Version
- Home screen widgets: iOS 16.0
- Lock screen widgets: iOS 16.0
- Interactive widgets: iOS 17.0

### App Group
Required for sharing data between app and widget extension:
`group.com.dietapp.shared`

### Shared Data Model
```swift
struct WidgetData: Codable {
    let caloriesConsumed: Int
    let calorieTarget: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let meals: [WidgetMeal]
    let trackingMode: TrackingMode
    let lastUpdated: Date
}

struct WidgetMeal: Codable {
    let id: UUID
    let type: MealType
    let summary: String
    let calories: Int?
}
```

---

*Document prepared by Agent 02: UX*
*Phase 3: Architecture*
