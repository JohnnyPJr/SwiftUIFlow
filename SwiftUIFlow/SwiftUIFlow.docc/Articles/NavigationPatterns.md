# Navigation Patterns

Advanced navigation patterns and best practices for complex SwiftUIFlow applications.

## Overview

SwiftUIFlow supports sophisticated navigation patterns beyond basic push and modal flows. This guide covers advanced scenarios like hierarchical coordinators, cross-coordinator navigation, tab coordination, and deep linking.

## Hierarchical Coordinators

### Child Coordinators

Child coordinators manage sub-flows within your app. Each coordinator has its own route type and manages its own navigation.

**Example: Red tab coordinator with Rainbow child coordinator**

```swift
// Parent routes (Red tab)
enum RedRoute: Route {
    case red
    case lightRed
    case darkRed
    case info

    var identifier: String {
        switch self {
        case .red: return "red"
        case .lightRed: return "lightRed"
        case .darkRed: return "darkRed"
        case .info: return "info"
        }
    }
}

// Child routes (completely separate type!)
enum RainbowRoute: Route {
    case red, orange, yellow, green, blue, purple

    var identifier: String {
        switch self {
        case .red: return "rainbow_red"
        case .orange: return "rainbow_orange"
        case .yellow: return "rainbow_yellow"
        case .green: return "rainbow_green"
        case .blue: return "rainbow_blue"
        case .purple: return "rainbow_purple"
        }
    }
}

// Child coordinator manages RainbowRoute
class RainbowCoordinator: Coordinator<RainbowRoute> {
    init() {
        let factory = RainbowViewFactory()
        super.init(router: Router(initial: .red, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is RainbowRoute
    }
    // No need to override navigationType if all routes use default (.push)
}

// Modal coordinators for .darkRed and .info routes
class RedModalCoordinator: Coordinator<RedRoute> {
    init() {
        let factory = RedViewFactory()
        super.init(router: Router(initial: .darkRed, factory: factory))
        factory.coordinator = self
    }
    // No overrides needed - just displays .darkRed view
}

class RedInfoCoordinator: Coordinator<RedRoute> {
    init() {
        let factory = RedViewFactory()
        super.init(router: Router(initial: .info, factory: factory))
        factory.coordinator = self
    }
    // No overrides needed - just displays .info view
}

// Parent coordinator adds child and registers modal coordinators
class RedCoordinator: Coordinator<RedRoute> {
    let darkRedModal: RedModalCoordinator
    let infoModal: RedInfoCoordinator
    let rainbowCoordinator: RainbowCoordinator

    init() {
        let factory = RedViewFactory()
        super.init(router: Router(initial: .red, factory: factory))
        factory.coordinator = self

        // Register modal coordinators (MUST be registered before use!)
        darkRedModal = RedModalCoordinator()
        addModalCoordinator(darkRedModal)

        infoModal = RedInfoCoordinator()
        addModalCoordinator(infoModal)

        // Add child coordinator
        rainbowCoordinator = RainbowCoordinator()
        addChild(rainbowCoordinator)
    }

    override func canHandle(_ route: any Route) -> Bool {
        // Parent handles all RedRoute (including modal routes)
        return route is RedRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let redRoute = route as? RedRoute else { return .push }
        switch redRoute {
        case .red, .lightRed:
            return .push
        case .darkRed, .info:
            return .modal  // Framework finds corresponding modal coordinator
        }
    }
}
```

**Navigation Flow:**

When you call `navigate(to: RainbowRoute.orange)`:
1. **Parent checks** `canHandle(RainbowRoute.orange)` → returns `false` (not RedRoute)
2. **Framework delegates to children** via `delegateToChildren()`
3. **Framework asks child** `rainbowCoordinator.canNavigate(to: RainbowRoute.orange)` → returns `true`
4. **Framework pushes child** `router.pushChild(rainbowCoordinator)` onto parent's navigation stack
5. **Framework delegates** `rainbowCoordinator.navigate(to: .orange)`
6. **Child handles navigation** and displays orange view

**From RedView:**

```swift
struct RedView: View {
    let coordinator: RedCoordinator

    var body: some View {
        VStack {
            Text("Red Screen")

            Button("Explore Rainbow") {
                // Navigate to child coordinator's route
                coordinator.navigate(to: RainbowRoute.orange)
            }
        }
    }
}
```

The framework automatically:
- Determines RainbowCoordinator should handle the route
- Pushes RainbowCoordinator onto the navigation stack
- Shows RainbowCoordinator's orange view
- Provides back button to return to RedView

## Modal Coordinators

### Multiple Modal Coordinators

Register multiple modal coordinators for different modal flows:

```swift
class ParentCoordinator: Coordinator<ParentRoute> {
    let settingsModalCoordinator: SettingsCoordinator
    let profileModalCoordinator: ProfileCoordinator

    init() {
        let factory = ParentViewFactory()
        super.init(router: Router(initial: .home, factory: factory))
        factory.coordinator = self

        // Register modal coordinators
        settingsModalCoordinator = SettingsCoordinator()
        addModalCoordinator(settingsModalCoordinator)

        profileModalCoordinator = ProfileCoordinator()
        addModalCoordinator(profileModalCoordinator)
    }

    override func navigationType(for route: ParentRoute) -> NavigationType {
        switch route {
        case .settings:
            return .modal // Presents settingsModalCoordinator
        case .profile:
            return .modal // Presents profileModalCoordinator
        default:
            return .push
        }
    }
}
```

The framework:
- Finds the correct modal coordinator by matching root routes
- Presents only one modal at a time
- Auto-dismisses modals during cross-flow navigation

### Modal Detents

Customize sheet height using `modalDetentConfiguration`. SwiftUIFlow supports six detent types:

```swift
override func modalDetentConfiguration(for route: RedRoute) -> ModalDetentConfiguration {
    guard let redRoute = route as? RedRoute else {
        return ModalDetentConfiguration(detents: [.large])
    }

    switch redRoute {
    case .info:
        // Content-sized sheet (automatic height!)
        return ModalDetentConfiguration(
            detents: [.custom, .medium],
            selectedDetent: .custom
        )
    case .darkRed:
        // User can drag between sizes
        return ModalDetentConfiguration(
            detents: [.medium, .large]
        )
    default:
        return ModalDetentConfiguration(detents: [.large])
    }
}
```

**Available Detents:**

- `.small` - Minimal height (e.g., header only)
- `.medium` - ~50% screen height (native SwiftUI)
- `.large` - 99.9% screen height
- `.extraLarge` - 100% screen height (still a sheet)
- `.fullscreen` - True fullscreen cover presentation
- **`.custom`** - ✨ **Automatic content-based sizing**

**The `.custom` Detent - Automatic Sizing**

This is a SwiftUIFlow feature! The framework automatically measures your modal content and sizes the sheet to fit:

```swift
// Just specify .custom - framework handles the rest!
ModalDetentConfiguration(detents: [.custom])
```

No manual height calculations needed! The sheet automatically adjusts to your content.

**Important: Text Requires `.fixedSize()`**

When using `.custom` detent with multiline text, you must add `.fixedSize(horizontal: false, vertical: true)`:

```swift
struct InfoModalContent: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("This is a long multiline text that needs to display fully...")
                .fixedSize(horizontal: false, vertical: true)  // ← Required!

            Text("Another text block...")
                .fixedSize(horizontal: false, vertical: true)  // ← Required!
        }
        .padding()
    }
}
```

**Why is this needed?**

SwiftUI has a measurement challenge:
1. Framework measures content to determine sheet height
2. During measurement, content is in a constrained context
3. Without `.fixedSize()`, Text compresses to one line with "..." truncation
4. With `.fixedSize(vertical: true)`, Text expands to its natural height

**This is standard SwiftUI behavior**, not a framework limitation. Many design systems build `.fixedSize()` into their text components automatically.

### Pushed Children in Modals and Detours

**Modal and detour coordinators support full navigation stacks** - you can push child coordinators inside them just like any other coordinator.

```swift
// Modal coordinator with pushed child
class SettingsCoordinator: Coordinator<SettingsRoute> {
    let privacyCoordinator: PrivacyCoordinator  // Child coordinator

    init() {
        let factory = SettingsViewFactory()
        super.init(router: Router(initial: .main, factory: factory))
        factory.coordinator = self

        // Add child coordinator - can be pushed in the modal's navigation stack
        privacyCoordinator = PrivacyCoordinator()
        addChild(privacyCoordinator)
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is SettingsRoute
    }
}

// From within the modal, navigate to child
struct SettingsMainView: View {
    let coordinator: SettingsCoordinator

    var body: some View {
        List {
            Button("Privacy Settings") {
                // Pushes PrivacyCoordinator onto modal's navigation stack
                coordinator.navigate(to: PrivacyRoute.overview)
            }
        }
    }
}
```

**How It Works:**

Modal and detour coordinators are **presented** (via `.sheet()` or `.fullScreenCover()`), not pushed. This means:

1. **Modal/detour has its own NavigationStack** - Not nested inside parent's NavigationStack
2. **Can push children freely** - SwiftUI's nested NavigationStack limitation doesn't apply
3. **Full navigation capabilities** - Push, pop, replace, even present nested modals
4. **Back navigation works perfectly** - Each modal/detour manages its own navigation state

**Example: Multi-Level Modal Flow**

```swift
// Detour coordinator with complex navigation
class OnboardingCoordinator: Coordinator<OnboardingRoute> {
    let profileSetupCoordinator: ProfileSetupCoordinator
    let notificationSetupModal: NotificationSetupCoordinator

    init() {
        let factory = OnboardingViewFactory()
        super.init(router: Router(initial: .welcome, factory: factory))
        factory.coordinator = self

        // Pushed child - can navigate through profile setup flow
        profileSetupCoordinator = ProfileSetupCoordinator()
        addChild(profileSetupCoordinator)

        // Nested modal - can present modal from within detour
        notificationSetupModal = NotificationSetupCoordinator()
        addModalCoordinator(notificationSetupModal)
    }
}
```

**Navigation Hierarchy:**

```
AppCoordinator (root NavigationStack)
├─ Present Detour: OnboardingCoordinator (fullScreenCover - has own NavigationStack)
│  ├─ Root: .welcome
│  ├─ Push: ProfileSetupCoordinator (pushed child)
│  │  ├─ .step1
│  │  ├─ .step2
│  │  └─ .step3
│  └─ Present Modal: NotificationSetupCoordinator (sheet - has own NavigationStack)
│     ├─ .permissions
│     └─ .preferences
```

**Key Insight:**

The SwiftUI limitation is about **nested NavigationStacks inside `.navigationDestination`**. But modals and detours use **`.sheet()` and `.fullScreenCover()`**, which can each have their own NavigationStack without issues!

## Tab-Based Navigation

### TabCoordinator Setup

Use ``TabCoordinator`` for tab-based apps. Each child coordinator becomes a tab and should override `tabItem` to provide tab appearance:

```swift
// Child coordinators define their tab appearance
class RedCoordinator: Coordinator<RedRoute> {
    init() {
        let factory = RedViewFactory()
        super.init(router: Router(initial: .red, factory: factory))
        factory.coordinator = self
    }

    override var tabItem: (text: String, image: String)? {
        return ("Red", "paintpalette.fill")
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is RedRoute
    }
}

class GreenCoordinator: Coordinator<GreenRoute> {
    init() {
        let factory = GreenViewFactory()
        super.init(router: Router(initial: .green, factory: factory))
        factory.coordinator = self
    }

    override var tabItem: (text: String, image: String)? {
        return ("Green", "leaf.fill")
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is GreenRoute
    }
}

// TabCoordinator manages all tabs
class MainTabCoordinator: TabCoordinator<AppRoute> {
    let redCoordinator: RedCoordinator
    let greenCoordinator: GreenCoordinator
    let blueCoordinator: BlueCoordinator

    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .tabRoot, factory: factory))
        factory.coordinator = self

        // Add child coordinators as tabs
        redCoordinator = RedCoordinator()
        addChild(redCoordinator)

        greenCoordinator = GreenCoordinator()
        addChild(greenCoordinator)

        blueCoordinator = BlueCoordinator()
        addChild(blueCoordinator)
    }

}
```

 ⚠️ IMPORTANT: Don't override canHandle() in TabCoordinator!
 TabCoordinator should ONLY delegate to children, never handle routes directly
 If you override canHandle() to return true, you break delegation

**Critical Pattern: TabCoordinator Delegation**

`TabCoordinator` is **purely a delegating coordinator** - it should never handle routes directly. The default `canHandle()` implementation returns `false`, which triggers the framework's delegation logic:

```swift
// ✅ CORRECT - Don't override canHandle()
class MainTabCoordinator: TabCoordinator<AppRoute> {
    // No canHandle() override - returns false by default
    // Framework delegates all routes to child coordinators
}

// ❌ WRONG - Overriding canHandle() breaks delegation
class MainTabCoordinator: TabCoordinator<AppRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        return route is AppRoute  // DON'T DO THIS!
    }
    // Problem: TabCoordinator tries to handle routes itself
    // instead of delegating to children
}
```

**Why This Pattern?**

When you call `coordinator.navigate(to: RedRoute.lightRed)`:
1. **TabCoordinator checks** `canHandle(RedRoute.lightRed)` → returns `false`
2. **Framework delegates** to children via tab switching logic
3. **Framework asks each child** until it finds `redCoordinator.canHandle(RedRoute.lightRed)` → `true`
4. **Framework switches** to Red tab automatically
5. **Red coordinator** handles the navigation

If `TabCoordinator.canHandle()` returned `true`, it would try to handle routes itself instead of delegating to children!


### Rendering Tabs with TabCoordinatorView

SwiftUIFlow provides ``TabCoordinatorView`` as a **convenience view** that renders your tabs using native `TabView`:

```swift
@main
struct MyApp: App {
    let tabCoordinator = MainTabCoordinator()

    var body: some Scene {
        WindowGroup {
            TabCoordinatorView(coordinator: tabCoordinator)
        }
    }
}
```

``TabCoordinatorView`` automatically:
- Creates a native `TabView` with tabs for each child coordinator
- Uses each coordinator's `tabItem` for tab labels and icons
- Syncs tab selection with coordinator state
- Preserves all navigation capabilities (modals, detours, navigation stacks)

### Custom Tab Bar Options

``TabCoordinatorView`` is **completely optional**! You can build custom tab bar UIs with any design. Choose your approach:

#### Option 1: CustomTabCoordinatorView Wrapper (Recommended)

Use ``CustomTabCoordinatorView`` for automatic modal/detour support:

```swift
struct MyApp: App {
    let coordinator = MainTabCoordinator()

    var body: some Scene {
        WindowGroup {
            CustomTabCoordinatorView(coordinator: coordinator) {
                CustomTabBarUI(coordinator: coordinator)
            }
        }
    }
}

struct CustomTabBarUI: View {
    let coordinator: MainTabCoordinator
    @ObservedObject private var router: Router<AppRoute>

    init(coordinator: MainTabCoordinator) {
        self.coordinator = coordinator
        self.router = coordinator.router
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Render selected tab's content
            if router.state.selectedTab < coordinator.children.count {
                let child = coordinator.children[router.state.selectedTab]
                eraseToAnyView(child.buildCoordinatorView())
            }

            // Your custom tab bar design
            customTabBar
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(coordinator.children.enumerated()), id: \.offset) { index, child in
                if let item = child.tabItem {
                    Button(action: { coordinator.switchToTab(index) }) {
                        VStack {
                            Image(systemName: item.image)
                            Text(item.text)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
```

**Benefits:**
- ✅ Automatic modal/detour support - impossible to forget!
- ✅ Cleaner code - wrapper handles presentation complexity
- ✅ Full design freedom

#### Option 2: Manual Modifier (Advanced)

For fine-grained control over presentation layering:

```swift
struct CustomTabBarUI: View {
    let coordinator: MainTabCoordinator
    @ObservedObject private var router: Router<AppRoute>

    var body: some View {
        ZStack(alignment: .bottom) {
            // Render selected tab's content
            if router.state.selectedTab < coordinator.children.count {
                let child = coordinator.children[router.state.selectedTab]
                eraseToAnyView(child.buildCoordinatorView())
            }

            // Your custom tab bar design
            customTabBar
        }
        .withTabCoordinatorPresentations(coordinator: coordinator)
    }
}
```

**When to use:**
- Need custom presentation layer ordering
- Complex view hierarchies with multiple modifiers
- Integration with other custom modifiers that must be ordered specifically

#### Custom Tab Bar Capabilities

Regardless of which option you choose:
- Access tabs via `coordinator.children`
- Read selected tab via `coordinator.router.state.selectedTab`
- Switch tabs via `coordinator.switchToTab(index)`
- Render each tab using `child.buildCoordinatorView()`
- Create any design: floating tabs, sidebars, custom animations, etc.

### Cross-Tab Navigation

Navigate to routes in other tabs:

```swift
// From Red tab, navigate to Green tab's route
coordinator.navigate(to: GreenRoute.settings)
```

The framework automatically:
- Switches to the correct tab
- Navigates within that tab's coordinator
- Dismisses any open modals

## Deep Linking with Navigation Paths

### Building Navigation Paths

For routes that require specific parent state, override `navigationPath(for:)`:

```swift
class DeepBlueCoordinator: Coordinator<DeepBlueRoute> {
    override func navigationPath(for route: any Route) -> [any Route]? {
        if let deepBlueRoute = route as? DeepBlueRoute {
            switch deepBlueRoute {
            case .level1:
                return nil // Root, no path needed
            case .level2:
                return [.level1, .level2]
            case .level3:
                return [.level1, .level2, .level3]
            case .level3Modal:
                // Modal needs level3 to be displayed first
                return [.level1, .level2, .level3]
            }
        }

        // Handle routes from descendant coordinators
        if route is OceanRoute {
            // Ocean is in nested modal, needs level3 first
            return [.level1, .level2, .level3]
        }

        return nil
    }
}
```

When deep linking to `.level3Modal`:
1. Framework checks if path is needed (`stack.isEmpty`)
2. Builds path: pushes `.level1`, `.level2`, `.level3`
3. Presents modal from level 3

## Handling External Deep Links

External triggers (push notifications, universal links, app links, URL schemes) require special handling. You have two options:

### Option 1: Navigate (Cleans State)

Use `navigate(to:)` when the user should lose their current context:

```swift
class DeepLinkHandler {
    static func handleMarketingLink(to route: any Route) {
        guard let mainTab = appCoordinator.currentFlow as? MainTabCoordinator else { return }

        // Dismisses modals, cleans stacks, navigates to destination
        // User loses their previous context
        mainTab.navigate(to: route)
    }
}
```

**When to use:**
- Marketing deep links ("View this product")
- "Take me to X" scenarios
- User shouldn't return to previous context

### Option 2: Detour (Preserves State)

Use detours when the user should preserve their current context:

```swift
class DeepLinkHandler {
    static func handleNotification(to route: any Route) {
        guard let mainTab = appCoordinator.currentFlow as? MainTabCoordinator else { return }

        // User is deep in a flow: Tab2 → Unlock → EnterCode → Loading
        // Notification arrives: "You have a message"

        // Present message as detour - preserves ALL context underneath
        let messageCoordinator = MessageCoordinator(root: .message)
        mainTab.presentDetour(messageCoordinator, presenting: .message)

        // When user dismisses: returns to EXACT state (Loading screen)
    }
}
```

**When to use:**
- Push notifications ("You have a message")
- Temporary interruptions
- "Show me X, then let me continue" scenarios

**⚠️ Always present detours from a central location** (AppCoordinator or MainTabCoordinator), never from individual view coordinators. This ensures app-wide interruptions work correctly regardless of where the user currently is.

**Detour capabilities:**
- Present as fullscreen cover
- Preserve all underlying navigation state (modals, stacks, pushed children)
- Auto-dismiss during cross-flow navigation
- Support full navigation stacks within the detour

## Flow Transitions

### FlowOrchestrator

Use ``FlowOrchestrator`` for major app flow transitions (login → main app, onboarding → login, etc.):

```swift
// FlowOrchestrator manages transitions between major app flows
class AppCoordinator: FlowOrchestrator<AppRoute> {
    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .login, factory: factory))
        factory.coordinator = self

        // Start with login flow
        transitionToFlow(LoginCoordinator(), root: .login)
    }

    // ⚠️ IMPORTANT: Don't override canHandle() in FlowOrchestrator!
    // FlowOrchestrator should ONLY orchestrate flows, never handle routes directly
    override func canHandle(_ route: any Route) -> Bool {
        // FlowOrchestrator doesn't directly handle routes - it delegates to child flow coordinators
        return false
    }

    /// Check if this coordinator can handle flow changes (without executing them).
    /// Used during navigation validation to avoid side effects.
    override func canHandleFlowChange(to route: any Route) -> Bool {
        guard let appRoute = route as? AppRoute else { return false }
        return appRoute == .login || appRoute == .tabRoot
    }

    /// Handle flow changes when routes bubble to the root.
    /// This is called when LoginCoordinator or any child coordinator navigates
    /// to an AppRoute that they can't handle - it bubbles here for orchestration.
    override func handleFlowChange(to route: any Route) -> Bool {
        guard let appRoute = route as? AppRoute else { return false }

        switch appRoute {
        case .login:
            transitionToFlow(LoginCoordinator(), root: .login)
            return true
        case .tabRoot:
            transitionToFlow(MainTabCoordinator(), root: .tabRoot)
            return true
        }
    }
}

// Login flow coordinator
class LoginCoordinator: Coordinator<AppRoute> {
    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .login, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let appRoute = route as? AppRoute else { return false }
        return appRoute == .login
    }
}
```

**Critical Pattern: FlowOrchestrator Delegation**

Like `TabCoordinator`, `FlowOrchestrator` is **purely an orchestration layer** - it should never handle routes directly:

```swift
// ✅ CORRECT - canHandle() returns false
class AppCoordinator: FlowOrchestrator<AppRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        return false  // Delegates to current flow (LoginCoordinator, MainTabCoordinator, etc.)
    }

    override func canHandleFlowChange(to route: any Route) -> Bool {
        // Only validates flow transitions (no side effects!)
        guard let appRoute = route as? AppRoute else { return false }
        return appRoute == .login || appRoute == .tabRoot
    }
}

// ❌ WRONG - Overriding to return true breaks delegation
class AppCoordinator: FlowOrchestrator<AppRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        return route is AppRoute  // DON'T DO THIS!
    }
    // Problem: FlowOrchestrator tries to handle routes itself
    // instead of delegating to child flows
}
```

**Why Two Overrides?**

1. **`canHandle()`** - Always returns `false` to delegate to current flow coordinator
2. **`canHandleFlowChange()`** - Validates flow transitions during navigation validation (no side effects!)

### Integration with SwiftUI App

In your app, observe the root route to render the current flow:

```swift
@main
struct SwiftUIFlowExampleApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppRootView(appState: appState)
        }
    }
}

class AppState: ObservableObject {
    let appCoordinator: AppCoordinator

    init() {
        // AppCoordinator handles initialization internally
        // It starts at login and manages flow transitions via handleFlowChange
        appCoordinator = AppCoordinator()
    }
}

struct AppRootView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var router: Router<AppRoute>

    init(appState: AppState) {
        self.appState = appState
        router = appState.appCoordinator.router
    }

    var body: some View {
        // Observe router.state.root to rebuild when it changes
        let currentRoot = router.state.root

        // Dynamically render based on current root
        Group {
            switch currentRoot {
            case .tabRoot:
                // Render main app flow
                if let mainTabCoordinator = appState.appCoordinator.currentFlow as? MainTabCoordinator {
                    CustomTabBarView(coordinator: mainTabCoordinator)
                } else {
                    Text("Main app loading...")
                }
            case .login:
                // Render login flow
                if let loginCoordinator = appState.appCoordinator.currentFlow as? LoginCoordinator {
                    CoordinatorView(coordinator: loginCoordinator)
                } else {
                    Text("Login loading...")
                }
            }
        }
    }
}
```

**Navigation Flow:**

When user taps "Login" button in LoginView:
1. **LoginView calls** `coordinator.navigate(to: .tabRoot)`
2. **LoginCoordinator checks** `canHandle(.tabRoot)` → returns `false` (only handles `.login`)
3. **Framework bubbles** to parent (AppCoordinator)
4. **AppCoordinator validates** `canHandleFlowChange(.tabRoot)` → returns `true`
5. **AppCoordinator executes** `handleFlowChange(.tabRoot)` → transitions to MainTabCoordinator
6. **Framework updates** root route to `.tabRoot`
7. **AppRootView observes** root change → renders MainTabCoordinator with custom tab bar
8. **LoginCoordinator deallocated** (memory cleanup!)

``FlowOrchestrator`` automatically:
- Deallocates the old coordinator (memory management)
- Creates and presents the new coordinator
- Updates the root route (triggers UI rebuild)
- Manages the transition animation

## Best Practices

### 1. Keep Coordinators Focused

Each coordinator should manage a cohesive set of routes:

✅ Good: `OnboardingCoordinator` handles welcome, signup, login
❌ Bad: `MegaCoordinator` handles every route in your app

### 2. Use canHandle() Wisely

Return `true` only for routes this coordinator directly handles:

```swift
override func canHandle(_ route: AppRoute) -> Bool {
    // Only handle routes with modal coordinators configured
    guard let route = route as? DeepBlueRoute else { return false }
    return route != .nestedModal // Let modal coordinator handle it
}
```

### 3. Navigation Paths for Prerequisites

Use `navigationPath(for:)` when routes require specific parent state:

```swift
override func navigationPath(for route: any Route) -> [any Route]? {
    // Modal presented from level 3 needs path to level 3
    if route.identifier == "level3Modal" {
        return [.level1, .level2, .level3]
    }
    return nil
}
```

### 4. Explicit Detour Presentation

Always present detours explicitly using `presentDetour()`:

```swift
// ✅ Correct
presentDetour(coordinator, presenting: route)
```

## See Also

- ``Coordinator``
- ``TabCoordinator``
- ``FlowOrchestrator``
- ``Coordinator/navigationPath(for:)``
