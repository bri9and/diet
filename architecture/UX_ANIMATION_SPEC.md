# Animation & Transition Specification
## Motion Design for Diet App

---

## Design Philosophy

Motion in our app serves three purposes:
1. **Feedback**: Confirm user actions happened
2. **Orientation**: Help users understand where they are
3. **Delight**: Add polish without distraction

**Guiding Principle**: Motion should feel natural and responsive, never slow or flashy. Less is more.

---

## 1. System Accessibility Compliance

### Reduced Motion Support

All animations MUST respect the system's Reduced Motion setting.

```swift
// Check preference
let prefersReducedMotion = UIAccessibility.isReduceMotionEnabled

// SwiftUI modifier
.animation(prefersReducedMotion ? nil : .default, value: state)
```

### Reduced Motion Alternatives

| Standard Animation | Reduced Motion Alternative |
|-------------------|---------------------------|
| Slide transitions | Cross-fade |
| Spring animations | Instant state change |
| Progress ring animation | Static display |
| Loading pulse | Static opacity change |
| Parallax effects | None |
| Scale transitions | Cross-fade |

### Never Disable These (Even with Reduced Motion)

- Haptic feedback (not visual)
- Focus state changes
- Error state displays
- Success confirmations (can be instant, but must show)

---

## 2. Screen Transitions

### Navigation Push (Forward)

**Standard Motion**:
- Duration: 350ms
- Curve: Ease-out (deceleration)
- Effect: New screen slides in from right
- Outgoing screen: Slides left 30% with slight opacity fade (0.3)

**SwiftUI Implementation**:
```swift
.navigationTransition(.slide)
// Or custom:
.transition(.asymmetric(
    insertion: .move(edge: .trailing),
    removal: .opacity.combined(with: .offset(x: -100))
))
```

**Reduced Motion**:
- Duration: 150ms
- Effect: Cross-fade only

---

### Navigation Pop (Back)

**Standard Motion**:
- Duration: 300ms
- Curve: Ease-out
- Effect: Current screen slides out to right
- Previous screen: Slides in from left 30%

**Reduced Motion**:
- Duration: 150ms
- Effect: Cross-fade only

---

### Modal Presentation

**Standard Motion**:
- Duration: 400ms
- Curve: Spring (response: 0.4, dampingFraction: 0.8)
- Effect: Slide up from bottom
- Background: Dim to 50% black with 200ms fade

**SwiftUI Implementation**:
```swift
.sheet(isPresented: $isPresented) {
    // Automatic spring animation
}
```

**Reduced Motion**:
- Duration: 200ms
- Effect: Fade in from 0 to 1 opacity
- No slide

---

### Modal Dismissal

**Standard Motion**:
- Duration: 300ms
- Curve: Ease-in (acceleration)
- Effect: Slide down + fade
- Swipe-to-dismiss: Follows finger, spring back if < 50%

**Reduced Motion**:
- Duration: 150ms
- Effect: Fade out only

---

### Tab Switching

**Standard Motion**:
- Duration: 200ms
- Curve: Ease-in-out
- Effect: Cross-fade between tab content
- Tab bar: Instant icon change, scale pop on selected (1.0 -> 1.1 -> 1.0)

**Reduced Motion**:
- Instant switch, no animation

---

## 3. Loading States

### Initial Content Load

**Standard Motion**:
- Skeleton screens with shimmer effect
- Shimmer: Linear gradient sweep, 1.5s duration, infinite
- Skeleton opacity: 0.3 to 0.5 pulse

**SwiftUI Implementation**:
```swift
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.4), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 200
                }
            }
    }
}
```

**Reduced Motion**:
- Static skeleton (no shimmer)
- Subtle opacity pulse: 0.3 -> 0.5, 1s duration

---

### Inline Loading (Buttons, Actions)

**Standard Motion**:
- Button text fades to loading spinner
- Spinner: System ActivityIndicator or custom
- Duration for text fade: 150ms

**Reduced Motion**:
- Instant swap to spinner (no fade)

---

### Pull to Refresh

**Standard Motion**:
- Native iOS pull-to-refresh behavior
- Custom: Rotation animation on pull indicator
- Spring bounce on release

**Reduced Motion**:
- Use native behavior (already accessible)

---

### Photo Processing (AI Recognition)

**Standard Motion**:
- Circular progress indicator
- Pulse effect on photo overlay
- Duration: Matches actual processing time

**Visual Spec**:
```
[Photo]
   |
[Circular progress ring, Deep Teal]
   |
[Text: "Looking at your meal..."]
```

**Reduced Motion**:
- Static spinner, no pulse
- Progress ring without animation (instant updates)

---

## 4. Success Animations

### Food Logged Successfully

**Standard Motion**:
- Checkmark draw animation (0.3s)
- Scale pop: 0.8 -> 1.1 -> 1.0 (spring)
- Subtle confetti optional (very subtle, 5-8 particles)
- Auto-dismiss after 1.5s

**SwiftUI Implementation**:
```swift
struct CheckmarkAnimation: View {
    @State private var isAnimating = false

    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 48))
            .foregroundColor(.deepTeal)
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isAnimating = true
                }
            }
    }
}
```

**Reduced Motion**:
- Instant checkmark display (no draw/scale)
- Auto-dismiss still works

**Haptic**: Medium impact feedback

---

### Favorite Added

**Standard Motion**:
- Heart icon: Scale 1.0 -> 1.3 -> 1.0 (spring)
- Fill animation from outline to filled
- Duration: 300ms

**Reduced Motion**:
- Instant state change

**Haptic**: Light impact feedback

---

### Recipe Saved

**Standard Motion**:
- Similar to food logged
- Checkmark with brief scale

**Reduced Motion**:
- Instant confirmation

---

### Sync Complete

**Standard Motion**:
- Cloud icon with checkmark
- Brief green tint pulse
- Auto-dismiss toast after 2s

**Reduced Motion**:
- Static display, no pulse

---

## 5. Micro-interactions

### Button Tap

**Standard Motion**:
- Scale: 1.0 -> 0.97 on press
- Opacity: 1.0 -> 0.9 on press
- Return: Spring (0.2s)

**SwiftUI Implementation**:
```swift
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
```

**Reduced Motion**:
- Opacity change only (no scale)

**Haptic**: Light impact on release

---

### Toggle Switch

**Standard Motion**:
- Thumb slides with spring
- Background color fade: 200ms
- Duration: 250ms total

**Reduced Motion**:
- Instant state change

**Haptic**: Light impact

---

### Slider Adjustment

**Standard Motion**:
- Value label updates in real-time
- Subtle scale on thumb when dragging
- Smooth value interpolation

**Reduced Motion**:
- No continuous animation
- Values update on release

**Haptic**: Selection feedback on value stops

---

### Card Selection

**Standard Motion**:
- Scale: 1.0 -> 1.02 on hover/focus
- Border highlight fade in: 200ms
- Checkmark fade in: 150ms

**Reduced Motion**:
- Border instant, no scale

---

### Swipe Actions (Delete, Edit)

**Standard Motion**:
- Actions reveal with drag
- Spring snap back if not committed
- Destructive actions: red background fade in

**Reduced Motion**:
- Use native behavior

---

### FAB (Floating Action Button) Tap

**Standard Motion**:
- Scale pulse: 1.0 -> 0.95 -> 1.0
- Opens modal (see modal transition)

**Reduced Motion**:
- No pulse, direct modal open

**Haptic**: Medium impact

---

## 6. Progress Visualizations

### Calorie Progress Ring

**Standard Motion**:
- Ring fills from 0 to current value
- Duration: 600ms
- Curve: Ease-out
- Numbers count up alongside

**SwiftUI Implementation**:
```swift
struct ProgressRing: View {
    let progress: Double
    @State private var animatedProgress: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: animatedProgress)
            .stroke(Color.deepTeal, lineWidth: 12)
            .rotationEffect(.degrees(-90))
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animatedProgress = progress
                }
            }
    }
}
```

**Reduced Motion**:
- Instant display at current value
- No animation on appear

---

### Macro Progress Bars

**Standard Motion**:
- Bars fill left-to-right
- Staggered start: 0ms, 100ms, 200ms
- Duration each: 400ms
- Curve: Ease-out

**Reduced Motion**:
- Instant display

---

### Weekly Graph

**Standard Motion**:
- Bars grow from bottom
- Staggered: 50ms delay per bar
- Duration: 400ms each
- Data points fade in

**Reduced Motion**:
- Instant display

---

## 7. Data State Changes

### List Item Add

**Standard Motion**:
- New item slides in from top/bottom
- Existing items shift with spring
- Duration: 300ms

**SwiftUI Implementation**:
```swift
ForEach(items) { item in
    ItemRow(item: item)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
}
.animation(.spring(response: 0.3, dampingFraction: 0.8), value: items)
```

**Reduced Motion**:
- Fade in only

---

### List Item Delete

**Standard Motion**:
- Swipe to reveal, then slide out
- Remaining items collapse with spring
- Duration: 250ms

**Reduced Motion**:
- Fade out, instant collapse

---

### Content Refresh

**Standard Motion**:
- Cross-fade between old and new content
- Duration: 200ms

**Reduced Motion**:
- Instant swap

---

## 8. Error & Alert Animations

### Error Shake

**Standard Motion**:
- Horizontal shake: -10, 10, -6, 6, -3, 0 offset
- Duration: 400ms
- Used for: invalid input, failed action

**SwiftUI Implementation**:
```swift
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}
```

**Reduced Motion**:
- Red border flash instead (no movement)

**Haptic**: Error notification feedback

---

### Toast Appear

**Standard Motion**:
- Slide up from bottom + fade
- Duration: 300ms
- Auto-dismiss: Slide down + fade

**Reduced Motion**:
- Fade only

---

### Alert Dialog

**Standard Motion**:
- Scale: 0.9 -> 1.0
- Opacity: 0 -> 1
- Background dim fade
- Duration: 200ms

**Reduced Motion**:
- Fade only (no scale)

---

## 9. Camera & Photo Animations

### Camera Open

**Standard Motion**:
- Full-screen slide up
- Camera preview fades in after transition
- Capture button scales in

**Reduced Motion**:
- Fade transition

---

### Photo Capture

**Standard Motion**:
- Screen flash (white overlay, 100ms)
- Captured image scales down to review position
- Duration: 400ms

**Reduced Motion**:
- No flash, instant transition

**Haptic**: Notification feedback (like camera shutter)

---

### AI Processing Overlay

**Standard Motion**:
- Circular progress on photo
- Gentle pulse effect on photo
- Results cards slide up as identified

**Reduced Motion**:
- Static progress indicator
- Results appear instantly when ready

---

## 10. Timing Reference

### Duration Guidelines

| Interaction Type | Duration |
|-----------------|----------|
| Micro-interaction (tap, toggle) | 150-200ms |
| UI element appearance | 200-300ms |
| Screen transition | 300-400ms |
| Complex animation (progress fill) | 400-600ms |
| Emphasis animation | 600-800ms |

### Easing Reference

| Curve | Use Case |
|-------|----------|
| **Ease-out** | Most UI (deceleration feels responsive) |
| **Ease-in** | Dismissals (acceleration) |
| **Ease-in-out** | Tab switches, cross-fades |
| **Spring** | Interactive elements, success states |
| **Linear** | Progress indicators, loading shimmers |

---

## 11. Haptic Feedback Map

| Action | Haptic Type |
|--------|-------------|
| Button tap | Light impact |
| Toggle switch | Light impact |
| Food logged | Medium impact |
| Favorite added | Light impact |
| Error | Notification (error) |
| Camera capture | Notification (success) |
| Slider value change | Selection |
| Swipe action reveal | Medium impact |
| Pull to refresh | Medium impact |
| Destructive action confirm | Heavy impact |

---

## 12. Performance Guidelines

### Frame Budget

- All animations MUST run at 60fps minimum
- Complex animations should use `drawingGroup()` in SwiftUI
- Avoid animating shadows directly (expensive)

### Memory

- Lottie animations: Keep under 100KB per animation
- Pre-render complex paths
- Reuse animation instances

### Battery

- Reduce animation complexity when Low Power Mode is on
- Stop background animations when app is backgrounded
- No infinite animations except loading states

### Testing

- Test on oldest supported device (iPhone XR)
- Test with Reduced Motion enabled
- Test with Low Power Mode enabled

---

*Document prepared by Agent 02: UX*
*Phase 3: Architecture*
