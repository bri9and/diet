# Complete Screen Inventory
## Diet App - Agent 02: UX Architecture

---

## Overview

This document catalogs every screen in the app with purpose, components, navigation, and data requirements. Screens are organized by user journey phase.

---

## 1. Onboarding Flow (7 Screens)

### 1.1 Welcome Screen
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Welcome |
| **Purpose** | First impression, set tone, explain value proposition |
| **Key Components** | - App logo<br>- Tagline: "Track your nutrition. Your way."<br>- Primary CTA: "Get Started"<br>- Secondary: "I already have an account" |
| **Navigation** | - Primary CTA -> Tracking Mode Selection<br>- Secondary -> Sign In |
| **Data Requirements** | None |

### 1.2 Tracking Mode Selection
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Tracking Mode Selection |
| **Purpose** | Let user choose their tracking style upfront (critical for ED-safety) |
| **Key Components** | - Mode cards (3):<br>&nbsp;&nbsp;- **Full Tracking**: "Calories, macros, and micronutrients"<br>&nbsp;&nbsp;- **Simple Tracking**: "Calories and protein only"<br>&nbsp;&nbsp;- **Mindful Tracking**: "Focus on food groups, no numbers"<br>- "You can change this anytime" reassurance<br>- Continue button |
| **Navigation** | From: Welcome -> To: Goals |
| **Data Requirements** | Write: user.tracking_mode |

### 1.3 Goals Screen
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Goals |
| **Purpose** | Understand user's primary motivation (without judgment) |
| **Key Components** | - Question: "What brings you here?"<br>- Selectable options (multi-select allowed):<br>&nbsp;&nbsp;- "Understand what I'm eating"<br>&nbsp;&nbsp;- "Support my fitness goals"<br>&nbsp;&nbsp;- "Feel more energized"<br>&nbsp;&nbsp;- "Build consistent habits"<br>&nbsp;&nbsp;- "Follow a nutrition plan"<br>&nbsp;&nbsp;- "Just curious"<br>- Continue button |
| **Navigation** | From: Tracking Mode -> To: Body Metrics |
| **Data Requirements** | Write: user.goals[] |

### 1.4 Body Metrics Screen
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Body Metrics |
| **Purpose** | Collect data for calorie calculations (optional in Mindful Mode) |
| **Key Components** | - Height input (ft/in or cm toggle)<br>- Weight input (lbs or kg toggle)<br>- Age input<br>- Biological sex (for TDEE accuracy)<br>- "Why we ask" info button<br>- Skip option for Mindful Mode<br>- Continue button |
| **Navigation** | From: Goals -> To: Activity Level |
| **Data Requirements** | Write: user.height, user.weight, user.age, user.sex |

### 1.5 Activity Level Screen
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Activity Level |
| **Purpose** | Determine baseline activity multiplier |
| **Key Components** | - Visual cards with descriptions:<br>&nbsp;&nbsp;- Sedentary: "Mostly sitting (desk job)"<br>&nbsp;&nbsp;- Lightly Active: "Light movement (walking, standing)"<br>&nbsp;&nbsp;- Active: "Regular exercise (3-4x/week)"<br>&nbsp;&nbsp;- Very Active: "Intense training (5-6x/week)"<br>&nbsp;&nbsp;- Athlete: "Training 2+ hours daily"<br>- Continue button |
| **Navigation** | From: Body Metrics -> To: Dietary Preferences |
| **Data Requirements** | Write: user.activity_level |

### 1.6 Dietary Preferences Screen
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Dietary Preferences |
| **Purpose** | Personalize food suggestions and database filtering |
| **Key Components** | - Multi-select chips:<br>&nbsp;&nbsp;- None/Everything<br>&nbsp;&nbsp;- Vegetarian<br>&nbsp;&nbsp;- Vegan<br>&nbsp;&nbsp;- Pescatarian<br>&nbsp;&nbsp;- Keto/Low-Carb<br>&nbsp;&nbsp;- Gluten-Free<br>&nbsp;&nbsp;- Dairy-Free<br>&nbsp;&nbsp;- Halal<br>&nbsp;&nbsp;- Kosher<br>- Allergy section (optional)<br>- Continue button |
| **Navigation** | From: Activity Level -> To: Notifications |
| **Data Requirements** | Write: user.dietary_preferences[], user.allergies[] |

### 1.7 Notifications Screen
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Notification Preferences |
| **Purpose** | Give user control over reminders (respect vs. nag) |
| **Key Components** | - Toggle: Meal reminders (off by default)<br>- Time pickers for: Breakfast, Lunch, Dinner<br>- Toggle: Weekly insights<br>- Toggle: Tips and suggestions<br>- "You're in control" messaging<br>- Continue button |
| **Navigation** | From: Dietary Preferences -> To: Setup Complete |
| **Data Requirements** | Write: user.notification_preferences |

### 1.8 Setup Complete Screen
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Setup Complete |
| **Purpose** | Celebrate completion, transition to app |
| **Key Components** | - Success illustration<br>- Personalized message: "You're all set, [Name]!"<br>- Calculated targets display (if not Mindful Mode)<br>- "Start Tracking" CTA |
| **Navigation** | From: Notifications -> To: Dashboard |
| **Data Requirements** | Read: calculated TDEE, macros |

---

## 2. Main App Screens (3 Primary)

### 2.1 Dashboard (Home)
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Dashboard |
| **Purpose** | Daily overview, primary logging entry point |
| **Key Components** | - Date selector (swipeable)<br>- Greeting with time-of-day awareness<br>- Nutrition summary card:<br>&nbsp;&nbsp;- Calories progress ring<br>&nbsp;&nbsp;- Macro bars (Protein, Carbs, Fat)<br>&nbsp;&nbsp;- Optional: micronutrient highlights<br>- Today's meals list:<br>&nbsp;&nbsp;- Meal cards (Breakfast, Lunch, Dinner, Snacks)<br>&nbsp;&nbsp;- Each shows: foods logged, total cals/macros<br>&nbsp;&nbsp;- Empty state: dashed add prompt<br>- FAB (Floating Action Button) for quick add |
| **Navigation** | - Date tap -> Day Detail<br>- Meal card tap -> Meal Detail<br>- FAB -> Add Food modal<br>- Tab bar: Home (active), Insights, More |
| **Data Requirements** | Read: meals for selected date, nutrition totals, daily targets |

### 2.2 Insights
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Insights |
| **Purpose** | Weekly/monthly trends, patterns, and suggestions |
| **Key Components** | - Time period selector (This Week, Last Week, This Month)<br>- Summary card:<br>&nbsp;&nbsp;- Days logged: X of 7<br>&nbsp;&nbsp;- Average calories/day<br>&nbsp;&nbsp;- Consistency messaging (positive)<br>- Trend charts (Swift Charts):<br>&nbsp;&nbsp;- Calories over time<br>&nbsp;&nbsp;- Macro distribution<br>- Patterns section:<br>&nbsp;&nbsp;- AI-detected observations<br>&nbsp;&nbsp;- e.g., "Protein tends to be lower on weekends"<br>- Suggestions section:<br>&nbsp;&nbsp;- Actionable, positive recommendations |
| **Navigation** | - Tab bar: Home, Insights (active), More<br>- Tap patterns/suggestions for detail |
| **Data Requirements** | Read: aggregated nutrition data, computed trends |

### 2.3 More (Settings Hub)
| Attribute | Details |
|-----------|---------|
| **Screen Name** | More |
| **Purpose** | Access to settings, profile, and secondary features |
| **Key Components** | - Profile card (avatar, name, current plan)<br>- Quick stats (days logged, longest streak optional)<br>- Menu sections:<br>&nbsp;&nbsp;- **Tracking**: Goals, Targets, Tracking Mode<br>&nbsp;&nbsp;- **Data**: My Foods, Recipes, Favorites<br>&nbsp;&nbsp;- **Connections**: HealthKit, Integrations<br>&nbsp;&nbsp;- **Preferences**: Notifications, Appearance, Units<br>&nbsp;&nbsp;- **Account**: Profile, Subscription, Export Data<br>&nbsp;&nbsp;- **Support**: Help, Contact, About |
| **Navigation** | Tab bar: Home, Insights, More (active)<br>- Each row -> corresponding subscreen |
| **Data Requirements** | Read: user profile, subscription status |

---

## 3. Food Logging Flow (4 Screens)

### 3.1 Add Food Modal
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Add Food |
| **Purpose** | Entry point for all food logging methods |
| **Key Components** | - Search bar (top)<br>- Quick action buttons row:<br>&nbsp;&nbsp;- Camera (photo)<br>&nbsp;&nbsp;- Microphone (voice)<br>&nbsp;&nbsp;- Barcode (scan)<br>- Recent foods list<br>- Favorites section<br>- Cancel (X) button |
| **Navigation** | - Search -> Search Results<br>- Camera -> Photo Capture<br>- Microphone -> Voice Input<br>- Barcode -> Barcode Scanner<br>- Recent/Favorite tap -> Food Detail (pre-filled)<br>- X -> Dismiss to Dashboard |
| **Data Requirements** | Read: recent foods, favorites |

### 3.2 Photo Capture Screen
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Photo Capture |
| **Purpose** | Capture food photo for AI recognition |
| **Key Components** | - Full-screen camera viewfinder<br>- Capture button (large, centered bottom)<br>- Flash toggle<br>- Photo library picker<br>- Close button<br>- Guidance overlay: "Center your food in frame"<br>- Processing state: circular progress indicator |
| **Navigation** | - Capture -> Photo Review (processing)<br>- Library -> System picker -> Photo Review<br>- Close -> Add Food Modal |
| **Data Requirements** | Write: captured image (temp storage) |

### 3.3 Photo Review Screen
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Photo Review |
| **Purpose** | Review and confirm AI-identified foods |
| **Key Components** | - Captured photo (top, cropped 16:9)<br>- "We identified:" heading<br>- Food item cards (each):<br>&nbsp;&nbsp;- Food name<br>&nbsp;&nbsp;- Estimated portion<br>&nbsp;&nbsp;- Calories and key macros<br>&nbsp;&nbsp;- Confidence indicator (visual only, not %)<br>&nbsp;&nbsp;- Edit button<br>- "+ Add missing item" button<br>- Total summary bar<br>- "Log This Meal" primary CTA<br>- Back button |
| **Navigation** | - Edit -> Food Edit<br>- Add missing -> Search<br>- Log -> Dashboard (with success feedback)<br>- Back -> Photo Capture |
| **Data Requirements** | Read: AI recognition results<br>Write: meal entry on log |

### 3.4 Food Search Results
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Search Results |
| **Purpose** | Find foods by text search |
| **Key Components** | - Search bar (active, with input)<br>- Filter chips: All, Verified, My Foods, Recipes<br>- Results list:<br>&nbsp;&nbsp;- Food name<br>&nbsp;&nbsp;- Brand (if applicable)<br>&nbsp;&nbsp;- Serving size<br>&nbsp;&nbsp;- Calories per serving<br>&nbsp;&nbsp;- Quick-add (+) button<br>- Empty state for no results<br>- Barcode scan shortcut (if no results) |
| **Navigation** | - Food tap -> Food Detail<br>- Quick-add -> Log immediately + haptic<br>- Barcode -> Barcode Scanner |
| **Data Requirements** | Read: food database search results |

---

## 4. Detail Views (4 Screens)

### 4.1 Food Detail
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Food Detail |
| **Purpose** | View full nutrition info, adjust serving, log food |
| **Key Components** | - Food name and brand<br>- Serving size selector (stepper or picker)<br>- Serving unit selector<br>- Nutrition facts panel:<br>&nbsp;&nbsp;- Calories (prominent)<br>&nbsp;&nbsp;- Macros: Protein, Carbs, Fat<br>&nbsp;&nbsp;- Expandable micronutrients<br>- Meal type selector: Breakfast, Lunch, Dinner, Snack<br>- Date picker (defaults to today)<br>- "Log Food" primary CTA<br>- "Add to Favorites" secondary<br>- Back button |
| **Navigation** | - Log -> Previous screen + success feedback<br>- Back -> Search Results or Add Food Modal |
| **Data Requirements** | Read: food nutrition data<br>Write: meal_item entry, favorites |

### 4.2 Food Edit
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Food Edit |
| **Purpose** | Correct AI-identified food or adjust logged item |
| **Key Components** | - Current food name (editable/searchable)<br>- Portion adjustment (visual slider + input)<br>- Alternative suggestions: "Did you mean..."<br>- Manual override fields<br>- Delete item option<br>- Save button |
| **Navigation** | - Save -> Photo Review (updated) or Meal Detail<br>- Search replacement -> Search -> back with new food |
| **Data Requirements** | Read/Write: food item in current meal |

### 4.3 Meal Detail
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Meal Detail |
| **Purpose** | View all foods in a meal, edit, add more |
| **Key Components** | - Meal type header (e.g., "Lunch")<br>- Date/time<br>- Photo thumbnail (if photo-logged)<br>- Food items list:<br>&nbsp;&nbsp;- Each item with calories, portion<br>&nbsp;&nbsp;- Swipe to delete<br>&nbsp;&nbsp;- Tap to edit<br>- Meal totals summary<br>- "+ Add more" button<br>- Back button |
| **Navigation** | - Food tap -> Food Edit<br>- Add more -> Add Food Modal<br>- Back -> Dashboard |
| **Data Requirements** | Read: meal with all food items |

### 4.4 Day Detail
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Day Detail |
| **Purpose** | Full day overview with all nutrition data |
| **Key Components** | - Date header with navigation arrows<br>- Full nutrition breakdown:<br>&nbsp;&nbsp;- Calories (eaten vs. target)<br>&nbsp;&nbsp;- Full macro breakdown<br>&nbsp;&nbsp;- Micronutrient highlights/warnings<br>- Meals list (all 4 types)<br>- Day notes field (optional journaling)<br>- HealthKit data (if connected):<br>&nbsp;&nbsp;- Steps, Active calories, Workouts |
| **Navigation** | - Meal tap -> Meal Detail<br>- Date arrows -> Adjacent days<br>- Back -> Dashboard |
| **Data Requirements** | Read: all meals for date, nutrition totals, HealthKit data |

---

## 5. Settings Subscreens (12 Screens)

### 5.1 Goals & Targets
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Goals & Targets |
| **Purpose** | View and adjust nutrition targets |
| **Key Components** | - Current goal display<br>- Calorie target (calculated + adjustable)<br>- Macro targets (g and %)<br>- Weekly goal (deficit/surplus)<br>- "Recalculate" based on progress button<br>- Toggle: Use adaptive targets |
| **Navigation** | From: More -> Tracking |
| **Data Requirements** | Read/Write: user targets, TDEE |

### 5.2 Tracking Mode
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Tracking Mode Settings |
| **Purpose** | Switch between Full/Simple/Mindful modes |
| **Key Components** | - Current mode indicator<br>- Mode descriptions<br>- Mode selector<br>- "Changes take effect immediately" note |
| **Navigation** | From: More -> Tracking |
| **Data Requirements** | Write: user.tracking_mode |

### 5.3 My Foods
| Attribute | Details |
|-----------|---------|
| **Screen Name** | My Foods |
| **Purpose** | Manage custom foods created by user |
| **Key Components** | - Search/filter bar<br>- Custom foods list<br>- "+ Create Food" button<br>- Swipe to edit/delete |
| **Navigation** | From: More -> Data |
| **Data Requirements** | Read/Write: user custom foods |

### 5.4 My Recipes
| Attribute | Details |
|-----------|---------|
| **Screen Name** | My Recipes |
| **Purpose** | Manage custom recipes |
| **Key Components** | - Recipe list with thumbnails<br>- "+ Create Recipe" button<br>- Import from URL option<br>- Swipe to edit/delete |
| **Navigation** | From: More -> Data |
| **Data Requirements** | Read/Write: user recipes |

### 5.5 Favorites
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Favorites |
| **Purpose** | Manage favorited foods for quick logging |
| **Key Components** | - Favorites list<br>- Reorder capability<br>- Remove from favorites (swipe) |
| **Navigation** | From: More -> Data |
| **Data Requirements** | Read/Write: user favorites |

### 5.6 HealthKit Settings
| Attribute | Details |
|-----------|---------|
| **Screen Name** | HealthKit Settings |
| **Purpose** | Manage Apple Health integration |
| **Key Components** | - Connection status<br>- "Connect to Health" or "Manage Permissions"<br>- Data sync toggles:<br>&nbsp;&nbsp;- Read: Weight, Workouts, Steps<br>&nbsp;&nbsp;- Write: Nutrition, Water<br>- Last sync timestamp<br>- Manual sync button |
| **Navigation** | From: More -> Connections |
| **Data Requirements** | Read/Write: HealthKit authorization status |

### 5.7 Notification Settings
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Notification Settings |
| **Purpose** | Fine-tune notification preferences |
| **Key Components** | - System permission status<br>- Meal reminder toggles + time pickers<br>- Weekly insights toggle<br>- Tips toggle<br>- Quiet hours setting |
| **Navigation** | From: More -> Preferences |
| **Data Requirements** | Read/Write: notification preferences |

### 5.8 Appearance Settings
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Appearance |
| **Purpose** | Theme and display options |
| **Key Components** | - Theme selector: System, Light, Dark<br>- Accent color (future)<br>- Dashboard layout options (future) |
| **Navigation** | From: More -> Preferences |
| **Data Requirements** | Write: appearance preferences |

### 5.9 Units Settings
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Units |
| **Purpose** | Set measurement unit preferences |
| **Key Components** | - Weight: lbs / kg<br>- Height: ft-in / cm<br>- Energy: kcal / kJ<br>- Liquid: cups / mL |
| **Navigation** | From: More -> Preferences |
| **Data Requirements** | Write: unit preferences |

### 5.10 Profile Settings
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Profile |
| **Purpose** | Manage account and personal info |
| **Key Components** | - Avatar (editable)<br>- Display name<br>- Email<br>- Body metrics (link to update)<br>- Sign out button |
| **Navigation** | From: More -> Account |
| **Data Requirements** | Read/Write: user profile |

### 5.11 Subscription
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Subscription |
| **Purpose** | View and manage subscription status |
| **Key Components** | - Current plan<br>- Renewal date<br>- "Manage Subscription" (opens App Store)<br>- "Restore Purchases" button<br>- Plan comparison (if free user) |
| **Navigation** | From: More -> Account |
| **Data Requirements** | Read: subscription status via StoreKit |

### 5.12 Export Data
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Export Data |
| **Purpose** | Download personal data (GDPR compliance) |
| **Key Components** | - Export format options (CSV, JSON)<br>- Date range selector<br>- Data categories checkboxes<br>- "Request Export" button<br>- Previous exports list |
| **Navigation** | From: More -> Account |
| **Data Requirements** | Read: all user data for export |

---

## 6. Auxiliary Screens (4 Screens)

### 6.1 Barcode Scanner
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Barcode Scanner |
| **Purpose** | Scan product barcodes for quick logging |
| **Key Components** | - Camera viewfinder with scan area overlay<br>- Torch toggle<br>- Manual entry link<br>- Close button<br>- Scanning status indicator |
| **Navigation** | - Scan success -> Food Detail (pre-filled)<br>- Not found -> Search with barcode number<br>- Manual entry -> Search<br>- Close -> Add Food Modal |
| **Data Requirements** | Read: barcode database lookup |

### 6.2 Voice Input
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Voice Input |
| **Purpose** | Log food via natural language |
| **Key Components** | - Large microphone button<br>- Waveform visualization<br>- Transcription display (live)<br>- Example prompts<br>- Cancel button |
| **Navigation** | - Success -> Photo Review (with parsed items)<br>- Cancel -> Add Food Modal |
| **Data Requirements** | Write: transcribed text for NLP processing |

### 6.3 Sign In
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Sign In |
| **Purpose** | Authenticate returning users |
| **Key Components** | - Apple Sign In button (primary)<br>- Email/password fields<br>- "Forgot Password" link<br>- "Create Account" link |
| **Navigation** | - Success -> Dashboard<br>- Create Account -> Onboarding |
| **Data Requirements** | Write: authentication tokens |

### 6.4 Create Recipe
| Attribute | Details |
|-----------|---------|
| **Screen Name** | Create Recipe |
| **Purpose** | Build custom recipes from ingredients |
| **Key Components** | - Recipe name field<br>- Servings input<br>- Ingredients list (searchable add)<br>- Per-ingredient amount/unit<br>- Calculated nutrition display<br>- Photo upload (optional)<br>- Save button |
| **Navigation** | - Add ingredient -> Search modal<br>- Save -> My Recipes<br>- Cancel -> My Recipes |
| **Data Requirements** | Write: recipe with ingredients |

---

## Navigation Map

```
Welcome
    |
    v
Tracking Mode -> Goals -> Body Metrics -> Activity -> Dietary -> Notifications -> Setup Complete
                                                                                        |
                                                                                        v
                                                                            +----- Dashboard -----+
                                                                            |          |          |
                                                                            v          v          v
                                                                        Insights    More     Add Food
                                                                            |          |          |
                                                                            v          v          +-> Camera -> Photo Review
                                                            (trend details)   (settings)          +-> Search -> Food Detail
                                                                                   |              +-> Barcode -> Food Detail
                                                                                   v              +-> Voice -> Photo Review
                                                                            +-> Goals & Targets
                                                                            +-> Tracking Mode
                                                                            +-> My Foods
                                                                            +-> My Recipes
                                                                            +-> Favorites
                                                                            +-> HealthKit
                                                                            +-> Notifications
                                                                            +-> Appearance
                                                                            +-> Units
                                                                            +-> Profile
                                                                            +-> Subscription
                                                                            +-> Export Data
```

---

## Screen Count Summary

| Category | Count |
|----------|-------|
| Onboarding | 8 |
| Main App | 3 |
| Food Logging | 4 |
| Detail Views | 4 |
| Settings | 12 |
| Auxiliary | 4 |
| **Total** | **35** |

---

*Document prepared by Agent 02: UX*
*Phase 3: Architecture*
