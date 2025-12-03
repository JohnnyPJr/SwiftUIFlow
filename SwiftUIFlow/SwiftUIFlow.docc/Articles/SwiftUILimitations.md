# SwiftUI Limitations

Known SwiftUI framework limitations and how SwiftUIFlow works around them.

## Overview

SwiftUIFlow is built on SwiftUI's NavigationStack, which has certain architectural limitations. Understanding these limitations helps you make informed decisions about your app's navigation architecture.

## Navigation Title Duplication During Deep Linking

### The Bug

When using `.navigationBarTitleDisplayMode(.automatic)` (the default), SwiftUI can render **both large and inline titles simultaneously** during deep linking or path building.

**From SwiftUI Community Reports:**
- Title duplication during programmatic navigation ([Stack Overflow](https://stackoverflow.com/questions/78731026/swiftui-navigationstack-title-is-duplicated-during-swipe-down-gesture))
- Inconsistent `.automatic` behavior across iOS versions ([Stack Overflow](https://stackoverflow.com/questions/79075633/different-navigationbartitledisplaymode-behaviour-between-ios-17-and-ios-18))
- Overlapping titles with `.large` mode ([Dabbling Badger](https://www.dabblingbadger.com/blog/2020/12/11/a-quick-fix-for-overlapping-navigation-titles-in-swiftui))

### What Happens

```swift
struct DeepView: View {
    var body: some View {
        VStack {
            Text("Content")
        }
        .navigationTitle("Deep View")
        // ❌ Using default .automatic mode
    }
}
```

**When deep linking through multiple screens rapidly:**

```swift
// Deep link builds path: [.level1, .level2, .level3, .level4]
coordinator.navigate(to: .level4)
```

**Symptom:** Title appears duplicated - both large title AND inline title render at the same time, with the duplicate floating and mispositioned.

### Why It Happens

SwiftUI's `.automatic` mode attempts to infer the correct title display mode from navigation context. During rapid synchronous pushes (path building), it becomes confused and renders BOTH `.large` and `.inline` titles simultaneously.

**Key Facts:**
- Only happens during **deep linking** (path building), NOT manual button taps
- Only happens with `.automatic` mode (the default)
- Dragging the view sometimes forces layout recalculation and the duplicate disappears
- This is a **known SwiftUI bug** in iOS 17+ (tested on iOS 18)

### The Solution

Always **explicitly specify** `.navigationBarTitleDisplayMode()` for views that might be reached via deep linking:

```swift
// ❌ DON'T - Relies on .automatic (default)
.navigationTitle("My Screen")

// ✅ DO - Explicit display mode
.navigationTitle("My Screen")
.navigationBarTitleDisplayMode(.large)  // or .inline

// ✅ ALTERNATIVE - Custom navigation bar (bypasses SwiftUI's title system)
.customNavigationBar(title: "My Screen", titleColor: .blue)
```

### When This Matters

This bug **only affects** views that:
1. Are part of a `navigationPath(for:)` array
2. Use `.navigationBarTitleDisplayMode(.automatic)` (the default)
3. Are navigated to via deep link (not manual button press)

**Regular navigation** (button taps, single pushes) works fine with `.automatic` because SwiftUI has time to settle between each navigation event.

### Best Practice

For any view in your coordinator-based app, always specify the title display mode:

```swift
struct MyView: View {
    var body: some View {
        ScrollView {
            // Content
        }
        .navigationTitle("My Screen")
        .navigationBarTitleDisplayMode(.large)  // ✅ Always explicit!
    }
}
```

## Custom Navigation Bar Layout Shift

### The Limitation

When using custom navigation bars (via `.customNavigationBar()` modifier), you may notice a brief layout shift when navigating to pushed child coordinators.
if the previous screen had no bar at all. e.g. a modal!

### What Happens

```swift
struct MyView: View {
    var body: some View {
        ScrollView {
            // Content
        }
        .customNavigationBar(title: "My Screen", titleColor: .red)
    }
}
```

**Symptom:** Content briefly appears under the navigation bar, then shifts down after navigation animation completes.

### Why It Happens

This is a **SwiftUI framework limitation** with how safe areas are calculated:

1. During navigation, SwiftUI hasn't finalized the safe area for the new view yet
2. Custom navigation bars use overlay/ZStack approach (don't integrate with safe area system)
3. After animation completes, SwiftUI recalculates safe areas
4. Content shifts to respect the new safe area

**Not a Bug:**
- Affects iOS 17+ (tested on iOS 18)
- Affects all custom navigation bar implementations
- Native SwiftUI navigation bars work correctly (they're part of NavigationStack internals)

### Solutions

**Option 1: Use Native Navigation Bars for Pushed Children**

```swift
struct PushedChildView: View {
    var body: some View {
        ScrollView {
            // Content
        }
        .navigationTitle("My Screen")  // Native - no layout shift
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

**Option 2: Use Custom Bars Consistently**

Use `.customNavigationBar()` throughout your entire navigation flow. The shift only happens on the transition between native and custom:

```swift
// ✅ Consistent - no shift between screens
struct RootView: View {
    var body: some View {
        VStack {
            // Content
        }
        .customNavigationBar(title: "Root", titleColor: .blue)
    }
}

struct ChildView: View {
    var body: some View {
        VStack {
            // Content
        }
        .customNavigationBar(title: "Child", titleColor: .blue)
    }
}
```

## Best Practices

### 1. Trust the Framework's Architecture

SwiftUIFlow's flattened navigation architecture is **not a workaround** - it's the correct way to work with SwiftUI's NavigationStack:

✅ Aligns with Apple's intended usage
✅ Prevents navigation bugs
✅ Enables advanced features (modals from children, detours, etc.)

### 2. Don't Try to Nest NavigationStacks

Never attempt to create nested NavigationStacks manually:

```swift
// ❌ Don't do this - won't work
struct MyCoordinatorView: View {
    var body: some View {
        NavigationStack {  // Don't create your own NavigationStack
            // when already inside one
        }
    }
}

// ✅ Use the framework's CoordinatorView
struct MyCoordinatorView: View {
    var body: some View {
        CoordinatorView(coordinator: myCoordinator)
    }
}
```

### 3. Modal and Detour Coordinators Are Fine

Modal and detour coordinators **can** have their own NavigationStack because they're presented, not pushed:

```swift
// ✅ This works - modal is presented, not pushed
.sheet(isPresented: $showModal) {
    NavigationStack {  // ✅ OK - presented as sheet
        ModalCoordinatorView(coordinator: modalCoordinator)
    }
}

// ✅ This works - detour is presented, not pushed
.fullScreenCover(isPresented: $showDetour) {
    NavigationStack {  // ✅ OK - presented as fullScreenCover
        DetourCoordinatorView(coordinator: detourCoordinator)
    }
}
```

### 4. Choose Your Navigation Bar Strategy

Decide early whether to use native or custom navigation bars:

- **Native bars** - Zero layout issues, standard Apple design
- **Custom bars** - Full design control, no issues if applied everywhere in stacks

## See Also

- <doc:NavigationPatterns>
- <doc:ImportantConcepts>
- ``CoordinatorView``
