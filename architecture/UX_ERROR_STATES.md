# Error States & Edge Cases
## Comprehensive Error Handling Design

---

## Design Philosophy

Error handling follows our guilt-free principles:
- **Never blame the user**
- **Always provide a clear next action**
- **Be honest but not alarming**
- **Recover gracefully when possible**

---

## 1. Network Errors

### 1.1 No Internet Connection (Offline Mode)

**When**: Device has no network connectivity

**Visual Treatment**:
- Subtle offline indicator in header (not intrusive)
- Cloud icon with slash or "Offline" pill badge
- Cards function normally (no grayed out states)

**Message Copy**:
```
Header badge: "Offline"

(On sync attempt):
"You're offline right now. No worries—everything you log
is saved and will sync when you're back online."

[Dismiss]
```

**User Actions Available**:
- Full food logging (local database)
- View all previously synced foods
- Create recipes
- View insights (cached data)
- Search local food database

**Limited Actions**:
- Barcode scan (uses local cache first, may not find new products)
- AI photo recognition (queued for later if enabled)
- Sync with HealthKit (reads local, writes queued)

**Auto-Recovery**:
- Automatic sync when connection restored
- No user action required
- Brief success toast: "All synced!"

---

### 1.2 Slow/Unstable Connection

**When**: Requests timing out or intermittently failing

**Visual Treatment**:
- Loading states extend gracefully
- Skeleton screens instead of spinners where possible
- No error shown for first 10 seconds

**Message Copy** (after extended wait):
```
"Taking longer than usual.
We'll keep trying, or you can continue offline."

[Continue Offline] [Keep Waiting]
```

**User Actions Available**:
- Continue with cached data
- Wait for connection
- All offline features

---

### 1.3 Server Errors (5xx)

**When**: Our backend is experiencing issues

**Visual Treatment**:
- Friendly illustration (not a broken robot)
- Calm, warm tones

**Message Copy**:
```
"Something's not working on our end right now.

Your data is safe, and we're looking into it.
You can keep logging—everything will sync soon."

[Continue Offline]
```

**User Actions Available**:
- Full offline functionality
- No retry spam (auto-retry with backoff)

---

## 2. AI Recognition Errors

### 2.1 Recognition Failure (No Results)

**When**: AI cannot identify any food in photo

**Visual Treatment**:
- Photo displayed with gentle overlay
- No harsh error icons

**Message Copy**:
```
"Hmm, I couldn't identify the food in this photo.

This sometimes happens with unusual angles
or low lighting. Want to try again?"

[Retake Photo] [Search Instead] [Cancel]
```

**User Actions Available**:
- Retake photo
- Switch to manual search
- Cancel and return

---

### 2.2 Low Confidence Results

**When**: AI returns results but with low confidence

**Visual Treatment**:
- Results shown with visual confidence indicator
- More prominent "Edit" button
- "Not quite right?" helper text

**Message Copy**:
```
"I'm not 100% sure about these.
Take a look and adjust if needed."

[food results with edit buttons]

Not seeing your food? [Search for it]
```

**User Actions Available**:
- Accept as-is
- Edit individual items
- Search for replacement
- Add missing items

---

### 2.3 Portion Estimation Uncertainty

**When**: Food identified but portion size unclear

**Visual Treatment**:
- Portion shown as editable with "~" prefix
- Slider for easy adjustment

**Message Copy**:
```
Grilled Chicken Breast
~6 oz (adjust if needed)
[portion slider]

Tip: If you're unsure, our estimate
is based on typical serving sizes.
```

**User Actions Available**:
- Accept estimate
- Adjust with slider
- Enter exact amount manually

---

## 3. Food Not Found

### 3.1 Barcode Not in Database

**When**: Scanned barcode returns no results

**Visual Treatment**:
- Barcode number displayed
- Option to contribute data

**Message Copy**:
```
"We don't have this product yet.

Barcode: 012345678901

You can search for it by name, or help us
by adding it to the database."

[Search by Name] [Add This Product] [Cancel]
```

**User Actions Available**:
- Search manually
- Add new product (opens create flow)
- Cancel

---

### 3.2 Search Returns No Results

**When**: Text search has no matches

**Visual Treatment**:
- Friendly empty state illustration
- Search tips

**Message Copy**:
```
"No results for '[search term]'"

Try:
• Checking the spelling
• Using a simpler term (e.g., "apple" instead of "honeycrisp apple")
• Scanning the barcode if you have the package

[Scan Barcode] [Create Custom Food]
```

**User Actions Available**:
- Modify search
- Scan barcode
- Create custom food entry

---

### 3.3 Restaurant/Brand Not Found

**When**: User searches for specific restaurant item

**Visual Treatment**:
- Generic food suggestions
- Restaurant contribution prompt

**Message Copy**:
```
"We don't have '[Restaurant Name]' menu items yet.

Here are similar foods that might work:
[generic alternatives list]

[Use Generic] [Add Restaurant Item]
```

**User Actions Available**:
- Select generic alternative
- Create custom entry for restaurant

---

## 4. Sync Conflicts

### 4.1 Data Conflict Detected

**When**: Local changes conflict with server changes

**Visual Treatment**:
- Non-alarming info sheet
- Side-by-side comparison when helpful

**Message Copy**:
```
"This meal was updated on another device.

We found a small difference:

Your version: 1 cup rice
Other device: 1.5 cups rice

Which would you like to keep?"

[Keep Mine] [Use Other] [Keep Both]
```

**User Actions Available**:
- Keep local version
- Accept server version
- Merge (keep both as separate entries)

---

### 4.2 Background Sync Failure

**When**: Automatic sync fails silently

**Visual Treatment**:
- Small indicator on More tab
- No intrusive alerts

**Message Copy** (on More screen):
```
Sync Status
Last synced: 2 hours ago
Some items pending sync.

[Sync Now]
```

**User Actions Available**:
- Manual sync trigger
- View pending items
- Continue normally (will retry)

---

## 5. HealthKit Issues

### 5.1 Permission Denied

**When**: User denies HealthKit access

**Visual Treatment**:
- Informative card explaining benefits
- Clear path to enable

**Message Copy**:
```
"HealthKit isn't connected yet.

Connecting lets us:
• Read your workouts to adjust calorie needs
• Sync your nutrition data
• Track your progress in the Health app

This is optional—the app works great without it too."

[Connect to Health] [Maybe Later]
```

**User Actions Available**:
- Open Settings to enable
- Dismiss and use app without HealthKit
- Learn more

---

### 5.2 Partial Permissions

**When**: User granted some but not all permissions

**Visual Treatment**:
- Permission status list with checkmarks
- Non-judgmental about missing permissions

**Message Copy**:
```
"HealthKit Permissions

✓ Nutrition (write)
✓ Weight (read)
○ Workouts (not enabled)
○ Active Energy (not enabled)

Enabling workout access helps us adjust
your calories on active days.

[Manage Permissions]
```

**User Actions Available**:
- Adjust permissions in Settings
- Continue with partial sync
- Learn why each permission helps

---

### 5.3 HealthKit Sync Delay

**When**: HealthKit background delivery delayed

**Visual Treatment**:
- Subtle "syncing" indicator
- Timestamp of last sync

**Message Copy**:
```
"Last synced with Health: 30 minutes ago"

HealthKit syncs in the background.
Recent data will appear soon.

[Sync Now]
```

**User Actions Available**:
- Manual sync trigger
- Continue without waiting

---

## 6. Empty States

### 6.1 No Meals Logged Today

**When**: Dashboard shows empty day

**Visual Treatment**:
- Friendly illustration (not sad/empty)
- Clear CTA
- Time-aware greeting

**Message Copy**:
```
(Morning):
"Good morning! What's for breakfast?"

(Afternoon):
"Nothing logged yet today.
Start whenever you're ready."

(Evening):
"Quiet day? No pressure.
Log something when you feel like it."

[Add Your First Meal]
```

**User Actions Available**:
- Add food
- View previous days
- Normal navigation

---

### 6.2 No Insights Yet (New User)

**When**: Insights tab has insufficient data

**Visual Treatment**:
- Progress indicator (days until insights)
- Encouraging message

**Message Copy**:
```
"Your insights are brewing!

Log a few more days and I'll start
spotting patterns in your eating.

You've logged 2 of 5 days needed.
[progress bar]

[Back to Dashboard]
```

**User Actions Available**:
- Return to logging
- Explore sample insights

---

### 6.3 No Favorites Yet

**When**: Favorites list is empty

**Visual Treatment**:
- Explanatory illustration
- How-to instructions

**Message Copy**:
```
"No favorites yet"

Tap the heart on any food to add it here
for quick access later.

[Browse Foods]
```

**User Actions Available**:
- Browse foods to add favorites
- Search

---

### 6.4 No Recipes

**When**: Recipe list is empty

**Visual Treatment**:
- Recipe illustration
- Clear value proposition

**Message Copy**:
```
"No recipes yet"

Create recipes for meals you make often.
Log them with one tap instead of
adding each ingredient.

[Create a Recipe] [Import from URL]
```

**User Actions Available**:
- Create new recipe
- Import from URL

---

## 7. Permission & Access Errors

### 7.1 Camera Permission Denied

**When**: User tries photo logging without camera access

**Visual Treatment**:
- Modal with explanation
- Direct link to settings

**Message Copy**:
```
"Camera access needed"

To log food with photos, we need access
to your camera.

[Open Settings] [Search Instead]
```

**User Actions Available**:
- Open system settings
- Use search/barcode instead

---

### 7.2 Microphone Permission Denied

**When**: User tries voice logging without mic access

**Visual Treatment**:
- Modal with explanation

**Message Copy**:
```
"Microphone access needed"

To log food with your voice, we need
access to your microphone.

[Open Settings] [Type Instead]
```

**User Actions Available**:
- Open system settings
- Use search instead

---

### 7.3 Photo Library Access Denied

**When**: User tries to select photo without library access

**Visual Treatment**:
- Modal with explanation

**Message Copy**:
```
"Photo library access needed"

To select a food photo from your library,
we need access to your photos.

[Open Settings] [Take New Photo]
```

**User Actions Available**:
- Open system settings
- Take new photo instead

---

## 8. Account & Subscription Errors

### 8.1 Session Expired

**When**: Auth token has expired

**Visual Treatment**:
- Gentle modal, not kicked out
- Data preserved

**Message Copy**:
```
"Please sign in again"

Your session has expired.
All your data is safe—just sign in to continue.

[Sign In]
```

**User Actions Available**:
- Sign in again
- Use Apple Sign In for speed

---

### 8.2 Subscription Expired

**When**: Premium subscription lapsed

**Visual Treatment**:
- Informative card, not punishment
- Clear explanation of changes

**Message Copy**:
```
"Your subscription has ended"

Thanks for being a supporter!
Here's what changes:

• AI photo logging: Not available
• Advanced insights: Limited
• Everything else: Still works!

[Renew Subscription] [Continue Free]
```

**User Actions Available**:
- Renew subscription
- Continue with free tier
- Access core features

---

### 8.3 Purchase Failed

**When**: App Store purchase doesn't complete

**Visual Treatment**:
- Error card with next steps

**Message Copy**:
```
"Purchase didn't go through"

This sometimes happens. Try:
• Checking your payment method in Settings
• Waiting a moment and trying again

Your card wasn't charged.

[Try Again] [Later]
```

**User Actions Available**:
- Retry purchase
- Dismiss
- Check App Store settings

---

## 9. Data & Storage Errors

### 9.1 Storage Full

**When**: Device storage prevents saving

**Visual Treatment**:
- Warning banner (not blocking)

**Message Copy**:
```
"Storage is running low"

We couldn't save your food photo.
Free up some space to continue
logging with photos.

Your text entries still work fine.

[Dismiss]
```

**User Actions Available**:
- Dismiss warning
- Continue without photos
- Free up device storage

---

### 9.2 Database Corruption (Rare)

**When**: Local database is corrupted

**Visual Treatment**:
- Full-screen recovery flow

**Message Copy**:
```
"Something went wrong with your local data"

Don't worry—we can fix this.
Your cloud data is safe.

We'll restore from your last backup.
This might take a moment.

[Restore Now]
```

**User Actions Available**:
- Start recovery
- Contact support if recovery fails

---

## 10. Edge Case Behaviors

### 10.1 Extremely Large Meal

**When**: User logs 10+ items in one meal

**Visual Treatment**:
- Normal logging, confirmation prompt

**Message Copy**:
```
"That's a big meal! Just confirming:

15 items totaling 3,400 calories

Is this one meal or should we split it up?"

[Log as One Meal] [Split Into Multiple]
```

---

### 10.2 Duplicate Detection

**When**: Same food logged twice in quick succession

**Visual Treatment**:
- Subtle confirmation

**Message Copy**:
```
"Looks like you just added Greek Yogurt.

Add another serving?"

[Yes, Add Again] [Cancel]
```

---

### 10.3 Unusual Time

**When**: Logging for unusual time (3am breakfast)

**Visual Treatment**:
- Time confirmation

**Message Copy**:
```
"Logging for 3:00 AM?

[Yes, That's Right] [Change Time]
```

---

### 10.4 Future Date Logging

**When**: User tries to log for future date

**Visual Treatment**:
- Gentle block

**Message Copy**:
```
"Can't log for future dates yet"

You can log for today or any past date.

[Log for Today] [Choose Different Date]
```

---

## Error State Consistency

### Visual Components

All error states use:
- **Illustrations**: Warm, friendly, not sad/broken
- **Colors**: Terracotta accent for attention, not red
- **Typography**: Body text, not shouty headlines
- **Buttons**: Primary CTA + subtle secondary option

### Animation

- Errors appear with gentle fade, not jarring pop
- Dismissal with smooth transition
- Loading states use subtle pulse, not aggressive spinners

### Accessibility

- All error messages are announced by VoiceOver
- Error states have minimum 4.5:1 contrast
- CTAs meet 44x44pt touch target minimum
- No error relies solely on color

---

*Document prepared by Agent 02: UX*
*Phase 3: Architecture*
