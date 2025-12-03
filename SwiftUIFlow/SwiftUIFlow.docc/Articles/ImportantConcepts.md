# Important Concepts and Best Practices

Critical patterns, constraints, and special cases you need to know when using SwiftUIFlow.

## Overview

This guide covers essential concepts that are crucial for correctly implementing SwiftUIFlow in your app. Understanding these patterns will help you avoid common pitfalls and build robust navigation flows.

## Modal Coordinator Type Constraints

### ⚠️ Modal Coordinators Must Share Parent's Route Type

**Critical Rule:** Modal coordinators must be `Coordinator<R>` where `R` is the **same route type** as the parent coordinator.

```swift
// Parent uses AppRoute
class AppCoordinator: Coordinator<AppRoute> {
    let settingsModal: SettingsCoordinator

    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .home, factory: factory))
        factory.coordinator = self

        // ✅ CORRECT: SettingsCoordinator also uses AppRoute
        settingsModal = SettingsCoordinator()
        addModalCoordinator(settingsModal)
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is AppRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let appRoute = route as? AppRoute else { return .push }
        switch appRoute {
        case .home, .profile:
            return .push
        case .settings:
            return .modal  // Framework finds settingsModal coordinator
        }
    }
}

// Modal coordinator MUST use same route type
class SettingsCoordinator: Coordinator<AppRoute> {  // ← Same AppRoute!
    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .settings, factory: factory))
        factory.coordinator = self
    }
    // No overrides needed if no child routes!
}
```

**Why This Constraint Exists:**

The framework finds modal coordinators by matching the root route:
```swift
// When you navigate to .settings:
// 1. Parent returns .modal from navigationType(for: .settings)
// 2. Framework searches modalCoordinators for one with root = .settings
// 3. Presents that modal coordinator
```

If modal coordinator used a different route type, the framework couldn't match routes!

### Detour Coordinators Have No Type Constraint

Unlike modals, detours can use **any route type**:

```swift
class AppCoordinator: Coordinator<AppRoute> {
    func handleDeepLink() {
        // ✅ ProfileCoordinator can use ProfileRoute (different type!)
        let profile = ProfileCoordinator()  // Uses ProfileRoute
        presentDetour(profile, presenting: .profile)
    }
}
```

**Why:** Detours are explicitly presented via `presentDetour()`, not through route matching.

## canHandle() vs Modal Coordinator Ownership

### The Critical Rule

**A coordinator should only `canHandle()` routes for which it has the modal coordinator configured in its own `modalCoordinators` array.**

### Common Mistake: Claiming Too Much

```swift
// ❌ WRONG - ParentCoordinator claims routes it doesn't own
enum AppRoute: Route {
    case home
    case settings
    case modal         // Owned by ParentCoordinator
    case nestedModal   // Owned by ModalCoordinator (NOT ParentCoordinator!)
}

class ParentCoordinator: Coordinator<AppRoute> {
    let modalCoordinator: ModalCoordinator

    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .home, factory: factory))
        factory.coordinator = self

        // Register modalCoordinator
        modalCoordinator = ModalCoordinator()
        addModalCoordinator(modalCoordinator)
    }

    override func canHandle(_ route: any Route) -> Bool {
        // ❌ TOO BROAD! Claims to handle ALL AppRoutes
        return route is AppRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let appRoute = route as? AppRoute else { return .push }
        switch appRoute {
        case .home, .settings:
            return .push
        case .modal:
            return .modal  // Presents modalCoordinator
        case .nestedModal:
            return .modal  // ❌ Will fail! No nestedModalCoordinator here!
        }
    }
}

class ModalCoordinator: Coordinator<AppRoute> {
    let nestedModalCoordinator: NestedModalCoordinator

    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .modal, factory: factory))
        factory.coordinator = self

        // Register NESTED modal coordinator
        nestedModalCoordinator = NestedModalCoordinator()
        addModalCoordinator(nestedModalCoordinator)
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let appRoute = route as? AppRoute else { return false }
        return appRoute == .modal || appRoute == .nestedModal
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let appRoute = route as? AppRoute else { return .push }
        switch appRoute {
        case .modal:
            return .push
        case .nestedModal:
            return .modal  // Presents nestedModalCoordinator
        default:
            return .push
        }
    }
}

class NestedModalCoordinator: Coordinator<AppRoute> {
    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .nestedModal, factory: factory))
        factory.coordinator = self
    }
}
```

**What Goes Wrong:**

When you call `coordinator.navigate(to: .nestedModal)` from anywhere:

1. **ParentCoordinator checks** `canHandle(.nestedModal)` → returns `true` (route is AppRoute ❌)
2. **ParentCoordinator tries** `navigationType(.nestedModal)` → returns `.modal`
3. **Framework searches** `ParentCoordinator.modalCoordinators` for coordinator with root = `.nestedModal`
4. **Framework finds nothing!** `nestedModalCoordinator` is in `ModalCoordinator.modalCoordinators`, not here!
5. **Navigation fails** with "Modal coordinator not found" error ❌

**The Root Cause:**

`ParentCoordinator` claims ownership of `.nestedModal` via `canHandle()`, but doesn't have the modal coordinator to present it!

### Correct Approach: Exclude Nested Modals

```swift
// ✅ CORRECT - ParentCoordinator only claims routes it owns
class ParentCoordinator: Coordinator<AppRoute> {
    let modalCoordinator: ModalCoordinator

    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .home, factory: factory))
        factory.coordinator = self

        modalCoordinator = ModalCoordinator()
        addModalCoordinator(modalCoordinator)
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let appRoute = route as? AppRoute else { return false }

        // ✅ Only handle routes with modal coordinators in OUR array
        switch appRoute {
        case .home, .settings, .modal:
            return true  // We own these routes
        case .nestedModal:
            return false  // ✅ Let modalCoordinator handle it
        }
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let appRoute = route as? AppRoute else { return .push }
        switch appRoute {
        case .home, .settings:
            return .push
        case .modal:
            return .modal  // ✅ Presents modalCoordinator (we have it!)
        case .nestedModal:
            return .push  // Won't be called - we don't handle this route
        }
    }
}

// ModalCoordinator only handles .nestedModal (parent owns .modal!)
class ModalCoordinator: Coordinator<AppRoute> {
    let nestedModalCoordinator: NestedModalCoordinator

    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .modal, factory: factory))
        factory.coordinator = self

        // ✅ Register nested modal coordinator in OUR array
        nestedModalCoordinator = NestedModalCoordinator()
        addModalCoordinator(nestedModalCoordinator)
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let appRoute = route as? AppRoute else { return false }
        // ✅ We only own .nestedModal (parent owns .modal!)
        return appRoute == .nestedModal
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let appRoute = route as? AppRoute else { return .push }
        switch appRoute {
        case .nestedModal:
            return .modal  // ✅ Presents nestedModalCoordinator (we have it!)
        default:
            return .push
        }
    }
}

class NestedModalCoordinator: Coordinator<AppRoute> {
    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .nestedModal, factory: factory))
        factory.coordinator = self
    }
}
```

**What Happens Now:**

When you call `coordinator.navigate(to: .nestedModal)`:

1. **ParentCoordinator checks** `canHandle(.nestedModal)` → returns `false` ✅
2. **Framework delegates** to `ParentCoordinator.modalCoordinators`
3. **Framework asks** `modalCoordinator.canHandle(.nestedModal)` → returns `true` ✅
4. **Framework presents** `modalCoordinator` as a modal
5. **ModalCoordinator navigates** to `.nestedModal` internally
6. **ModalCoordinator checks** `navigationType(.nestedModal)` → returns `.modal`
7. **ModalCoordinator presents** `nestedModalCoordinator` ✅

**Result:** Navigation succeeds! The framework correctly delegates through the modal hierarchy.

## Navigation Path Building for Modals

### When to Use navigationPath(for:)

Use `navigationPath(for:)` when a modal requires specific **parent state** before it can be presented.

**Example:** Modal presented from level 3 of a multi-level flow:

```swift
class ParentCoordinator: Coordinator<ParentRoute> {
    override func navigationPath(for route: any Route) -> [any Route]? {
        if let parentRoute = route as? ParentRoute {
            switch parentRoute {
            case .level1:
                return nil  // Root, no path needed
            case .level2:
                return [.level1, .level2]
            case .level3:
                return [.level1, .level2, .level3]
            case .level3Modal:
                // Modal needs level3 to be displayed first
                return [.level1, .level2, .level3]  // ← Path to prerequisite state
            }
        }

        // For routes handled by descendants (e.g., pushed child in modal)
        if route is ChildRoute {
            // Child is in modal presented from level 3
            return [.level1, .level2, .level3]
        }

        return nil
    }
}
```

**What Happens:**

When deep linking to `.level3Modal`:
1. Framework checks if path needed (only if `stack.isEmpty`)
2. Builds path: pushes `.level1`, `.level2`, `.level3`
3. **Checks if target route is in path:**
   - If YES: Done (path includes destination)
   - If NO: Falls through to present modal
4. Presents modal from correct state (level 3)

### Path Must Not Include Modal Routes

```swift
// ❌ WRONG
override func navigationPath(for route: any Route) -> [any Route]? {
    if route.identifier == "deepRoute" {
        return [.level1, .modalRoute, .level2]  // ❌ Path contains modal!
    }
    return nil
}
```

**Rule:** Paths can only contain `.push` or `.replace` routes. Modal presentation happens AFTER path building.

## Replace Navigation Type

### What Replace Does

`.replace` pops the current route, then pushes the new route:

```swift
override func navigationType(for route: WorkflowRoute) -> NavigationType {
    switch route {
    case .loading:
        return .push
    case .success, .failure:
        return .replace  // ← Replace loading screen
    }
}
```

**Navigation Flow:**
1. User at: Home → Loading
2. Call `navigate(to: .success)`
3. Framework replaces Loading with Success
4. Back button returns to Home (not Loading)

### When to Use Replace

✅ Use `.replace` for:
- Multi-step flows where intermediate steps shouldn't be in back stack
- Success/failure screens replacing loading screens
- Workflow completion replacing progress screens

❌ Don't use `.replace` for:
- Regular navigation (use `.push`)
- Modal presentation (use `.modal`)
- Going back (framework handles automatically)

## Detour Navigation Pattern

### Why Detours Exist

**Problem:** Deep linking across coordinators normally cleans navigation state:

```swift
// User is deep in a flow:
Tab2 → UnlockCoordinator → EnterCode → Loading → Failure

// Deep link arrives: Navigate to ProfileSettings
// Problem: Bubbling to parent cleans Unlock flow state
// User can't return to Failure screen!
```

**Solution:** Present deep link as detour to preserve context:

```swift
class AppCoordinator: Coordinator<AppRoute> {
    func handleDeepLink(to route: any Route) {
        // Present as fullscreen detour
        let profileCoordinator = ProfileCoordinator()
        presentDetour(profileCoordinator, presenting: .settings)

        // When user taps back, they return to Failure screen ✅
    }
}
```

### Critical Rules for Detours

1. **Always present explicitly:**
   ```swift
   // ✅ CORRECT
   presentDetour(coordinator, presenting: route)
   ```

2. **Back button automatically provided:**
   - Framework sets `canNavigateBack` environment value to `true`
   - Framework injects `navigationBackAction` to dismiss the detour
   - Custom navigation bars automatically show back buttons based on these environment values
   - Example app's `CustomNavigationBar` demonstrates this pattern

3. **Detours auto-dismiss during cross-flow navigation:**
   - No need for manual dismissal logic
   - Framework handles cleanup automatically

## View Factory Pattern

### The Three-Line Pattern

SwiftUIFlow uses a consistent pattern for coordinator initialization:

```swift
class AppCoordinator: Coordinator<AppRoute> {
    init() {
        let factory = AppViewFactory()  // 1. Create factory
        super.init(router: Router(initial: .home, factory: factory))  // 2. Pass to router
        factory.coordinator = self  // 3. Set coordinator reference
    }
}

class AppViewFactory: ViewFactory<AppRoute> {
    weak var coordinator: AppCoordinator?  // ← MUST be weak!

    override func buildView(for route: AppRoute) -> AnyView {
        guard let coordinator else {
            return AnyView(Text("Error: Coordinator not set"))
        }
        // Build views...
    }
}
```

**Critical:** Factory's `coordinator` property MUST be `weak` to avoid reference cycles.

## Smart Navigation Features

### Automatic Backward Detection

Framework automatically detects when you're navigating to an existing route:

```swift
// Current stack: [Home, Profile, Settings]
coordinator.navigate(to: .profile)
// Framework detects .profile is in stack
// Automatically pops to Profile (doesn't push again)
```

### Automatic Modal Dismissal

When navigating across coordinators, modals auto-dismiss:

```swift
// Tab1 → Profile (modal open)
coordinator.navigate(to: Tab2Route.settings)
// Framework automatically:
// 1. Dismisses Profile modal
// 2. Switches to Tab2
// 3. Navigates to Settings
```

### Tab Switching

Navigate to any tab's route from anywhere:

```swift
// From Tab1, navigate to Tab2's route:
coordinator.navigate(to: Tab2Route.details)
// Framework automatically:
// 1. Switches to Tab2
// 2. Navigates within Tab2 to details
```

## Environment Values for Custom Back Buttons

### Using navigationBackAction

If you need custom back button UI:

```swift
struct CustomView: View {
    @Environment(\.navigationBackAction) var backAction
    @Environment(\.canNavigateBack) var canNavigateBack

    var body: some View {
        VStack {
            // Your content

            if canNavigateBack {
                Button("← Go Back") {
                    backAction?()  // Framework provides correct action
                }
            }
        }
    }
}
```

**Framework automatically injects the correct back action based on:**
- Push navigation → Pops from navigation stack
- Modal → Dismisses modal
- Detour → Dismisses detour

## Common Pitfalls

### 1. Forgetting to Register Modal Coordinators

```swift
// ❌ WRONG - Modal coordinator not registered
class AppCoordinator: Coordinator<AppRoute> {
    let modal = ModalCoordinator()

    override func navigationType(for route: AppRoute) -> NavigationType {
        if route == .settings {
            return .modal  // Will fail! Modal not registered
        }
        return .push
    }
}

// ✅ CORRECT - Register the modal
class AppCoordinator: Coordinator<AppRoute> {
    let modal = ModalCoordinator()

    init() {
        // ...
        addModalCoordinator(modal)  // ← Register it!
    }
}
```

### 2. Modal Coordinator Using Wrong Route Type

```swift
// ❌ WRONG - Type mismatch
class AppCoordinator: Coordinator<AppRoute> {
    init() {
        // SettingsCoordinator uses SettingsRoute (different type!)
        let modal = SettingsCoordinator()  // Type: Coordinator<SettingsRoute>
        addModalCoordinator(modal)  // ❌ Compile error!
    }
}

// ✅ CORRECT - Same route type
class SettingsCoordinator: Coordinator<AppRoute> {  // ← Same type!
    init() {
        super.init(router: Router(initial: .settings, factory: ...))
    }
}
```

### 3. Including Modal Routes in Navigation Paths

```swift
// ❌ WRONG - Path contains modal
override func navigationPath(for route: any Route) -> [any Route]? {
    return [.level1, .modalRoute, .level2]  // Error!
}

// ✅ CORRECT - Path only has push/replace routes
override func navigationPath(for route: any Route) -> [any Route]? {
    return [.level1, .level2, .level3]  // ← Only prerequisites
}
```

### 4. Router Methods Are Internal

All router mutation methods are **internal** - clients cannot access them:

```swift
// ❌ WRONG - All these are internal, compile error!
coordinator.router.push(route)
coordinator.router.pop()
coordinator.router.replace(route)
coordinator.router.setRoot(route)
coordinator.router.pushChild(childCoordinator)

// ✅ CORRECT - Use coordinator's public API
coordinator.navigate(to: route)  // For all navigation

// For FlowOrchestrator only (flow transitions):
flowOrchestrator.transitionToFlow(newCoordinator, root: route)
```

The router is publicly accessible for **reading state** via `@ObservedObject`, but mutation is internal to the framework.

## See Also

- <doc:GettingStarted>
- <doc:NavigationPatterns>
- ``Coordinator``
- ``Router``
- ``ViewFactory``
