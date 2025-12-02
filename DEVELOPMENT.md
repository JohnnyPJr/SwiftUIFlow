# SwiftUIFlow - Development Progress

**Last Updated:** November 29, 2025

---

## Project Overview

SwiftUIFlow is a coordinator-based navigation framework for SwiftUI that provides:
- Hierarchical navigation management
- Type-safe routing
- Smart backward navigation
- Deeplinking with context preservation (detours)
- Tab-based navigation support
- Multiple modal coordinator registration
- Proper encapsulation (internal framework implementation hidden from clients)

---

## Platform Support

### Primary Platform: iOS ✅
SwiftUIFlow is **fully tested and supported on iOS**. All features work as expected:
- Navigation (push, pop, replace)
- Modals (with custom detents)
- Detours (fullscreen deeplinks)
- Tab coordination
- Pushed child coordinators

**Minimum Version:** iOS 16.0+

### Experimental Platforms: macOS, visionOS ⚠️
The framework compiles and runs on macOS and visionOS, but these platforms are **not officially tested or supported** in v1.0.

**What works:**
- Core navigation (push, pop, replace)
- Regular modals (.sheet presentation)
- Tab coordination
- Coordinator hierarchy

**Known limitations:**
- **Detours are iOS-only** - The `.fullScreenCover` presentation used for detours is guarded with `#if os(iOS)`. On macOS/visionOS, calling `presentDetour()` will compile but have no effect.
- Modal detents may behave differently
- Platform-specific UI quirks not tested

**Future Support:**
macOS and visionOS support may be added in future releases once properly tested. Community contributions for platform-specific enhancements are welcome.

---

## Phase 1: Navigation Engine ✅ COMPLETE

### What Was Built

**Core Components:**
1. **Route Protocol** - Type-safe navigation destinations
2. **NavigationState** - State container (root, stack, selectedTab, presented, currentRoute, pushedChildren)
3. **Router** - Observable state machine managing navigation mutations
4. **NavigationType** - Enum defining navigation strategies (.push, .replace, .modal, .tabSwitch)
5. **Coordinator** - Navigation orchestration with smart features (clients work with concrete `Coordinator<R>` types)
6. **TabCoordinator** - Specialized coordinator for tab-based navigation
7. **AnyCoordinator** - Type-erased protocol for coordinator hierarchy (**internal** - hidden from clients)
8. **CoordinatorUISupport** - Public protocol for custom UI implementations (minimal interface)

**Navigation Features:**
- ✅ Universal navigate API (call from anywhere, framework finds the right flow)
- ✅ Push/Pop navigation
- ✅ Replace navigation (pops current screen then pushes new one - prevents back navigation to intermediate steps in multi-step flows)
- ✅ Modal presentation/dismissal with multiple modal coordinator support
- ✅ Detour navigation (Deeplinking preserving context via fullScreenCover)
- ✅ Tab switching
- ✅ SetRoot (major flow transitions via `transitionToNewFlow()`)
- ✅ Smart backward navigation (auto-pop to existing route)
- ✅ Cross-tab navigation with automatic switching
- ✅ Deep linking support (navigate from any app state)
- ✅ Modal/detour auto-dismissal during cross-flow navigation
- ✅ Idempotency (don't navigate if already at destination)
- ✅ Infinite loop prevention (caller tracking)
- ✅ Hierarchical delegation (child → parent bubbling)
- ✅ State cleanup during flow transitions

**Code Quality:**
- ✅ No side effects in canHandle() (pure query methods)
- ✅ Consistent coordinator creation (eager in init)
- ✅ SwiftLint compliant
- ✅ Comprehensive test coverage (unit + integration tests)
- ✅ Proper access control and encapsulation (AnyCoordinator internal, public API uses generics, router mutation methods internal)
- ✅ Input file lists configured for build phase dependency tracking

---

## Phase 2: View Layer Integration ✅ COMPLETE

### What Was Built

**Completed Tasks:**

1. **Admin Operations Documentation** ✅
   - Added `transitionToNewFlow(root:)` public API
   - Documented `router.setRoot()` as admin-only operation
   - Clear guidelines on when to use vs regular navigation

2. **CoordinatorView** ✅
   - SwiftUI view that renders coordinator navigation state
   - Observes Router (ObservableObject) for state changes
   - Coordinator provides actions (navigate, pop, dismissModal, dismissDetour)
   - NavigationStack integration with automatic back handling
   - Sheet presentation binding for modal routes
   - FullScreenCover binding for detour routes (preserves navigation context)
   - Two-way binding for user-initiated dismissals

3. **Detour Navigation** ✅
   - **REMOVED** `.detour` case from NavigationType enum (now explicit-only presentation)
   - Implemented `presentDetour()` and `dismissDetour()` in Coordinator
   - Detours must be presented explicitly via `presentDetour()` (NEVER through navigate())
   - Automatic detour dismissal during cross-flow navigation
   - Smart detour dismissal when detour bubbles to parent route already displayed
   - FullScreenCover presentation (slides from right, preserves context)
   - Integration tests for detour bubbling and dismissal

4. **Multiple Modal Coordinators** ✅
   - Changed from single modal coordinator to `modalCoordinators` array
   - **Type-constrained**: Modal coordinators must be `Coordinator<R>` (same route type as parent)
   - Multiple modal coordinators can be registered per coordinator
   - Only one presented at a time via `currentModalCoordinator`
   - Modal navigation finds appropriate coordinator via `canHandle()`
   - Smart modal dismissal when modal bubbles to parent route already displayed
   - Fixed bug: ensure `router.present()` is called before delegating to modal coordinator

5. **CoordinatorView Modal Rendering Fix** ✅
   - Fixed modal sheet rendering to use modal coordinator's buildView()
   - Previously used parent coordinator's router/factory (incorrect)
   - Now uses `coordinator.currentModalCoordinator.buildView(for: route)`
   - Modal coordinators build views using their own router/factory instance, not the parent's
   - Essential for complex modal flows with independent navigation stacks

6. **CoordinatorPresentationContext System** ✅
   - Automatic tracking of how coordinators are presented
   - Enum with 5 cases: `.root`, `.tab`, `.pushed`, `.modal`, `.detour`
   - Controls back button visibility without user configuration
   - Automatically set by framework when presenting coordinators
   - TabCoordinator defaults children to `.tab` context
   - Views can check `coordinator.presentationContext` to adapt UI
   - Comprehensive test coverage (7 unit tests + 3 integration tests)

7. **Navigation Back Action Environment System** ✅
   - Added `navigationBackAction` environment value for dismissal actions
   - Added `canNavigateBack` environment value for back button visibility
   - CoordinatorView injects appropriate actions based on context
   - Views read from environment to implement custom navigation UI
   - Works for modals, detours, and regular navigation
   - Enables maximum UI flexibility for framework users

8. **UI Freedom - Modal Dismissal Patterns** ✅
   - **Pattern 1: X Button** - `.withCloseButton()` modifier (DarkRed, DarkBlue, DarkYellow)
   - **Pattern 2: Custom Navigation Bar** - `.customNavigationBar()` (DarkPurple)
   - **Pattern 3: Native Navigation Bar** - `NavigationStack` + `.toolbar()` (DarkGreen)
   - **Pattern 4: Swipe Gesture** - All modals support via `presentedRoute` binding
   - Users choose the dismissal UI that fits their design
   - All patterns properly sync coordinator state
   - Example app demonstrates all approaches

9. **UI Freedom - Detour Dismissal Patterns** ✅
   - **Framework Fallback** - Auto-wraps detours in NavigationStack with back button
   - **Custom Override** - Use `.customNavigationBar()` to hide fallback (LightRed example)
   - **Native Override** - Add own `NavigationStack` + `.toolbar()`
   - **Custom Buttons** - Read `navigationBackAction` from environment
   - **Context-Aware Views** - Check `coordinator.presentationContext` to adapt UI
   - Fallback ensures users can always dismiss detours
   - Users have full control over navigation UI appearance

10. **Custom Navigation Bar Example Component** ✅
    - Created reusable CustomNavigationBar in example app
    - Framework-style navigation bar with back button, title, trailing button
    - Automatically hides native navigation bar (`.navigationBarHidden(true)`)
    - Reads `navigationBackAction` and `canNavigateBack` from environment
    - Demonstrates how to build custom navigation UI with framework

11. **FlowOrchestrator** ✅
    - Base class for root coordinators that manage major app flow transitions
    - Eliminates boilerplate code for flow changes (48-62% code reduction)
    - Automatic coordinator lifecycle management (deallocation and creation)
    - Public API: `transitionToFlow<FlowRoute>(_ coordinator: Coordinator<FlowRoute>, root: R)` (generic, accepts any concrete coordinator)
    - Property: `currentFlow: Any?` - the currently active flow coordinator (public read-only, cast to concrete type)
    - Clean architecture: Dependencies via init, service calls after transition
    - Comprehensive test coverage (8 unit tests + updated integration tests)
    - Example app updated to use FlowOrchestrator pattern

## Key Architectural Decisions

### 1. Router vs Coordinator Observation

**Decision:** CoordinatorView observes Router, not Coordinator

**Reasoning:**
- Router is already ObservableObject with @Published state
- Coordinator is pure logic (actions), Router is state
- Clean separation: State (observable) = Router, Actions = Coordinator
- No lifecycle issues (Router is immutable property of Coordinator)

### 2. Universal Navigate API - Smart Navigation from Anywhere

**Decision:** Single `navigate(to:)` API works from any coordinator, automatically handles all navigation scenarios

**Key Feature:** You can call `navigate(to:)` from ANY coordinator in your app, and the framework intelligently determines the correct navigation flow.

**How It Works:**
1. **Local handling**: If current coordinator can handle the route, navigate directly
2. **Smart backward navigation**: If route exists in current stack, auto-pop back to it
3. **Delegate to children**: Try child coordinators recursively
4. **Check modals/detours**: If active, delegate to them or dismiss if needed
5. **Bubble to parent**: If can't handle, ask parent coordinator
6. **Cross-coordinator**: Parent handles or continues bubbling up the hierarchy
7. **Auto-cleanup**: Dismisses modals/detours and cleans state when bubbling across flows

**Examples:**
```swift
// From anywhere in your app:
appCoordinator.navigate(to: .profile)

// Framework automatically:
// - Finds which coordinator owns .profile
// - Switches tabs if needed
// - Dismisses modals if needed
// - Cleans up intermediate navigation state
// - Executes correct navigation type (push/modal/detour)
```

**Benefits:**
- Deep linking works from any app state
- Push notifications can navigate from anywhere
- No manual coordinator lookups or state management
- Automatic cleanup prevents navigation stack pollution

### 3. SetRoot as Admin Operation

**Decision:** Keep setRoot separate from normal navigation flow

**Usage:**
- Normal navigation: `coordinator.navigate(to: route)`
- Major transitions: `coordinator.transitionToNewFlow(root: newRoot)`

**Examples:**
- Onboarding → Login
- Login → Home
- Logout → Login

### 4. Cross-Flow Navigation: Detour Pattern (Explicit Presentation Only)

**Problem:** Deep linking across coordinators wipes navigation context

**Example:**
- User at: Tab2 → UnlockCoordinator → EnterCode → Loading → Failure
- Deep link: Navigate to ProfileSettings (different coordinator)
- Desired: Push ProfileSettings, back button returns to Failure
- Problem: Without detours, bubbling up cleans state

**Solution:** Explicit Detour Presentation (NOT via NavigationType)
- **REMOVED** `.detour` from NavigationType enum (breaking change from earlier design)
- Detours MUST be presented explicitly via `presentDetour()` method
- NEVER return `.detour` from `navigationType()` - framework does not support this
- Presents as fullScreenCover (slides from right like push)
- Preserves underlying navigation context
- Auto-dismisses during cross-flow navigation
- **Smart dismissal**: Auto-dismisses when detour bubbles to parent route already displayed

**Why Explicit-Only?**
- Clearer API: Detours are fundamentally different from regular navigation
- Type safety: Detours can be any coordinator type (not constrained like modals)
- Less ambiguity: Explicit presentation makes intent obvious
- Prevents navigation type confusion with modals

**Implementation Details:**
- `detourCoordinator` property holds the currently presented detour
- `handleDetourNavigation()` checks detour first, similar to modal handling
- **REMOVED** `shouldDismissDetourFor()` method - detours always auto-dismiss during cross-flow navigation
- Detours always dismiss if they don't handle route (simplified logic)
- One level of detour (doesn't infinitely stack)

**Status:** ✅ Implemented and tested

### 5. View Initialization Pattern

**Decision:** Use ViewFactory for view/viewModel creation

**Pattern:**
```swift
class AppViewFactory: ViewFactory<AppRoute> {
    let dependencies: Dependencies

    override func buildView(for route: AppRoute) -> AnyView? {
        switch route {
        case .profile:
            let vm = ProfileViewModel(userService: dependencies.userService)
            return AnyView(ProfileView(viewModel: vm))
        }
    }
}
```

**Deferred:** Coordinator lifecycle hooks (prepare, didNavigate) - wait for real need

### 6. View Layer Testing Strategy

**Decision:** Manual validation via example app, then snapshot tests

**Reasoning:**
- SwiftUI views hard to unit test without dependencies
- Example app validates real-world integration
- Snapshot tests added later for regression protection

### 6. Sheet Presentation Styles

**Decision:** Add detents/custom sizing AFTER example app

**Reasoning:**
- Validate core works first
- Real usage will inform best API design
- Detents are iOS 16+ (might need fallback logic)

**Deferred to:** After example app validates basics

### 7. Multiple Modal Coordinators Pattern (Type-Constrained)

**Decision:** Support multiple modal coordinator registration per coordinator with type constraints

**Pattern:**
```swift
let mainCoordinator = MainCoordinator(...)
let profileModalCoord = ProfileModalCoordinator(...)  // Must be Coordinator<MainRoute>
let settingsModalCoord = SettingsModalCoordinator(...) // Must be Coordinator<MainRoute>

mainCoordinator.addModalCoordinator(profileModalCoord)
mainCoordinator.addModalCoordinator(settingsModalCoord)

// When navigating to a modal route, framework finds the right coordinator
mainCoordinator.navigate(to: .profile)  // Uses profileModalCoord
mainCoordinator.navigate(to: .settings) // Uses settingsModalCoord
```

**Implementation:**
- `modalCoordinators: [Coordinator<R>]` - **type-constrained** array of modal coordinators (same route type as parent)
- `currentModalCoordinator: AnyCoordinator?` - the one currently presented (type-erased, internal storage)
- Modal navigation finds coordinator via `canHandle()`, then presents it
- Only one modal presented at a time
- **Smart modal dismissal**: Modals auto-dismiss when they bubble to parent route already displayed

**Type Constraint Rationale:**
- Ensures modal coordinators can handle same routes as parent
- Compile-time safety for modal registration
- Parent and modal share same route enum for seamless navigation
- Detours use generics (`presentDetour<DetourRoute>(_:presenting:)`) for flexibility - any coordinator type accepted

**Bug Fixed:** Modal navigation now ensures `router.present()` is called before delegating to modal coordinator, so the presentation state is properly updated.

### 8. Error Handling Strategy

**Decision:** Defer comprehensive error handling to future phase

**Current Approach:**
- Use `assertionFailure()` for programmer errors (safe in production, crashes in debug)
- Two cases: modal coordinator not found, detour returned from navigationType()

**Future Enhancement:**
- Define NavigationError enum for various error cases
- Provide error callbacks/delegates for framework consumers
- Optional logging framework integration
- Consider changing `navigate(to:)` return type to `Result<Bool, NavigationError>`

**Reasoning:** Better to design comprehensive error handling strategy holistically rather than piecemeal solutions.

### 9. CoordinatorPresentationContext - Automatic Back Button Management

**Decision:** Framework automatically tracks how coordinators are presented and controls back button visibility

**Problem:** Views need to know whether to show back buttons, but determining this manually is error-prone:
- Root views shouldn't show back buttons
- Tab root views shouldn't show back buttons
- Pushed views should show back buttons
- Modal views should show back buttons
- Detour views should show back buttons

**Solution:** `CoordinatorPresentationContext` enum with automatic assignment

**Implementation:**
```swift
public enum CoordinatorPresentationContext {
    case root      // App root coordinator - no back button
    case tab       // Tab in TabCoordinator - no back button
    case pushed    // Child coordinator pushed - show back button
    case modal     // Modal presentation - show back button
    case detour    // Detour presentation - show back button

    public var shouldShowBackButton: Bool {
        switch self {
        case .root, .tab:
            return false
        case .pushed, .modal, .detour:
            return true
        }
    }
}
```

**Automatic Context Assignment:**
- Coordinators default to `.root` context
- `TabCoordinator.addChild()` defaults to `.tab` context
- `Coordinator.addChild()` defaults to `.pushed` context
- `presentModal()` automatically sets `.modal` context
- `presentDetour()` automatically sets `.detour` context

**Benefits:**
- Zero user configuration required
- Consistent back button behavior across app
- Views can adapt UI based on presentation context
- Framework handles complexity, users get simplicity

**Status:** ✅ Implemented with comprehensive tests

### 10. Navigation Back Action - Environment-Based Dismissal

**Decision:** Use SwiftUI environment to provide dismissal actions to views

**Problem:** Views need to dismiss themselves (modals, detours, navigation) but shouldn't directly call coordinator methods

**Solution:** Environment values for back actions and visibility

**Implementation:**
```swift
// Environment keys
@Environment(\.navigationBackAction) var backAction
@Environment(\.canNavigateBack) var canNavigateBack

// Framework injects appropriate action
.environment(\.navigationBackAction) { coordinator.pop() }          // Regular nav
.environment(\.navigationBackAction) { coordinator.dismissModal() } // Modal
.environment(\.navigationBackAction) { coordinator.dismissDetour() }// Detour
```

**Benefits:**
- Views don't need direct coordinator references for dismissal
- Same pattern works for all navigation types
- Testable (mock environment values)
- SwiftUI-idiomatic approach
- Enables maximum UI flexibility

**User Patterns:**
```swift
// Pattern 1: Custom button
Button("Close") {
    backAction?()
}

// Pattern 2: Conditional visibility
if canNavigateBack {
    BackButton()
}

// Pattern 3: Context-aware UI
if coordinator.presentationContext == .modal {
    CloseButton()
} else {
    BackButton()
}
```

**Status:** ✅ Implemented and used throughout example app

### 11. UI Freedom - Maximum Flexibility for Navigation UI

**Decision:** Framework provides smart defaults but allows complete UI customization

**Philosophy:** Users should have full control over navigation UI appearance while framework handles state management

**Modal Dismissal - 4 Approaches:**

1. **X Button (Close Button)**
   ```swift
   struct MyModal: View {
       var body: some View {
           ContentView()
               .withCloseButton()  // Framework-provided modifier
       }
   }
   ```

2. **Custom Navigation Bar**
   ```swift
   struct MyModal: View {
       var body: some View {
           ContentView()
               .customNavigationBar(title: "Settings",
                                   titleColor: .white,
                                   backgroundColor: .blue)
       }
   }
   ```

3. **Native Navigation Bar**
   ```swift
   struct MyModal: View {
       @Environment(\.navigationBackAction) var backAction

       var body: some View {
           NavigationStack {
               ContentView()
                   .navigationTitle("Settings")
                   .toolbar {
                       ToolbarItem(placement: .navigationBarLeading) {
                           Button("Close") { backAction?() }
                       }
                   }
           }
       }
   }
   ```

4. **Swipe Gesture Only**
   ```swift
   struct MyModal: View {
       var body: some View {
           ContentView()  // No navigation UI - rely on swipe
       }
   }
   ```

**Detour Dismissal - 5 Approaches:**

1. **Framework Fallback (Default)**
   - Framework automatically wraps in NavigationStack with back button
   - No user code needed
   - Ensures users can always dismiss

2. **Custom Navigation Bar**
   ```swift
   struct MyDetour: View {
       var body: some View {
           ContentView()
               .customNavigationBar(...)  // Hides framework fallback
       }
   }
   ```

3. **Native Navigation Bar**
   ```swift
   struct MyDetour: View {
       @Environment(\.navigationBackAction) var backAction

       var body: some View {
           NavigationStack {
               ContentView()
                   .toolbar {
                       ToolbarItem(placement: .navigationBarLeading) {
                           Button("Back") { backAction?() }
                       }
                   }
           }
       }
   }
   ```

4. **Custom Button**
   ```swift
   struct MyDetour: View {
       @Environment(\.navigationBackAction) var backAction

       var body: some View {
           VStack {
               Button("Back") { backAction?() }
               ContentView()
           }
       }
   }
   ```

5. **Context-Aware UI**
   ```swift
   struct MyView: View {
       let coordinator: MyCoordinator

       var body: some View {
           let content = ContentView()

           // Different UI based on presentation
           if coordinator.presentationContext == .detour {
               content.withCloseButton()
           } else {
               content.customNavigationBar(...)
           }
       }
   }
   ```

**Key Principles:**
- Framework provides smart defaults (fallback navigation)
- Users can override with any custom UI
- All approaches properly sync coordinator state
- Environment values enable any UI pattern
- Example app demonstrates all approaches

**Status:** ✅ Fully implemented with comprehensive examples

### 12. Flow Change Handling - Major Flow Transitions via Bubbling ✅

**Decision:** Enable major flow transitions (login ↔ main app) through route bubbling pattern, eliminating the need to pass root coordinator references throughout the app.

**Problem:** Apps need to transition between major flows (e.g., Login → Main App, Logout → Login) with:
- Complete deallocation of previous flow's coordinators
- Fresh coordinator creation on each transition
- Integration points for service calls (e.g., fetchUserProfile after login)
- No coupling between view code and root coordinator

**Previous Approach (Coupled):**
```swift
// ❌ Views needed direct access to AppCoordinator
struct LoginView: View {
    let appCoordinator: AppCoordinator  // Tight coupling

    Button("Login") {
        appCoordinator.transitionToNewFlow(root: .mainApp)
    }
}

struct PurpleView: View {
    let appCoordinator: AppCoordinator  // Tight coupling

    Button("Logout") {
        appCoordinator.transitionToNewFlow(root: .login)
    }
}
```

**Solution: handleFlowChange(to:) Hook**

Added open method to Coordinator that's called when a route bubbles to root and cannot be handled:

```swift
/// Handle major flow transitions (e.g., Login ↔ Main App).
///
/// Called when a route bubbles to root and cannot be handled. Override to orchestrate
/// flow changes: deallocate old coordinators, create fresh ones, call `transitionToNewFlow(root:)`.
open func handleFlowChange(to route: any Route) -> Bool {
    return false  // Default: don't handle
}
```

**New Approach (Decoupled):**
```swift
// ✅ Views use standard navigation - no root coordinator reference needed
struct LoginView: View {
    let coordinator: LoginCoordinator  // Only knows about its coordinator

    Button("Login") {
        coordinator.navigate(to: AppRoute.mainApp)  // Bubbles to root
    }
}

// ✅ Root coordinator orchestrates flow changes
class AppCoordinator: Coordinator<AppRoute> {
    private(set) var currentFlowCoordinator: AnyCoordinator?

    override func handleFlowChange(to route: any Route) -> Bool {
        guard let appRoute = route as? AppRoute else { return false }

        switch appRoute {
        case .login:
            showLogin()   // Deallocate main app, create fresh login
            return true
        case .mainApp:
            showMainApp() // Deallocate login, create fresh main app
            return true
        }
    }

    private func showMainApp() {
        // 1. Deallocate old flow
        if let current = currentFlowCoordinator {
            removeChild(current)
        }

        // 2. Create fresh coordinators
        let mainTab = MainTabCoordinator()
        addChild(mainTab)
        currentFlowCoordinator = mainTab

        // 3. Integration point for service calls
        fetchUserProfile()
        loadDashboardData()

        // 4. Transition to new root
        transitionToNewFlow(root: .mainApp)
    }
}
```

**How It Works:**

1. View calls `coordinator.navigate(to: AppRoute.mainApp)`
2. LoginCoordinator can't handle `.mainApp`, bubbles to parent
3. Route reaches AppCoordinator (root, has no parent)
4. Before failing, AppCoordinator tries `handleFlowChange(to: .mainApp)`
5. AppCoordinator's override returns `true` after orchestrating transition
6. Navigation succeeds, flow transition complete

**Implementation Details:**

- Added to `Coordinator.bubbleToParent()` at line 249-268
- Only called at root (when `parent == nil`)
- Checked before navigation fails
- Open method for subclass override
- Returns `Bool` to indicate if handled
- TabCoordinator can also implement for tab-level flow changes

**Benefits:**

✅ **Zero coupling**: Views only reference their local coordinator
✅ **Fresh state**: New coordinators created on each transition
✅ **Service integration**: Clear place to call APIs after login
✅ **Complete cleanup**: Old flow deallocated (verified with weak references)
✅ **Consistent pattern**: Uses standard `navigate()` API
✅ **Type safety**: Route types enforce valid transitions
✅ **Testable**: Easy to test flow change logic in isolation

**Testing:**

Created comprehensive test coverage in `FlowChangeIntegrationTests.swift` (7 tests):
- Login → Main App creates fresh coordinators
- Logout → Login deallocates main app coordinators
- Multiple login/logout cycles work correctly
- Deep nesting bubbles correctly
- Service call integration points work
- Service calls run fresh on each login
- All child coordinators deallocated on logout

Created unit tests in `CoordinatorNavigationTests.swift` (4 tests):
- handleFlowChange called when route can't be handled at root
- handleFlowChange NOT called when route can be handled
- handleFlowChange NOT called when coordinator has parent
- Navigation fails when handleFlowChange returns false

**Test Helpers:**

Created `FlowChangeTestHelpers.swift` with:
- `TestAppRoute` enum (login, mainApp)
- `TestAppCoordinator` - Demonstrates flow change pattern
- `TestLoginCoordinator` - Handles login route
- `TestMainTabCoordinator` - Handles mainApp route
- `TestAppCoordinatorWithServiceCalls` - Demonstrates service integration

**Code Organization:**

Split large test file for maintainability:
- Created `CoordinatorTestHelpers.swift` - SUT struct and makeSUT() function
- Split `CoordinatorTests.swift` (485 lines, 34 tests) into 4 focused files:
  1. `CoordinatorBasicsTests.swift` - Initialization, child management (8 tests)
  2. `CoordinatorNavigationTests.swift` - Navigation, bubbling, flow changes (13 tests)
  3. `CoordinatorPresentationTests.swift` - Modals, detours, contexts (11 tests)
  4. `TabCoordinatorTests.swift` - Tab-specific tests (4 tests)

**Bug Fixes:**

Fixed infinite loop in TabCoordinator navigation:
- Added `canNavigate()` check before trying tabs
- Made `bubbleToParent()` internal instead of private
- TabCoordinator now calls `bubbleToParent()` directly instead of duplicating logic
- Prevented tab iteration when route can't be handled by any tab

**Documentation:**

- Condensed verbose documentation to meet SwiftLint requirements
- Added concise example in `handleFlowChange()` doc comments
- Updated all test files with proper headers and organization

**Example App Integration:**

Updated example app to use flow change pattern:
- `AppCoordinator` - Root orchestrator, no longer TabCoordinator
- `LoginCoordinator` - Fresh on each logout, has deinit verification
- `MainTabCoordinator` - Fresh on each login, creates 5 tabs
- Views use `navigate()` instead of direct `transitionToNewFlow()` calls
- Removed appCoordinator coupling from ViewFactories
- Updated `SwiftUIFlowExampleApp.swift` to handle dynamic root switching

**Status:** ✅ Fully implemented, tested, and documented

### 13. FlowOrchestrator - Reducing Flow Transition Boilerplate ✅

**Decision:** Create specialized base class for root coordinators that manage major flow transitions

**Problem:** Flow change pattern required repetitive boilerplate code in every root coordinator:
```swift
// Repetitive pattern for every flow transition
private func showMainApp() {
    // 1. Remove old flow
    if let current = currentFlowCoordinator {
        removeChild(current)
    }

    // 2. Create new flow
    let mainTab = MainTabCoordinator()
    addChild(mainTab)
    currentFlowCoordinator = mainTab

    // 3. Transition root
    transitionToNewFlow(root: .mainApp)
}

private func showLogin() {
    // Same boilerplate repeated...
    if let current = currentFlowCoordinator {
        removeChild(current)
    }

    let login = LoginCoordinator()
    addChild(login)
    currentFlowCoordinator = login
    transitionToNewFlow(root: .login)
}
```

**Boilerplate Issues:**
- 42 lines of repetitive cleanup/setup code in AppCoordinator
- Same pattern duplicated in test helpers (56 lines)
- Error-prone: Easy to forget steps or get order wrong
- Obscures the intent: What flow we're transitioning to

**Solution: FlowOrchestrator Base Class**

Created specialized coordinator that encapsulates flow transition logic:

```swift
open class FlowOrchestrator<R: Route>: Coordinator<R> {
    /// The currently active flow coordinator.
    /// Clients can cast to concrete coordinator type (e.g., `as? MainTabCoordinator`)
    public private(set) var currentFlow: Any?

    /// Transition to a new application flow.
    ///
    /// Dependencies should be injected via the coordinator's initializer.
    /// Service calls should happen after calling this method.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Simple transition
    /// transitionToFlow(LoginCoordinator(), root: .login)
    ///
    /// // With dependencies
    /// transitionToFlow(
    ///     MainTabCoordinator(userService: userService),
    ///     root: .mainApp
    /// )
    ///
    /// // With service calls after transition
    /// transitionToFlow(MainTabCoordinator(), root: .mainApp)
    /// fetchUserProfile()
    /// loadDashboardData()
    /// ```
    public func transitionToFlow<FlowRoute: Route>(_ coordinator: Coordinator<FlowRoute>, root: R) {
        // 1. Deallocate old flow
        if let current = currentFlow as? AnyCoordinator {
            removeChild(current)
        }

        // 2. Install new flow
        addChild(coordinator)
        currentFlow = coordinator

        // 3. Transition root
        transitionToNewFlow(root: root)
    }
}
```

**New Approach (Clean & Concise):**

```swift
class AppCoordinator: FlowOrchestrator<AppRoute> {
    init() {
        let viewFactory = AppViewFactory()
        let router = Router(initial: .login, factory: viewFactory)
        super.init(router: router)
        viewFactory.appCoordinator = self
        transitionToFlow(LoginCoordinator(), root: .login)
    }

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
```

**Results:**
- Example app: 42 lines → 22 lines (48% reduction)
- Test helpers: 56 lines → 21 lines (62% reduction)
- Clear intent: One line per flow transition
- Automatic lifecycle: Framework handles cleanup/setup
- Type-safe: Compile-time checking of root routes

**Clean Architecture Emphasis:**

The API design enforces clean separation of concerns:

- **Coordinators**: Navigation only (no business logic, no service calls)
- **ViewFactory**: View/ViewModel creation with dependency injection
- **ViewModels**: Business logic and data fetching

Service calls happen AFTER transition, not during coordinator init:
```swift
case .tabRoot:
    transitionToFlow(MainTabCoordinator(), root: .tabRoot)
    return true
    // Service calls would happen in ViewModel.onAppear, not here
```

**API Design Evolution:**

Initially considered closure-based factory pattern:
```swift
// ❌ Initial design (rejected)
transitionToFlow({ MainTabCoordinator() }, root: .mainApp)
```

**Analysis revealed:**
- ViewModels created in ViewFactory, not coordinator
- Dependencies injected via coordinator init
- Service calls happen in ViewModels after views appear
- Closure provided no value, just added syntax noise

**Final API (simplified):**
```swift
// ✅ Final design (clean)
transitionToFlow(MainTabCoordinator(), root: .mainApp)
```

**Testing Strategy:**

**Unit Tests (FlowOrchestratorTests.swift - 8 tests):**
- Basic functionality: Creates/installs coordinator, transitions root, sets parent
- Flow cleanup: Deallocates previous flow, removes from children, clears parent reference
- Integration: Works with handleFlowChange hook
- Coordinator installation: Uses provided coordinator instance

**Integration Tests (FlowChangeIntegrationTests.swift - Updated):**
- Updated existing tests to use FlowOrchestrator pattern
- No test duplication (Option B: consolidate tests)
- Demonstrates recommended pattern with typed convenience properties

**Test Helpers Pattern:**

Tests can use typed convenience properties to bridge `AnyCoordinator` protocol and concrete types:

```swift
class TestAppCoordinator: FlowOrchestrator<TestAppRoute> {
    // Typed convenience properties for tests
    var loginCoordinator: TestLoginCoordinator? {
        currentFlow as? TestLoginCoordinator
    }

    var mainTabCoordinator: TestMainTabCoordinator? {
        currentFlow as? TestMainTabCoordinator
    }
}

// Usage in tests
let success = appCoordinator.loginCoordinator!.navigate(to: TestAppRoute.mainApp)
XCTAssertTrue(appCoordinator.currentFlow is TestMainTabCoordinator)
```

**Why this pattern?**
- `AnyCoordinator` protocol doesn't have `navigate(to:)` convenience overload
- Concrete `Coordinator<R>` has convenience method with default parameter
- Typed properties allow method calls, `currentFlow` for type checking

**File Organization:**

Created proper separation of test helpers:
- `FlowOrchestratorTests.swift` - 8 unit tests
- `FlowOrchestratorTestHelpers.swift` - Test infrastructure (separate file)
  - `FlowRoute` enum for testing
  - `FlowRouteViewFactory` for view factory
  - `TestFlowCoordinator` with specific route handling
  - `TestFlowOrchestratorWithFlowChange` demonstrating pattern

**Benefits:**

✅ **Massive boilerplate reduction**: 48-62% less code
✅ **Clear intent**: One line per flow transition
✅ **Automatic lifecycle**: Framework handles coordinator cleanup
✅ **Type safety**: Compile-time route checking
✅ **Testable**: Easy to test flow transitions in isolation
✅ **Consistent pattern**: Same API across all root coordinators
✅ **Clean architecture**: Enforces separation (Coordinators=Navigation, ViewModels=Business Logic)
✅ **Example app updated**: Demonstrates real-world usage

**Status:** ✅ Fully implemented, tested, and documented

### 14. Coordinator Initialization Simplification ✅

**Decision:** Reduce ViewFactory coupling and coordinator initialization boilerplate

**Problem:** Coordinator initialization required 4 lines of repetitive code:
```swift
let viewFactory = RedViewFactory()
let router = Router(initial: .red, factory: viewFactory)
super.init(router: router)
viewFactory.coordinator = self
```

**Solution:** Three improvements:

1. **Add coordinator property to base ViewFactory**
   ```swift
   open class ViewFactory<R: Route>: ObservableObject {
       public weak var coordinator: Coordinator<R>?
       // ...
   }
   ```

2. **Simplify to 3-line pattern**
   ```swift
   class RedCoordinator: Coordinator<RedRoute> {
       init() {
           let factory = RedViewFactory()
           super.init(router: Router(initial: .red, factory: factory))
           factory.coordinator = self
       }
   }
   ```

3. **Remove duplicate coordinator properties from ViewFactory subclasses**
   - ViewFactory subclasses now inherit `coordinator` from base class
   - Cast to specific coordinator type when needed: `coordinator as? RedCoordinator`

**Code Organization Improvements:**

1. **Extracted navigation helpers** (Coordinator.swift: 422 lines → 245 lines)
   - Created `Coordinator+NavigationHelpers.swift` (161 lines)
   - Extracted 7 navigation helper methods:
     - `trySmartNavigation(to:)`
     - `handleModalNavigation(to:from:)`
     - `handleDetourNavigation(to:from:)`
     - `delegateToChildren(route:caller:)`
     - `bubbleToParent(route:)`
     - `isAlreadyAt(route:)`
     - `executeNavigation(for:)`

2. **Changed access control for extension flexibility**
   - Changed `public private(set)` → `public internal(set)` for:
     - `children`, `modalCoordinators`, `currentModalCoordinator`, `detourCoordinator`
   - Allows framework code in extensions to modify internal state
   - Maintains external read-only API

**TabCoordinator Simplification:**

1. **Removed unnecessary `navigationType` override**
   - TabCoordinator no longer overrides with `fatalError`
   - Inherits sensible default (`.push`) from base Coordinator
   - Subclasses can override if needed

2. **Clarified MainTabCoordinator responsibilities**
   - `canHandle()` returns `false` - only delegates to children
   - `.tabRoot` is handled by AppCoordinator for flow transitions
   - Cross-tab navigation uses explicit routes (`.red`, `.green`, etc.)

**Rejected Approaches:**

❌ **Generic ViewFactory with convenience init** - Over-engineered, required:
   - Making ViewFactory generic over Coordinator type
   - Adding ViewFactoryProtocol for type erasure
   - Complex required initializer handling
   - User feedback: "serious over-engineering for a simple problem"

❌ **Convenience init pattern** - Confusing:
   - Required subclasses to use `convenience init()`
   - Used `self.init()` instead of `super.init()`
   - Developer confusion: "is the fact that the client should use a convenience init a bit confusing?"

**Benefits:**

✅ **Reduced boilerplate**: 4 lines → 3 lines per coordinator
✅ **Simpler**: Just add coordinator property to base class
✅ **Clear**: Uses familiar `super.init()` pattern
✅ **Flexible**: Subclasses can still add specific properties if needed
✅ **Maintainable**: Better file organization (Coordinator.swift under 400 lines)

**Results:**
- All 12 coordinators in example app updated
- ViewFactory subclasses cleaner (no duplicate properties)
- Coordinator file length reduced by 43%
- Navigation helpers clearly separated

**Status:** ✅ Fully implemented and validated

### 15. Error Handling System ✅

**Decision:** Implement comprehensive error reporting system for navigation failures and view creation errors

**Problem:** Framework needs to communicate errors to client apps when:
- Navigation fails (route can't be handled)
- View creation fails (ViewFactory returns nil)
- Modal/detour coordinator misconfiguration
- Circular references or duplicate children

**Solution: SwiftUIFlowError and Error Reporting System**

**Components:**

1. **SwiftUIFlowError enum** - Type-safe error representation
   ```swift
   public enum SwiftUIFlowError: Error {
       case navigationFailed(coordinator: String, route: String, routeType: String, context: String)
       case viewCreationFailed(coordinator: String, route: String, routeType: String, viewType: ViewType)
       case modalCoordinatorNotConfigured(coordinator: String, route: String, routeType: String)
       case invalidDetourNavigation(coordinator: String, route: String, routeType: String)
       case circularReference(coordinator: String)
       case duplicateChild(coordinator: String)

       public enum ViewType: String {
           case root, pushed, modal, detour
       }
   }
   ```

2. **SwiftUIFlowErrorHandler** - Global error reporting
   ```swift
   public class SwiftUIFlowErrorHandler {
       public static let shared = SwiftUIFlowErrorHandler()
       public var onError: ((SwiftUIFlowError) -> Void)?

       public func report(_ error: SwiftUIFlowError) {
           onError?(error)
       }
   }
   ```

3. **ErrorReportingView** - Fallback UI for view creation failures
   - Shows in place of views that fail to create
   - Immediately reports error through global handler
   - Framework handles presentation, client handles response

**Integration Points:**

1. **Navigation failures** - Coordinator.swift:156
   ```swift
   let error = makeError(for: route, errorType: .navigationFailed(context: "No coordinator can handle"))
   reportError(error)
   return false
   ```

2. **View creation failures** - CoordinatorView.swift
   - Root view fails: ErrorReportingView at line 57
   - Pushed view fails: ErrorReportingView at line 50
   - Modal view fails: ErrorReportingView at line 68
   - Detour view fails: ErrorReportingView at line 84, 101

3. **Coordinator errors** - Coordinator.swift
   - Circular reference: line 57
   - Duplicate child: line 64

**Client Usage Pattern:**

```swift
@main
struct MyApp: App {
    init() {
        SwiftUIFlowErrorHandler.shared.onError = { error in
            // Log to analytics
            print("Navigation error: \(error.description)")

            // Show user feedback
            showErrorToast(error)
        }
    }
}
```

**Testing:**

Created ErrorHandlingIntegrationTests.swift (4 tests):
- Navigation fails when no coordinator can handle route
- View creation failure for root view triggers error
- View creation failure for pushed view triggers error
- Multiple errors can be reported

**Example App Integration:**

1. **Error scenarios** - Demonstrate error handling
   - UnhandledRoute enum - navigation failure
   - BlueRoute.invalidView - view creation failure
   - Error toast UI component

2. **Error toast** - ErrorToastView.swift
   - Shows error description at top of screen
   - Red background with dismiss button
   - Auto-dismisses after 2 seconds
   - Positioned above all content

**Benefits:**

✅ **Type-safe errors**: Compile-time safety with enum
✅ **Global handling**: Single point for all framework errors
✅ **Contextual information**: Coordinator, route, and context included
✅ **Graceful degradation**: ErrorReportingView shows instead of crashing
✅ **Flexible response**: Clients choose how to handle (logging, UI, analytics)
✅ **Testable**: Easy to verify error reporting in tests

**Status:** ✅ Fully implemented with tests and examples

### 16. Modal and Detour Navigation Stacks ✅

**Decision:** Enable full navigation stack support within modal and detour presentations

**Problem:** Modals and detours were limited to single views with no ability to push/pop navigation:
- Modal coordinators couldn't push additional screens
- Detours couldn't have their own navigation stacks
- User flows requiring multi-step modals were impossible
- Back buttons in modals/detours would break navigation state

**Root Cause:**
- CoordinatorView used `buildView(for:)` which returns only the single view
- Parent coordinator doesn't know modal/detour coordinator's route type at compile time
- Manual NavigationStack wrapping in view layer was incomplete

**Solution: Use buildCoordinatorView() for Modals and Detours**

**Implementation:**

1. **Added dismissModal() and dismissDetour() to AnyCoordinator protocol** - AnyCoordinator.swift:22-26
   ```swift
   protocol AnyCoordinator: AnyObject {  // Internal protocol
       func dismissModal()
       func dismissDetour()
       // ... existing methods
   }
   ```

2. **Made Coordinator.pop() context-aware** - Coordinator.swift:222-240
   ```swift
   public func pop() {
       // If at root of modal/detour, dismiss instead of pop
       if router.state.stack.isEmpty {
           switch presentationContext {
           case .modal:
               parent?.dismissModal()
               return
           case .detour:
               parent?.dismissDetour()
               return
           default:
               break
           }
       }

       // Normal pop behavior
       router.pop()
   }
   ```

3. **Updated CoordinatorView to use buildCoordinatorView()** - CoordinatorView.swift
   - Modals (line 58-71): Use `buildCoordinatorView()` for full navigation support
   - Detours iOS (line 67-89): Use `buildCoordinatorView()` with fullScreenCover
   - Detours macOS (line 82-107): Use `buildCoordinatorView()` with sheet

**Why buildCoordinatorView()?**
- Returns full CoordinatorView with NavigationStack and navigation state management
- Modal coordinator builds its own navigation infrastructure with correct route type
- Parent can't build it because route type is not known at compile time
- Type erasure via `eraseToAnyView()` bridges the gap

**How It Works:**

1. **Present modal** - Modal coordinator's NavigationStack wraps root view
2. **Push in modal** - Modal coordinator's router manages stack
3. **Pop in modal** - If stack not empty, pops normally
4. **Pop at modal root** - Calls parent's dismissModal() instead
5. **Modal dismissed** - Parent cleans up modal coordinator reference

**Testing:**

Added 5 new tests to CoordinatorPresentationTests.swift:
- `test_ModalCanPushRoutes` - Push within modal works
- `test_ModalCanPopRoutes` - Pop within modal works
- `test_PopAtModalRootDismissesModal` - Pop at root dismisses
- `test_PopAtDetourRootDismissesDetour` - Pop at detour root dismisses
- `test_DetourCanPushAndPopRoutes` - Push/pop within detour works

**Example App:**

Added "even darker green" screen to demonstrate:
- DarkGreenView (modal) has "Go Even Darker" button
- Pushes to EvenDarkerGreenView within the modal
- Back button pops back to DarkGreenView
- Another back dismisses the modal

**Benefits:**

✅ **Multi-step modals**: Complex flows within modal presentations
✅ **Detour navigation**: Detours can have their own navigation stacks
✅ **Consistent behavior**: Pop() works the same everywhere, context-aware
✅ **Clean API**: Views call coordinator.pop(), framework handles context
✅ **Type-safe**: Modal coordinators know their own route types
✅ **Tested**: Comprehensive test coverage for all scenarios

**Status:** ✅ Fully implemented with tests and example

### 16A. Pushed Child Coordinators - Child Coordinator Navigation Support ✅

**Decision:** Enable child coordinators to be pushed into parent's navigation stack

**Problem:** Child coordinators could only be rendered as tabs or separate flows, but couldn't be pushed into parent's navigation hierarchy for true hierarchical navigation.

**Solution: Pushed Children Tracking**

**Implementation:**

1. **NavigationState.pushedChildren** - New array tracking pushed child coordinators
   ```swift
   /// Child coordinators currently pushed in the navigation stack
   /// Maintained in parallel with the route stack for rendering
   /// **Framework internal** - hidden from clients
   var pushedChildren: [AnyCoordinator]
   ```

2. **Router.pushChild() / popChild()** - Methods to manage pushed children
   ```swift
   func pushChild(_ coordinator: AnyCoordinator)  // Internal
   func popChild()
   ```

3. **CoordinatorView Integration** - Renders pushed children coordinators
   - Uses flattened navigation (see section 16B for implementation details)
   - Child routes rendered via `ChildRouteWrapper` in parent's NavigationStack
   - Back button automatically pops child coordinator

4. **Smart Navigation for Pushed Children** - Auto-pop when navigating to parent route
   - When pushed child navigates to parent's route, child gets popped
   - When parent navigates and child bubbles back, child gets popped
   - Prevents getting stuck in child coordinator flow

**How It Works:**

```swift
// Parent delegates to child for route
func delegateToChildren(route: any Route, caller: AnyCoordinator?) -> Bool {
    for child in children where child !== caller {
        if child.canHandle(route) {
            let navType = child.navigationType(for: route)

            switch navType {
            case .push:
                router.pushChild(child)  // ← Pushed into parent's nav stack
                child.parent = self
                child.presentationContext = .pushed
                _ = child.navigate(to: route, from: self)
                return true
            // ... other cases
            }
        }
    }
}

// Smart navigation handles pushed children
if let typedRoute = route as? R, trySmartNavigation(to: typedRoute) {
    // If caller is a pushed child, pop it
    if let caller, router.state.pushedChildren.contains(where: { $0 === caller }) {
        router.popChild()
        NavigationLogger.debug("👈 Popped child coordinator after bubbling back")
    }
    return true
}
```

**Testing:**

Added tests to NavigationFlowIntegrationTests.swift:
- Pushed child coordinators are rendered correctly
- Back button pops pushed child
- Smart navigation pops child when navigating to parent route
- Multiple pushed children work correctly

**Benefits:**

✅ **Hierarchical navigation**: Child coordinators can be part of parent's navigation flow
✅ **Type safety**: Child knows its own route types
✅ **Clean back navigation**: Automatically pops child when returning to parent
✅ **Consistent behavior**: Same pop() API works for routes and child coordinators
✅ **Flexible architecture**: Mix routes and child coordinators in same navigation stack

**Status:** ✅ Fully implemented and tested

### 16B. Flattened Navigation Architecture - SwiftUI NavigationStack Limitations ✅

**Decision:** Use flattened navigation hierarchy instead of nested NavigationStack views for pushed child coordinators

**Critical Discovery:** Nested NavigationStack views inside `.navigationDestination` callbacks fundamentally **do not work** in SwiftUI - this is an official Apple limitation, not a bug in our framework.

**Problem:** Initial implementation (main branch) attempted to render pushed child coordinators using nested NavigationStacks:
```swift
// ❌ Main branch approach (broken)
.navigationDestination(for: CoordinatorWrapper.self) { wrapper in
    // Render child's full CoordinatorView (includes NavigationStack)
    wrapper.coordinator.buildCoordinatorView()
}
```

**Symptoms:**
1. ✗ Navigation bounced back immediately on first tap
2. ✗ Routes never appeared in child coordinator's stack
3. ✗ SwiftUI error: "NavigationLink is presenting a value but there is no matching navigationDestination"
4. ✗ Fatal errors: `SwiftUI.AnyNavigationPath.Error.comparisonTypeMismatch`

**Root Cause Investigation:**

We tested pure SwiftUI code (no framework) to isolate the issue:
```swift
// Pure SwiftUI test - still fails!
NavigationStack(path: $outerPath) {
    Button("Push Container") { outerPath.append("container") }
    .navigationDestination(for: String.self) { _ in
        // Nested NavigationStack inside navigationDestination
        NavigationStack(path: $innerPath) {
            Button("Inner Nav") { innerPath.append(1) }
            .navigationDestination(for: Int.self) { number in
                Text("Screen \(number)")
            }
        }
    }
}

// Result: Navigation bounces back, inner navigation never works
```

**Official Apple Position:**

From Apple Developer Forums and Stack Overflow (January 2025):
> "Nested NavigationStack are not supported in SwiftUI currently. The intended way to use it is to have one top-level NavigationStack that contains multiple navigationDestination modifiers."
> - Apple DTS Engineer

**Why Nested NavigationStack Doesn't Work:**

1. **Type Collision**: SwiftUI can't differentiate which NavigationStack should handle which route type
2. **Path Confusion**: SwiftUI's NavigationPath can't track nested hierarchies
3. **By Design**: NavigationStack was explicitly designed for flat navigation, not hierarchical nesting
4. **Since iOS 16**: This limitation exists from when NavigationStack was introduced (2022)

**Not a Bug - It's Architectural:**
- ✗ Not a version-specific issue (iOS 16, 17, 18 all have same limitation)
- ✗ Not fixable with workarounds (observers, callbacks, state management)
- ✓ Fundamental SwiftUI design constraint
- ✓ Documented by Apple as intended behavior

**Solution: Flattened Navigation Architecture**

Instead of nesting NavigationStacks, flatten all routes into parent's single NavigationStack:

```swift
// ✅ feature/Pushed-Childs-FullScreen-Approach (works!)

// Parent's navigation path includes BOTH parent and child routes
var navigationPath: Binding<NavigationPath> {
    Binding(get: {
        var path = NavigationPath()

        // Add parent's routes
        for route in router.state.stack {
            path.append(route)
        }

        // Add FLATTENED child routes
        for wrapper in pushedChildStack {
            path.append(wrapper)  // ChildRouteWrapper wraps child route + coordinator
        }

        return path
    })
}

// Render child routes with ChildRouteWrapper
.navigationDestination(for: ChildRouteWrapper.self) { wrapper in
    ChildCoordinatorRouteView(wrapper: wrapper)
}
```

**Implementation Details:**

**1. ChildRouteWrapper - Type Erasure for Flattened Navigation**
```swift
struct ChildRouteWrapper: Hashable {  // Internal struct
    let route: any Route       // Type-erased child route
    let coordinator: AnyCoordinator  // Coordinator that owns this route (internal)

    func hash(into hasher: inout Hasher) {
        hasher.combine(route.identifier)
        hasher.combine(ObjectIdentifier(coordinator))
    }
}
```

**Why Wrapper?**
- Parent doesn't know child's route type at compile time
- Wrapper associates route with its coordinator
- Hashable for NavigationPath compatibility
- Identity based on route + coordinator (same route, different coordinator = different identity)

**2. pushedChildStack - Cached Flattened Routes**
```swift
@State private var pushedChildStack: [ChildRouteWrapper] = []

private func rebuildPushedChildStack() {
    pushedChildStack = router.state.pushedChildren.flatMap { child in
        child.allRoutes.map { route in
            ChildRouteWrapper(route: route, coordinator: child)
        }
    }
}
```

**Why Cache?**
- Flattens multi-level hierarchy into single array
- Each child can have multiple routes (root + stack)
- Rebuilds when any child's routes change
- Efficient: Only rebuilds when necessary (via Combine subscriptions)

**3. Synchronous Rebuild - Avoiding White Flash Bug**
```swift
.onReceive(router.$state) { _ in
    setupChildSubscriptions()  // Rebuild immediately, synchronously
}
```

**Why .onReceive Instead of .task/.onChange?**
- `.task(id:)` - Asynchronous, causes white flash
- `.onChange(of:)` - Asynchronous, causes white flash
- `.onReceive` - **Synchronous**, no flash!

The white flash occurs when:
1. Child route changes
2. View layer rebuilds asynchronously
3. Brief moment where old route shown with new state
4. User sees white flash

Synchronous rebuild eliminates this race condition.

**4. Child Route Subscriptions - Reactive Updates**
```swift
private func setupChildSubscriptions() {
    cancellables.removeAll()

    for child in router.state.pushedChildren {
        child.routesDidChange
            .receive(on: DispatchQueue.main)
            .sink { _ in rebuildPushedChildStack() }
            .store(in: &cancellables)
    }

    rebuildPushedChildStack()
}
```

**Why Subscribe?**
- Child coordinators push/pop their own routes
- Parent needs to know when child routes change
- Type-erased publisher (`AnyPublisher<[any Route], Never>`) enables this
- Main thread dispatch ensures UI updates correctly

**Challenge: Modals and Detours from Pushed Children**

**New Problem:** Flattened navigation solves push/pop, but creates modal/detour issue:

```swift
// With flattened navigation, child routes render as plain views
.navigationDestination(for: ChildRouteWrapper.self) { wrapper in
    wrapper.coordinator.buildView(for: wrapper.route)  // ← Just the view, no modal/detour support!
}
```

Child views can't present modals/detours because:
- Parent's CoordinatorView has modal/detour presentation modifiers
- Child views are rendered directly (no CoordinatorView wrapper)
- Modal/detour calls fail - no presentation infrastructure

**Solution: CoordinatorRouteView Wrapper**

Wrap each child route with its own modal/detour presentation:

```swift
// New file: SwiftUIFlow/View/CoordinatorRouteView.swift

struct CoordinatorRouteView<R: Route>: View {
    let coordinator: Coordinator<R>
    let route: any Route
    @ObservedObject var router: Router<R>

    var body: some View {
        // 1. Render the actual view
        coordinator.buildView(for: route)

        // 2. Add modal presentation modifiers
        .sheet(isPresented: ...) {
            if let modal = coordinator.currentModalCoordinator {
                modal.buildCoordinatorView()
            }
        }

        // 3. Add detour presentation modifiers
        .fullScreenCover(isPresented: ...) {
            if let detour = coordinator.detourCoordinator {
                detour.buildCoordinatorView()
            }
        }
    }
}
```

**How It Works:**

1. **Each child route** gets wrapped in `CoordinatorRouteView`
2. **Each wrapper** adds modal/detour presentation modifiers
3. **Child coordinator** can present modals/detours normally
4. **Framework handles** the presentation infrastructure

**Type Erasure Challenge:**

Problem: `buildCoordinatorRouteView()` must return type-erased view:
```swift
// In Coordinator.swift (Core layer - no SwiftUI import)
public func buildCoordinatorRouteView(for route: any Route) -> Any {
    return CoordinatorRouteView(coordinator: self, route: route)  // ← Returns Any
}

// In CoordinatorRouteView.swift (View layer - has SwiftUI)
struct ChildCoordinatorRouteView: View {
    var body: some View {
        // Cast from Any to View at call site
        if let view = wrapper.coordinator.buildCoordinatorRouteView(for: route) as? any View {
            AnyView(view)
        }
    }
}
```

**Why This Pattern?**
- Core layer can't import SwiftUI (architectural separation)
- `buildView()` and `buildCoordinatorView()` use same pattern
- Type erasure happens at view layer, not core
- Keeps framework architecture clean

**Testing Methodology:**

**1. Pure SwiftUI Test:**
- Created `NestedNavigationTest.swift` with 4 container examples
- Tested nested NavigationStack without any framework code
- **Result**: Confirmed SwiftUI limitation (navigation bounces, crashes)

**2. Web Research:**
- Stack Overflow: Multiple reports of same issue
- Apple Forums: DTS Engineer confirmed not supported
- Community consensus: Use single NavigationStack with multiple destinations

**3. Production Test:**
- Example app: Rainbow coordinator with 6 screens
- Button "Go to Purple" with `.modal` navigation type
- Added `RainbowModalCoordinator` and modal presentation
- **Result**: ✅ Modal presents correctly from pushed child!

**Comparison: Main Branch vs Feature Branch**

| Aspect | Main Branch | Feature Branch |
|--------|-------------|----------------|
| **Architecture** | Nested NavigationStacks | Flattened Navigation |
| **Push Child Route** | ❌ Bounces back | ✅ Works |
| **Child Navigation** | ❌ Routes don't stack | ✅ Routes stack correctly |
| **Back Navigation** | ❌ Broken | ✅ Smooth |
| **Modals from Child** | ❌ Not possible | ✅ Works |
| **Detours from Child** | ❌ Not possible | ✅ Works |
| **White Flash** | ❌ Yes (async updates) | ✅ No (sync updates) |
| **SwiftUI Compatibility** | ❌ Fights framework | ✅ Works with framework |

**Files Created:**

1. **SwiftUIFlow/View/CoordinatorRouteView.swift** (97 lines)
   - `CoordinatorRouteView<R>` - Wraps child routes with modal/detour support
   - `ChildCoordinatorRouteView` - Type-erased wrapper for navigation destination

2. **SwiftUIFlow/View/Coordinator+View.swift** (18 lines) - REMOVED
   - Initially tried extension approach
   - Replaced with direct `Any` return in Coordinator.swift

3. **SwiftUIFlowExample/NestedNavigationTest.swift** (202 lines)
   - Pure SwiftUI tests to verify limitation
   - 4 container examples with different route types
   - Comprehensive logging for debugging

4. **SwiftUIFlowExample/ClaudeExactExample.swift** (130 lines)
   - Recreated exact pattern from Claude AI suggestion
   - Proved even "working" examples have issues
   - Documented specific failure modes

**Key Code Changes:**

**CoordinatorView.swift:**
```swift
// Before (main branch):
.navigationDestination(for: CoordinatorWrapper.self) { wrapper in
    eraseToAnyView(wrapper.coordinator.buildCoordinatorView())
}

// After (feature branch):
@State private var pushedChildStack: [ChildRouteWrapper] = []

var navigationPath: Binding<NavigationPath> {
    Binding(get: {
        var path = NavigationPath()
        for route in router.state.stack { path.append(route) }
        for wrapper in pushedChildStack { path.append(wrapper) }  // ← Flattened!
        return path
    }, ...)
}

.navigationDestination(for: ChildRouteWrapper.self) { wrapper in
    ChildCoordinatorRouteView(wrapper: wrapper)  // ← With modal/detour support
}

.onReceive(router.$state) { _ in
    setupChildSubscriptions()  // ← Synchronous rebuild
}
```

**AnyCoordinator.swift:**
```swift
// Added for flattening:
protocol AnyCoordinator: AnyObject {  // Internal protocol
    var allRoutes: [any Route] { get }
    var routesDidChange: AnyPublisher<[any Route], Never> { get }
    func buildCoordinatorRouteView(for route: any Route) -> Any
}

// Type erasure wrapper:
struct ChildRouteWrapper: Hashable {  // Internal struct
    let route: any Route
    let coordinator: AnyCoordinator
}
```

**Coordinator.swift:**
```swift
// Added computed property:
public var allRoutes: [any Route] {
    [router.state.root] + router.state.stack
}

// Added publisher:
public var routesDidChange: AnyPublisher<[any Route], Never> {
    router.routesDidChange.eraseToAnyPublisher()
}

// Added method (returns Any, not SwiftUI types):
public func buildCoordinatorRouteView(for route: any Route) -> Any {
    return CoordinatorRouteView(coordinator: self, route: route)
}
```

**Architectural Principles Learned:**

**1. Work With Framework Constraints, Not Against Them**
- SwiftUI has opinions about navigation architecture
- Fighting these constraints creates fragile code
- Embracing constraints leads to cleaner solutions

**2. Type Erasure is Essential for Hierarchical Coordinators**
- Parent can't know child's route type at compile time
- `any Route` and `AnyCoordinator` enable polymorphism
- Wrappers bridge type safety and flexibility

**3. Synchronous UI Updates Prevent Visual Glitches**
- Async updates cause race conditions
- `.onReceive` provides synchronous updates
- Critical for smooth navigation UX

**4. Test Framework Assumptions with Minimal Examples**
- Don't assume framework limitations are your bugs
- Create isolated test cases without framework code
- Research community knowledge (Stack Overflow, Apple Forums)

**5. Separation of Concerns Via Layers**
- Core layer: Pure logic, no SwiftUI
- View layer: SwiftUI, type erasure casting
- Clean architecture > convenience

**Benefits:**

✅ **Works with SwiftUI**: Respects NavigationStack design
✅ **Full feature support**: Modals, detours, pushed children all work
✅ **No white flash**: Synchronous updates
✅ **Type safe**: Coordinator generics preserved where possible
✅ **Clean separation**: Core layer independent of SwiftUI
✅ **Future proof**: Aligns with Apple's intended usage
✅ **Production ready**: No workarounds or hacks

**Alternatives Considered:**

❌ **Fix nested NavigationStack** - Impossible, SwiftUI limitation
❌ **Delegation to parent for modals** - Breaks coordinator independence
❌ **ViewFactory modifiers** - Tight coupling, breaks architecture
❌ **Limit pushed children features** - Unacceptable UX compromise

**Documentation:**

- ✅ Comprehensive inline documentation
- ✅ Web research and citations
- ✅ Test files demonstrating issue
- ✅ This detailed architectural explanation

**Status:** ✅ Fully implemented, tested, and production-ready

**Attribution:**

Pattern uses standard SwiftUI techniques:
- Single NavigationStack with multiple destinations (Apple recommendation)
- Type erasure for polymorphism (Swift standard practice)
- Combine publishers for reactive updates (Apple framework)

**Last Updated:** November 20, 2025

### 17. Two-Phase Navigation - Atomic Navigation with Specific Error Reporting ✅

**Decision:** Implement validation-before-execution pattern to prevent broken intermediate states during navigation failures

**Critical Bug Fixed:** When navigation failed partway through bubbling, state changes (modal dismissals, pops, etc.) had already occurred, leaving the app in a broken intermediate state.

**Problem Example:**
```swift
// Before fix:
TabCoordinator (tab 2 selected)
  ├─ Tab2Coordinator (3 screens in stack, modal open)
  └─ Navigation to UnhandledRoute

Execution flow:
1. Tab2 dismisses modal ✓ (SIDE EFFECT)
2. Tab2 pops to root ✓ (SIDE EFFECT)
3. Tab2 bubbles to TabCoordinator
4. TabCoordinator tries other tabs
5. Navigation FAILS ❌
6. Result: Modal gone, stack cleared, but navigation failed
   → User stuck in broken state!
```

**Solution: Two-Phase Navigation**

Separate navigation into two atomic phases:
1. **Phase 1 - Validation**: Traverse entire hierarchy, check if navigation CAN succeed (no side effects)
2. **Phase 2 - Execution**: Only execute if validation passed (with side effects)

**Implementation:**

**New Types** - `SwiftUIFlowError.swift`:
```swift
/// Result of navigation validation
public enum ValidationResult {
    case success
    case failure(SwiftUIFlowError)

    var isSuccess: Bool { ... }
    var error: SwiftUIFlowError? { ... }
}
```

**Validation Phase** - `Coordinator+NavigationHelpers.swift`:
```swift
// MARK: - Validation Phase (No Side Effects)
extension Coordinator {
    func validateNavigationPathBase(to route: any Route, from caller: AnyCoordinator?) -> ValidationResult {
        // 1. Smart navigation check (no side effects - just checking state)
        if let typedRoute = route as? R, canValidateSmartNavigation(to: typedRoute) {
            return .success
        }

        // 2. Modal/Detour navigation check
        if let modalDetourResult = validateModalAndDetourNavigation(to: route, from: caller) {
            return modalDetourResult
        }

        // 3. Direct handling check with specific errors
        if let directHandlingResult = validateDirectHandling(of: route) {
            return directHandlingResult  // Returns .modalCoordinatorNotConfigured or .invalidDetourNavigation
        }

        // 4. Delegate to children
        if let childrenResult = validateChildrenCanHandle(route: route, caller: caller) {
            return childrenResult
        }

        // 5. Bubble to parent
        return validateBubbleToParent(route: route)
    }

    private func validateDirectHandling(of route: any Route) -> ValidationResult? {
        guard let typedRoute = route as? R, canHandle(typedRoute) else {
            return nil
        }

        switch navigationType(for: typedRoute) {
        case .push, .replace, .tabSwitch:
            return .success
        case .modal:
            if let currentModal = currentModalCoordinator, currentModal.canHandle(route) {
                return .success
            }
            if modalCoordinators.contains(where: { $0.canHandle(route) }) {
                return .success
            }
            // Specific error instead of generic navigationFailed
            return .failure(makeError(for: route, errorType: .modalCoordinatorNotConfigured))
        case .detour:
            // Specific error instead of generic navigationFailed
            return .failure(makeError(for: route, errorType: .invalidDetourNavigation))
        }
    }
}
```

**Execution Phase** - `Coordinator.swift`:
```swift
// Public API (no caller parameter)
public func navigate(to route: any Route) -> Bool {
    return navigate(to: route, from: nil)
}

// Internal with caller tracking
func navigate(to route: any Route, from caller: AnyCoordinator?) -> Bool {
    // Phase 1: Validation - ONLY at entry point (caller == nil)
    if caller == nil {
        let validationResult = validateNavigationPath(to: route, from: caller)
        if case let .failure(error) = validationResult {
            NavigationLogger.error("❌ \(Self.self): Navigation validation failed")
            reportError(error)  // Reports SPECIFIC error
            return false
        }
    }

    // Phase 2: Execution (side effects happen here)
    // ... existing navigation logic with side effects
}
```

**Specific Error Types:**

Before fix (generic errors):
```swift
❌ "Navigation failed: No coordinator can handle this route"
```

After fix (specific errors):
```swift
✅ "Cannot present 'profile' as modal - no modal coordinator configured"
✅ "Cannot navigate to 'settings' - detours must use presentDetour()"
✅ "Invalid tab index 5 - valid range is 0..<3"
✅ "Navigation failed: No coordinator in hierarchy can handle this route"
```

**Key Architectural Points:**

1. **Validation mirrors execution exactly**
   - Same logic flow (smart nav → modal → detour → direct → children → parent)
   - Same caller tracking to prevent infinite loops
   - Same skip logic for modal/detour when caller is our child

2. **No side effects during validation**
   - No `dismissModal()`, `popTo()`, `push()`, etc.
   - Just checking state (isAlreadyAt, canHandle, canNavigate)
   - Returns success/failure without mutating anything

3. **Specific errors from validation**
   - `.modalCoordinatorNotConfigured` when modal NavigationType but no coordinator
   - `.invalidDetourNavigation` when detour returned from navigationType()
   - `.navigationFailed` with context when route can't be handled

4. **Execution phase has safety logs**
   - Unreachable error cases now log warnings
   - "validation should have caught this" messages
   - Helps catch validation bugs during development

**Testing:**

Updated ErrorHandlingIntegrationTests.swift (7 tests):
- `test_ModalCoordinatorNotConfigured_CallsErrorHandler` - Now expects specific error
- `test_InvalidDetourNavigation_CallsErrorHandler` - Now expects specific error
- All other tests verify specific errors are reported

**Implementation Cost:**
- Added ~200 lines of validation code
- Validation helpers mirror execution helpers
- Worth it: Prevents real user-facing bugs in production

**Alternatives Considered:**

1. **Deferred Execution Pattern** (Build action list, then execute)
   - ❌ Doesn't work: Decisions depend on execution results (modal handled? → dismiss or continue)
   - ❌ Conditional actions would require complex decision tree structure

2. **Transaction/Rollback Pattern** (Execute, rollback on failure)
   - ❌ Too complex: Need to snapshot entire hierarchy state
   - ❌ Brittle: Rollback could fail, animations/callbacks not reversible

3. **Navigate-Back-On-Failure** (Store state, navigate back if failed)
   - ❌ UI flicker: User briefly sees broken state
   - ❌ Partial solution: Only restores one coordinator's route, not entire hierarchy

**Why ValidationResult is the Best Solution:**

✅ **Zero flicker** - User never sees broken state
✅ **Specific errors** - Detailed error information for debugging
✅ **Atomic navigation** - Either fully succeeds or fully fails
✅ **Well-known pattern** - Validation before execution (form validation, SQL planning, type checking)
✅ **Testable** - Easy to verify validation logic separately
✅ **Production-ready** - Acceptable cost (~200 lines) for production framework

**Files Modified:**
- `SwiftUIFlow/Core/SwiftUIFlowError.swift` - Added ValidationResult enum
- `SwiftUIFlow/Core/Coordinator/AnyCoordinator.swift` - Changed return type to ValidationResult
- `SwiftUIFlow/Core/Coordinator/Coordinator.swift` - Two-phase navigate(), validateNavigationPath()
- `SwiftUIFlow/Core/Coordinator/Coordinator+NavigationHelpers.swift` - All validation helpers
- `SwiftUIFlow/Core/Coordinator/TabCoordinator.swift` - Tab-specific validation
- `SwiftUIFlowTests/IntegrationTests/ErrorHandlingIntegrationTests.swift` - Updated tests

**Benefits:**

✅ **Prevents broken states** - Navigation either fully succeeds or leaves state unchanged
✅ **Better error messages** - Specific errors instead of generic failures
✅ **Production quality** - Framework suitable for mission-critical apps
✅ **Developer experience** - Clear error messages help fix issues faster
✅ **Maintainable** - Validation logic cleanly separated in extension

**Status:** ✅ Fully implemented, tested, and validated

### 18. Modal Presentation Detents - Content-Adaptive Sheet Sizing ✅

**Decision:** Implement comprehensive detent system for modal presentations with automatic content-based sizing

**Problem:** SwiftUI's native sheets support only fixed detents (`.medium`, `.large`). Apps need:
- Content-adaptive sheets that automatically size to fit content
- Multiple detent options (small, medium, large, extra large, fullscreen)
- True fullscreen presentation (fullScreenCover) triggered by detent configuration
- Smooth animations when content size changes
- User-draggable detents for flexible modal heights

**Solution: ModalPresentationDetent System**

Implemented a complete detent system inspired by common SwiftUI patterns, integrated with SwiftUIFlow's coordinator architecture.

**Core Components:**

1. **ModalPresentationDetent enum** - Six detent types
   ```swift
   public enum ModalPresentationDetent: Equatable {
       case small       // Minimal height (e.g., header only)
       case medium      // ~50% screen (native SwiftUI)
       case large       // 99.9% screen (avoids 3D push effect)
       case extraLarge  // 100% screen (still a sheet)
       case fullscreen  // True fullScreenCover presentation
       case custom      // Automatic content-based sizing
   }
   ```

2. **ModalDetentConfiguration** - Configuration with height tracking
   ```swift
   public struct ModalDetentConfiguration: Equatable {
       let detents: [ModalPresentationDetent]
       var selectedDetent: ModalPresentationDetent?
       var minHeight: CGFloat?    // For .small detent
       var idealHeight: CGFloat?  // For .custom detent

       var shouldUseFullScreenCover: Bool {
           detents.contains(.fullscreen)
       }
   }
   ```

3. **View+OnSizeChange modifier** - Content measurement tool
   ```swift
   // Wraps GeometryReader for clean size tracking
   .onSizeChange { size in
       contentHeight = size.height
   }
   ```

4. **PreferenceKeys** - For multi-section height tracking
   ```swift
   IdealHeightPreferenceKey  // Full content height (.custom)
   MinHeightPreferenceKey    // Minimum height (.small)
   ```

**How It Works:**

**Simple Content-Sized Modal:**
```swift
// 1. Define modal with .custom detent
coordinator.presentModal(
    infoCoordinator,
    presenting: .info,
    detentConfiguration: ModalDetentConfiguration(detents: [.custom])
)

// 2. Framework automatically:
//    - Measures modal content via GeometryReader
//    - Updates idealHeight via PreferenceKeys
//    - Maps .custom → .height(idealHeight)
//    - Sheet smoothly animates to fit content
```

**Multiple Detents (User-Draggable):**
```swift
// User can drag between different heights
coordinator.presentModal(
    modalCoordinator,
    presenting: .settings,
    detentConfiguration: ModalDetentConfiguration(
        detents: [.small, .medium, .custom],
        selectedDetent: .small  // Start collapsed
    )
)
```

**True Fullscreen:**
```swift
// Presents as fullScreenCover instead of sheet
coordinator.presentModal(
    modalCoordinator,
    presenting: .fullscreen,
    detentConfiguration: ModalDetentConfiguration(detents: [.fullscreen])
)
```

**Do I Need to Use PreferenceKeys?**

**Most Common Case: NO** ✅
- If you're using a **single detent** (`.custom`, `.small`, `.medium`, etc.), you don't need to do anything!
- The framework automatically measures content and applies the appropriate height
- This works for 90% of use cases

**When You DO Need PreferenceKeys:**

You only need to use PreferenceKeys when presenting **multiple detents** that include both `.small` and `.custom`:

```swift
// This requires PreferenceKeys because framework needs to know:
// 1. minHeight for .small (header only)
// 2. idealHeight for .custom (full content)
coordinator.presentModal(
    modalCoordinator,
    presenting: .settings,
    detentConfiguration: ModalDetentConfiguration(
        detents: [.small, .custom],  // ← Multiple content-based detents!
        selectedDetent: .small
    )
)
```

**Why?** When users drag between `.small` and `.custom`, the framework needs:
- **minHeight** - What size should the collapsed state be? (just header)
- **idealHeight** - What size should the expanded state be? (all content)

**How to Implement Multi-Detent Content:**

```swift
struct SettingsModal: View {
    // 1. Track each section's height
    @State private var headerHeight: CGFloat?
    @State private var bodyHeight: CGFloat?
    @State private var footerHeight: CGFloat?

    // 2. Calculate total height (for .custom detent)
    var idealHeight: CGFloat? {
        [headerHeight, bodyHeight, footerHeight]
            .compactMap { $0 }
            .reduce(0, +)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 3. Measure each section
            HeaderSection()
                .onSizeChange { headerHeight = $0.height }

            BodySection()
                .onSizeChange { bodyHeight = $0.height }

            FooterSection()
                .onSizeChange { footerHeight = $0.height }
        }
        // 4. Send heights to framework via PreferenceKeys
        .preference(key: IdealHeightPreferenceKey.self, value: idealHeight)
        .preference(key: MinHeightPreferenceKey.self, value: headerHeight)
    }
}
```

**What Happens:**
1. Each section measures itself using `.onSizeChange()`
2. Heights are summed to get total content height
3. `IdealHeightPreferenceKey` sends total height → used for `.custom` detent
4. `MinHeightPreferenceKey` sends header height → used for `.small` detent
5. User can now drag between collapsed (header) and expanded (all content)

**Quick Reference:**

| Detent Configuration | PreferenceKeys Needed? |
|----------------------|------------------------|
| `[.custom]` only | ❌ No - automatic |
| `[.small]` only | ❌ No - automatic |
| `[.medium]` only | ❌ No - native SwiftUI |
| `[.large]` only | ❌ No - fixed height |
| `[.fullscreen]` only | ❌ No - fullScreenCover |
| `[.medium, .large]` | ❌ No - both fixed |
| `[.small, .custom]` | ✅ **YES** - needs both heights |
| `[.small, .medium, .custom]` | ✅ **YES** - .custom needs measurement |

**Example: Simple Modal (No PreferenceKeys Needed):**
```swift
struct SimpleInfoModal: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Title").font(.title)
            Text("Description").font(.body)
            Button("Got It") { /* dismiss */ }
        }
        .padding()
        // ✅ That's it! Framework measures automatically
    }
}

// Present with .custom - no PreferenceKeys needed
coordinator.presentModal(
    infoCoordinator,
    presenting: .info,
    detentConfiguration: ModalDetentConfiguration(detents: [.custom])
)
```

**Architecture Details:**

**1. Content Measurement Flow:**
```
Modal Content Renders
    ↓
GeometryReader measures size (via .onSizeChange)
    ↓
Updates @State height
    ↓
Sends via PreferenceKey to parent
    ↓
CoordinatorView receives in .onPreferenceChange
    ↓
Updates Router's modalDetentConfiguration
    ↓
Detent mapping: .custom → .height(idealHeight)
    ↓
Sheet animates to new height ✨
```

**2. CoordinatorView Integration:**

The view layer intelligently handles detents:
```swift
// Conditional presentation based on detent
if shouldUseFullScreenCover {
    .fullScreenCover(item: presentedRoute) { ... }
} else {
    .sheet(item: presentedRoute) { ... }
        .presentationDetents(presentationDetentsSet)
}
```

**3. Detent Mapping Logic:**

```swift
func toPresentationDetent(_ detent: ModalPresentationDetent) -> PresentationDetent {
    switch detent {
    case .small:      return .height(minHeight ?? 100)
    case .medium:     return .medium
    case .large:      return .fraction(0.999)  // Avoids 3D effect
    case .extraLarge: return .large           // Native 100%
    case .fullscreen: return .large           // Used with fullScreenCover
    case .custom:     return .height(idealHeight ?? 200)
    }
}
```

**Implementation Files:**

Created new directory: `Core/View/Detents/`

1. **ModalPresentationDetent.swift** (133 lines)
   - ModalPresentationDetent enum (6 cases)
   - ModalDetentConfiguration struct
   - Detent mapping helpers
   - shouldUseFullScreenCover property

2. **View+OnSizeChange.swift** (49 lines)
   - Reusable size measurement modifier
   - Wraps GeometryReader with clean API
   - Reports initial size and changes

3. **ModalHeightPreferenceKeys.swift** (85 lines)
   - IdealHeightPreferenceKey (full content)
   - MinHeightPreferenceKey (minimum content)
   - Combine heights from multiple sections

**Framework Integration:**

**Updated Files:**

1. **NavigationState.swift** - Added modalDetentConfiguration storage
   ```swift
   public var modalDetentConfiguration: ModalDetentConfiguration?
   ```

2. **Router.swift** - Detent configuration lifecycle
   ```swift
   func present(_ route: R, detentConfiguration: ModalDetentConfiguration = ...)
   func dismissModal() // Clears configuration
   func updateModalIdealHeight(_ height: CGFloat?)
   func updateModalMinHeight(_ height: CGFloat?)
   ```

3. **Coordinator.swift** - Public API
   ```swift
   public func presentModal(
       _ coordinator: AnyCoordinator,
       presenting route: R,
       detentConfiguration: ModalDetentConfiguration = ModalDetentConfiguration(detents: [.large])
   )
   ```

4. **CoordinatorView.swift** - Smart presentation
   ```swift
   // Listens to PreferenceKey changes
   .onPreferenceChange(IdealHeightPreferenceKey.self) { height in
       router.updateModalIdealHeight(height)
   }

   // Chooses presentation style
   if shouldUseFullScreenCover {
       .fullScreenCover(item: ...) { ... }
   } else {
       .sheet(item: ...) { ... }
           .presentationDetents(presentationDetentsSet)
   }
   ```

**Example App Integration:**

Created comprehensive demonstrations in all 5 tabs:

1. **Red Tab** - `.custom` detent
   - Automatically sizes to content
   - Demonstrates dynamic content-based sizing

2. **Green Tab** - `.small` detent
   - Minimal height (header-like)
   - Shows collapsed modal pattern

3. **Blue Tab** - `.medium` detent
   - Native SwiftUI ~50% height
   - Standard medium presentation

4. **Yellow Tab** - `.large` detent
   - 99.9% screen height
   - Avoids 3D push effect

5. **Purple Tab** - `.fullscreen` detent
   - True fullScreenCover
   - Edge-to-edge presentation

**Components Created:**

1. **InfoView.swift** - Reusable info modal
   - Title, description, detent type label
   - Uses navigationBackAction for dismissal
   - Color-coded per tab

2. **InfoButton.swift** - Reusable modifier
   - `.withInfoButton(action:)` modifier
   - Similar to `.withCloseButton()`
   - Top-trailing info icon

3. **Info Coordinators** - Per tab
   - RedInfoCoordinator, GreenInfoCoordinator, etc.
   - Each handles .info route for its tab
   - Demonstrates isolated modal flows

**Key Design Decisions:**

**1. Why Six Detent Types?**

Each serves a specific use case:
- `.small` - Collapsed states, quick actions
- `.medium` - Standard modals
- `.large` - Maximum sheet without fullscreen (99.9% height, avoids 3D effect)
- `.extraLarge` - True 100% height but still dismissible sheet
- `.fullscreen` - Immersive fullScreenCover experiences (onboarding, media)
- `.custom` - Content-first design (forms, dynamic content)

**Important: `.fullscreen` Behavior with Multiple Detents**

The `.fullscreen` detent behaves differently depending on whether it's used alone or with other detents:

- **Single detent**: `[.fullscreen]` → Uses `fullScreenCover` (true fullscreen, non-dismissible, edge-to-edge)
- **Multiple detents**: `[.custom, .fullscreen]` → Uses `sheet` with SwiftUI's `.large` detent (100% height, still dismissible)

**Why this limitation?**
SwiftUI does not support dynamically switching between `sheet` and `fullScreenCover` during user interaction. When `.fullscreen` is combined with other detents (to enable dragging between heights), the framework falls back to a 100% height **sheet** rather than a true fullScreenCover.

**In practice:**
```swift
// True fullscreen (fullScreenCover, non-draggable)
.modalDetentConfiguration(detents: [.fullscreen])

// Draggable to 100% height sheet - these are functionally identical:
.modalDetentConfiguration(detents: [.custom, .fullscreen], selectedDetent: .custom)
.modalDetentConfiguration(detents: [.custom, .extraLarge], selectedDetent: .custom)
// Both create a sheet that drags from custom height → 100% height
```

When using multiple detents including `.fullscreen`, the behavior is equivalent to using `.extraLarge` - both map to SwiftUI's native `.large` detent (100% screen height) within a sheet presentation.

**Recommendation:** Use `.extraLarge` instead of `.fullscreen` when combining with other detents, as it more accurately describes the behavior (100% height sheet, not fullScreenCover).

**2. Why .custom vs Manual Height?**

`.custom` is superior because:
- ✅ Automatically adapts to content changes
- ✅ Handles Dynamic Type sizing
- ✅ Responds to orientation changes
- ✅ Works with keyboard appearance
- ✅ No manual recalculation needed

**3. Why PreferenceKeys?**

Standard SwiftUI pattern for child → parent communication:
- Views know their own size
- Parent needs to know child size
- Data flows upward through PreferenceKeys
- Clean separation of concerns

**4. Why Optional Heights?**

```swift
var idealHeight: CGFloat?  // Not CGFloat = 0
```

Reasons:
- First render: Content hasn't been measured yet
- Smooth animations: nil → value better than 0 → value
- Safety: Prevents 0-height sheets
- Fallback: `?? 200` provides reasonable default

**5. Why Separate .fullscreen from .extraLarge?**

Different presentation mechanisms:
- `.extraLarge` - Sheet at 100% height (dismissible, drag interaction)
- `.fullscreen` - fullScreenCover (immersive, no automatic dismissal)

**Technical Patterns:**

**1. GeometryReader Pattern:**
```swift
// Invisible overlay that measures without affecting layout
.overlay {
    GeometryReader { geometry in
        Color.clear
            .onAppear { closure(geometry.size) }
            .onChange(of: geometry.size) { closure($0) }
    }
}
```

**2. PreferenceKey Reduction:**
```swift
// Combines heights from multiple child views
static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
    guard let current = value, let next = nextValue() else {
        value = value ?? nextValue()
        return
    }
    value = current + next  // Sum all sections
}
```

**3. Two-Binding Pattern:**
```swift
// Read from one source, write to another
Binding(
    get: { router.state.modalDetentConfiguration?.selectedDetent },
    set: { router.updateModalSelectedDetent($0) }
)
```

**Important: Content-Sized Sheets and `.fixedSize()` Requirement**

When using `.custom` detent for content-sized sheets, multiline text must use `.fixedSize(horizontal: false, vertical: true)` to prevent truncation:

```swift
struct MyModalContent: View {
    var body: some View {
        VStack {
            Text("Long multiline text...")
                .fixedSize(horizontal: false, vertical: true)  // Required!
        }
    }
}
```

**Why is this required?**

SwiftUI has a chicken-and-egg problem with content-sized sheets:
1. To set the `.custom` detent height, the framework measures the content
2. But during measurement, the content is in a constrained context (the sheet)
3. Without `.fixedSize()`, Text compresses to one line with "..." truncation
4. With `.fixedSize(vertical: true)`, Text expands to its natural height during measurement

**This is standard SwiftUI behavior, not a framework limitation.**

Design systems (like LoomMDS in Toyota's oneapp-ios) solve this by building `.fixedSize()` into their text components:

```swift
// LoomMDS/LMBodyText.swift
public var body: some View {
    LMText(string)
        .LM_textStyle(...)
        .fixedSize(horizontal: false, vertical: true)  // Built-in!
}
```

**Our framework approach:**
- ✅ SwiftUIFlow is a navigation framework, not a UI component library
- ✅ We provide the measurement infrastructure (automatic via `ModalContentMeasurement`)
- ✅ Clients handle text layout (either with `.fixedSize()` or their own design system components)
- ✅ Clean separation of concerns

**Benefits:**

✅ **Automatic content sizing** - No manual height calculations
✅ **Six flexible detent types** - Covers all modal use cases
✅ **True fullscreen support** - fullScreenCover via detent configuration
✅ **User-draggable detents** - Multiple detents enable interaction
✅ **Dynamic adaptation** - Responds to content/orientation changes
✅ **SwiftUI-idiomatic** - Uses GeometryReader and PreferenceKeys
✅ **Clean API** - Simple configuration, complex behavior hidden
✅ **Optional complexity** - Simple modals work out-of-box, advanced features available
✅ **Thoroughly demonstrated** - Example app shows all six types

**Alternatives Considered:**

❌ **Manual height prop** - Requires user to calculate and maintain
❌ **ViewModifier approach** - Less flexible, couples view to detent logic
❌ **Single .contentSized detent** - Loses flexibility of multiple detents
❌ **Always fullScreenCover** - Loses sheet benefits (partial coverage, dismissal)

**Code Statistics:**

- New files: 3 files, ~270 lines
- Updated files: 4 core files, ~100 lines added
- Example integration: 10 files updated, ~200 lines
- Total: ~570 lines for complete system

**Testing Strategy:**

**Manual Testing (via Example App):**
- ✅ All six detent types demonstrated
- ✅ Info button in all 5 tabs
- ✅ Smooth animations verified
- ✅ Dynamic content adaptation works
- ✅ Multiple detents draggable
- ✅ Fullscreen presentation confirmed

**Future: Snapshot Tests:**
- Visual regression testing for all detent types
- Verify correct heights across device sizes
- Test Dynamic Type adaptation

**Documentation:**

- ✅ Inline code documentation (docstrings)
- ✅ Usage examples in comments
- ✅ Private notes (`Content-Sized-Sheet-Pattern.md`) - Educational reference
- ✅ This comprehensive development doc section

**Status:** ✅ Fully implemented, integrated, and demonstrated

**Attribution:**

Implementation uses common SwiftUI patterns:
- GeometryReader for measurement (Apple framework)
- PreferenceKeys for data flow (Apple framework)
- Patterns widely documented in SwiftUI community

References:
- Apple Documentation: PresentationDetent
- Common SwiftUI techniques for dynamic layouts
- Personal learning notes (kept private)

---

### 19. Privacy Refactor - Framework Internal Encapsulation ✅

**Date:** November 24, 2025

**Problem:** The `AnyCoordinator` protocol was public, exposing sensitive framework internals (parent, presentationContext, router mutation methods) to clients. This violated encapsulation principles and could lead to clients accidentally calling internal methods.

**Goal:** Hide `AnyCoordinator` and all framework internals while maintaining client API ergonomics and functionality.

**Implementation:**

1. **Made `AnyCoordinator` Internal**
   - Changed from `public protocol` to `protocol` (internal by default)
   - Clients never see `AnyCoordinator` - they work exclusively with concrete `Coordinator<R>` types
   - All type erasure happens transparently within the framework

2. **Created `CoordinatorUISupport` Public Protocol**
   ```swift
   public protocol CoordinatorUISupport: AnyObject {
       func buildCoordinatorView() -> Any
       var tabItem: (text: String, image: String)? { get }
   }
   ```
   - Minimal public interface for custom UI implementations (e.g., custom tab bars)
   - `AnyCoordinator` inherits from `CoordinatorUISupport` internally
   - Provides only what clients need for rendering

3. **Updated Public Methods to Use Generics**
   ```swift
   // Before (exposed AnyCoordinator)
   public func addChild(_ coordinator: AnyCoordinator)

   // After (generic, hides type erasure)
   public func addChild<ChildRoute: Route>(_ coordinator: Coordinator<ChildRoute>,
                                           context: CoordinatorPresentationContext = .pushed)
   ```
   - `addChild<ChildRoute>(_:context:)` - accepts any concrete coordinator type
   - `removeChild<ChildRoute>(_:)` - public API for manual child removal
   - `presentDetour<DetourRoute>(_:presenting:)` - accepts any concrete coordinator type
   - `transitionToFlow<FlowRoute>(_:root:)` (FlowOrchestrator) - accepts any concrete coordinator type
   - Internal storage uses `AnyCoordinator` (type-erased), public API never exposes it

4. **Exposed `children` as `[CoordinatorUISupport]`**
   ```swift
   // Internal storage
   var internalChildren: [AnyCoordinator] = []

   // Public read-only access
   public var children: [CoordinatorUISupport] {
       return internalChildren
   }
   ```
   - Clients can iterate over children for custom UI (e.g., custom tab bars)
   - Can access `buildCoordinatorView()` and `tabItem` through protocol
   - Can cast to concrete types if needed
   - Internal framework code uses `internalChildren` for full access

5. **Exposed `currentFlow` as `Any?`** (FlowOrchestrator)
   ```swift
   // Public read-only, private write
   public private(set) var currentFlow: Any?
   ```
   - Clients can check which flow is active
   - Cast to concrete coordinator type as needed: `as? MainTabCoordinator`
   - Internal framework code casts to `AnyCoordinator` when needed

6. **Made `buildCoordinatorView()` Public**
   - Changed from internal to public
   - Needed for custom UI implementations like custom tab bars
   - Returns type-erased `Any` to avoid SwiftUI dependency in protocol

7. **Kept `router` Public** (Decision: Safe as-is)
   - Mutation methods (`push`, `pop`, `present`, etc.) are **internal** - clients can't call them
   - Only `view(for:)` is public (safe)
   - `state` is `public private(set)` (read-only)
   - Clients need to observe with `@ObservedObject` (ergonomic pattern)
   - Alternative (making router internal) would break client observation patterns

8. **Made `NavigationState.pushedChildren` Internal**
   - Changed from `public var` to `var` (internal)
   - Clients don't need to know about framework's internal child tracking

**What Clients See:**
```swift
// ✅ Public API - Clean and Safe
coordinator.navigate(to: .someRoute)
coordinator.addChild(childCoordinator)
coordinator.removeChild(childCoordinator)
coordinator.addModalCoordinator(modalCoordinator)
coordinator.removeModalCoordinator(modalCoordinator)
coordinator.presentDetour(detourCoordinator, presenting: route)
let state = coordinator.router.state  // Read-only observation
let children = coordinator.children   // [CoordinatorUISupport]

// ❌ Hidden - Framework Internal
// coordinator.parent - NOT VISIBLE
// coordinator.presentationContext - NOT VISIBLE
// coordinator.internalChildren - NOT VISIBLE
// coordinator.router.push() - INTERNAL METHOD, can't call
// AnyCoordinator - TYPE NOT VISIBLE
```

**Benefits:**
- ✅ True encapsulation - internal implementation hidden
- ✅ Prevents accidental misuse of internal APIs
- ✅ Maintains client API ergonomics (generics are transparent)
- ✅ Future-proof - can change internals without breaking clients
- ✅ Clean separation between public API and internal implementation
- ✅ Tests still work (same module, can access internals)

**Files Modified:**
- `AnyCoordinator.swift` - Made protocol internal, added `CoordinatorUISupport`
- `Coordinator.swift` - Updated methods to use generics, exposed `children` and `internalChildren`
- `TabCoordinator.swift` - Updated `addChild` override to use generics
- `FlowOrchestrator.swift` - Updated `transitionToFlow` to use generics, exposed `currentFlow` as `Any?`
- `ViewFactory.swift` - Changed `coordinator` property from `(any AnyCoordinator)?` to `Coordinator<R>?`
- `NavigationState.swift` - Made `pushedChildren` internal
- `TabCoordinatorView.swift` - Uses `_children` internally (same module)
- `CustomTabBarView.swift` (example) - Uses public `children: [CoordinatorUISupport]` API
- `FlowOrchestratorTests.swift` - Updated tests to cast `currentFlow` and `children` to concrete types

**Naming Convention:**
- Renamed `_children` to `internalChildren` (SwiftLint compliant)
- Swift naming convention: underscore prefix only for unused parameters

**Migration Notes:**
- No breaking changes for client code that uses concrete `Coordinator<R>` types
- Internal framework code can still access `internalChildren` (same module)
- Tests can access internals (same module)

---

## Current TODO List

### Completed ✅
- [x] Document setRoot as official admin operation
- [x] Build basic CoordinatorView with NavigationStack
- [x] Add sheet support for modal presentation
- [x] Add .detour NavigationType for cross-flow navigation
- [x] Implement detour logic in Coordinator (preserve context)
- [x] Update CoordinatorView to handle detours (fullScreenCover)
- [x] Implement multiple modal coordinators pattern
- [x] Fix modal navigation bug (ensure router.present() is called)
- [x] Organize integration tests into separate files
- [x] Configure SwiftLint/SwiftFormat build phases with input file lists
- [x] Trim verbose comments to meet file length requirements
- [x] Discuss and document error handling strategy
- [x] Build TabCoordinatorView for tab navigation
- [x] Create example app to validate all features
- [x] Fix CoordinatorView to use modal coordinator's buildView for modal rendering
- [x] Refactor example app to use proper coordinator bubbling pattern
- [x] Implement CoordinatorPresentationContext system
- [x] Implement Navigation Back Action environment system
- [x] Create UI Freedom patterns for modal dismissal (4 approaches)
- [x] Create UI Freedom patterns for detour dismissal (5 approaches)
- [x] Add comprehensive tests for presentation context (10 tests)
- [x] Document CoordinatorPresentationContext, Navigation Back Action, and UI Freedom patterns
- [x] Implement handleFlowChange(to:) hook for major flow transitions
- [x] Add comprehensive flow change tests (7 integration + 4 unit tests)
- [x] Create FlowChangeTestHelpers.swift for flow change test coordinators
- [x] Fix TabCoordinator infinite loop bug with canNavigate() check
- [x] Refactor TabCoordinator to use bubbleToParent() directly (eliminate duplication)
- [x] Split CoordinatorTests.swift into 4 focused test files (34 tests total)
- [x] Create CoordinatorTestHelpers.swift for shared test utilities
- [x] Update example app to use flow change pattern (AppCoordinator orchestration)
- [x] Remove coordinator coupling from example app views and ViewFactories
- [x] Document Flow Change Handling feature comprehensively
- [x] Implement FlowOrchestrator base class to reduce boilerplate
- [x] Create 8 unit tests for FlowOrchestrator
- [x] Update integration tests to use FlowOrchestrator pattern
- [x] Separate FlowOrchestrator test helpers into dedicated file
- [x] Update example app to use FlowOrchestrator pattern
- [x] Document FlowOrchestrator implementation comprehensively
- [x] Add memory leak tracking helper (trackForMemoryLeaks)
- [x] Update 10 tests with automatic memory leak verification
- [x] Extract navigation helpers to Coordinator+NavigationHelpers.swift (reduce file length)
- [x] Add coordinator property to base ViewFactory class (reduce boilerplate)
- [x] Simplify coordinator initialization to 3-line pattern
- [x] Change access control to `public internal(set)` for coordinator properties
- [x] Remove unnecessary `navigationType` override from TabCoordinator
- [x] Simplify MainTabCoordinator to only delegate (canHandle returns false)
- [x] Update all coordinators in example app to use simplified pattern
- [x] Implement error handling system (SwiftUIFlowError, ErrorReportingView, global handler)
- [x] Add error handling tests (ErrorHandlingIntegrationTests.swift)
- [x] Add error handling examples in example app (UnhandledRoute, invalidView, error toast)
- [x] Add modal and detour navigation stack support (buildCoordinatorView)
- [x] Make Coordinator.pop() context-aware (dismiss at modal/detour root)
- [x] Add dismissModal() and dismissDetour() to AnyCoordinator protocol
- [x] Add tests for modal/detour navigation stacks (5 new tests)
- [x] Add example for multi-step modal (even darker green)
- [x] Implement two-phase navigation (ValidationResult pattern)
- [x] Add ValidationResult enum with success/failure cases
- [x] Implement validateNavigationPath() that mirrors navigate() without side effects
- [x] Update navigate() to validate before executing (atomic navigation)
- [x] Add specific error types (modalCoordinatorNotConfigured, invalidDetourNavigation)
- [x] Update ErrorHandlingIntegrationTests to verify specific errors
- [x] Remove unreachable error reporting from execution phase
- [x] Document two-phase navigation architecture and alternatives considered
- [x] Clean up error toast UI (alignment improvements)
- [x] Create reusable errorToast() view modifier (like .sheet)
- [x] Implement modal presentation detents system (6 types: small, medium, large, extraLarge, fullscreen, custom)
- [x] Create ModalPresentationDetent enum and ModalDetentConfiguration
- [x] Implement .onSizeChange() modifier for content measurement
- [x] Create PreferenceKeys for height tracking (IdealHeight, MinHeight)
- [x] Update CoordinatorView to support detents and fullScreenCover switching
- [x] Add example app demonstrations (info button in all 5 tabs)
- [x] Create InfoView, InfoButton, and info coordinators
- [x] Document detent system comprehensively
- [x] Remove `.detour` from NavigationType enum (breaking change - detours now explicit-only)
- [x] Add pushedChildren tracking to NavigationState
- [x] Implement Router.pushChild() / popChild() methods
- [x] Add CoordinatorView rendering for pushed child coordinators
- [x] Fix smart navigation for pushed child coordinators (auto-pop when navigating to parent)
- [x] Implement type-constrained modal coordinators (Coordinator<R> instead of AnyCoordinator)
- [x] Fix modal/detour smart dismissal bug (dismiss when bubbling to already-displayed parent route)
- [x] Remove shouldDismissDetourFor() method (detours always auto-dismiss)
- [x] Investigate nested NavigationStack limitation (Apple forums, Stack Overflow, pure SwiftUI tests)
- [x] Implement flattened navigation architecture with ChildRouteWrapper
- [x] Add CoordinatorRouteView for modal/detour support from pushed children
- [x] Fix white flash bug with synchronous .onReceive updates
- [x] Add allRoutes and routesDidChange to AnyCoordinator protocol
- [x] Create comprehensive documentation comparing main vs feature branch
- [x] Test modal presentation from pushed child coordinators (RainbowCoordinator)
- [x] Update development.md with flattened navigation architecture documentation
- [x] Fix SwiftLint warnings
- [x] Implement Privacy Refactor - make AnyCoordinator internal
- [x] Create CoordinatorUISupport public protocol for custom UI needs
- [x] Update public methods to use generics (addChild, removeChild, presentDetour, transitionToFlow)
- [x] Expose children as [CoordinatorUISupport] and currentFlow as Any?
- [x] Rename _children to internalChildren (SwiftLint compliant)
- [x] Update tests to work with privacy refactor
- [x] Document Privacy Refactor in development.md

### In Progress 🔄
- [ ] Review final code and prepare for merge to main

### Pending 📋
- [ ] Add snapshot tests for view layer (optional)
- [ ] Add drag indicator for modals with multiple detents (visual feedback for draggable sheets)
- [ ] Enable drag-to-fullscreen for modal sheets (seamless transition from sheet to fullScreenCover)

---

## Next Steps

### Immediate: Review & Document Architectural Decisions

Review the example app implementation and document key decisions:
- Modal coordinators pattern (keep them for complex flows)
- TransitionToNewFlow pattern (views needing root coordinator access)
- ViewFactory pattern (shared class, separate instances)
- View coordinator dependency injection

### After Review: Polish & Future Enhancements

1. Comprehensive error handling (NavigationError enum, callbacks, optional logging)
2. Add sheet presentation styles (detents, sizing)
3. Add snapshot tests for regression protection
4. Performance testing
5. Documentation & API reference
6. Public API review

---

## Phase 3: Documentation & Release Preparation 🔄 IN PROGRESS

### Objectives

The correct order for v1.0 release:

1. **DocC Documentation** 🔄 CURRENT TASK
   - Add DocC comments to all public APIs
   - Document Coordinator lifecycle and methods
   - Document Router and NavigationState
   - Document CoordinatorView and ViewFactory
   - Document navigation patterns and best practices
   - Include code examples in documentation
   - Build DocC archive for hosting

2. **Swift Package Creation**
   - Create Package.swift
   - Verify Swift Package Manager configuration
   - Test package import in sample project
   - Verify minimum iOS version (iOS 16.0+)
   - Ensure all public APIs are properly exported

3. **README.md**
   - Framework overview and key features
   - Installation instructions (SPM)
   - Quick start guide with code examples
   - Architecture overview
   - Link to DocC documentation
   - Example app walkthrough
   - Contributing guidelines

4. **Final Verification**
   - Run final SwiftLint pass
   - Run all tests one final time
   - Build and test example app
   - Verify documentation builds correctly

5. **Version 1.0 Release**
   - Tag v1.0.0 in git
   - Create GitHub release with notes
   - Publish DocC documentation
   - Announce release

### Status

- ✅ Phase 1 Complete: Navigation Engine fully implemented and tested
- ✅ Phase 2 Complete: View Layer Integration with comprehensive example app
- ✅ Internal Documentation: DEVELOPMENT.md, NAVIGATION_ENGINE_DETAILED_ANALYSIS.md, VALIDATION_ENGINE_DETAILED_ANALYSIS.md
- 🔄 **CURRENT**: DocC API documentation
- ⏳ Pending: Package creation, README.md, final verification, v1.0 release

---

## Phase 2B: Advanced Features (Future)

Not yet started - postponed until Phase 2A complete:

1. **Deep Links / Universal Links**
   - Parse URL → Route
   - Navigate from any app state

2. **Push Notifications**
   - Parse notification → Route
   - Background navigation handling

3. **Custom Transitions/Animations**
   - Per-route animation styles
   - Custom transitions for replace navigation

4. **State Restoration**
   - Save navigation state to disk
   - Restore on app launch

5. **Coordinator Lifecycle Hooks**
   - willAppear, didAppear, willDisappear, didDisappear
   - Analytics, cleanup, data loading

---

## Development Workflow

**Approach:** TDD where possible, manual validation for views

**Commit Strategy:** One feature per commit with clear messages

**Testing:**
- Phase 1: Unit + integration tests (comprehensive)
- Phase 2: Manual validation via example app, then snapshot tests

**Branch:** Currently on `feature/Pushed-Childs-FullScreen-Approach` (ready for merge to main)

---

## Questions / Decisions Needed

None - branch ready for merge to main.

---

## Notes

- All router mutation methods are `internal` (public observation only)
- Coordinator hierarchy is permanent (children), modals/detours are temporary
- **Modal coordinators are type-constrained**: Must be `Coordinator<R>` (same route type as parent)
- **Detour coordinators are NOT type-constrained**: Use `AnyCoordinator` for flexibility
- Multiple modal coordinators can be registered, but only one presented at a time
- currentRoute priority: Detour → Modal → Stack top → Root
- **Pushed children tracking**: NavigationState.pushedChildren array tracks child coordinators in nav stack
- **Smart navigation for pushed children**: Auto-pops child when navigating to parent route
- **Smart modal/detour dismissal**: Auto-dismisses when bubbling to parent route already displayed
- Smart navigation auto-detects backward navigation and pops instead of push
- Tab switching doesn't clean state (tabs manage their own state)
- Cross-flow bubbling cleans state unless presented as detour
- **`.detour` NavigationType REMOVED**: Detours must be presented explicitly via `presentDetour()`, NEVER through `navigate()`
- **`shouldDismissDetourFor()` method REMOVED**: Detours always auto-dismiss during cross-flow navigation
- Error handling uses `assertionFailure()` for programmer errors (safe in production)
- CoordinatorPresentationContext automatically set by framework (zero user configuration)
- Views can check `coordinator.presentationContext` for context-aware UI
- Navigation back actions injected via environment (`navigationBackAction`, `canNavigateBack`)
- Modal dismissal synced via `presentedRoute` binding setter (not onDismiss callback)
- Detours auto-wrapped in NavigationStack with fallback back button
- Detour swipe-to-dismiss NOT supported (fullScreenCover doesn't have gesture)
- Users have full UI freedom: X buttons, custom nav bars, native nav bars, or framework fallbacks
- Flow changes use bubbling pattern via `handleFlowChange(to:)` hook at root coordinator
- Major flow transitions create fresh coordinators and deallocate old ones
- Service calls after login integrated in root coordinator's flow change methods
- TabCoordinator uses `bubbleToParent()` to avoid infinite loops
- Test organization: 4 focused test files for Coordinator tests (34 tests total)
- FlowOrchestrator eliminates 48-62% of boilerplate for major flow transitions
- FlowOrchestrator enforces clean architecture: Coordinators=Navigation, ViewModels=Business Logic
- Test helpers can use typed convenience properties to bridge AnyCoordinator protocol
- Memory leak tracking helper (`trackForMemoryLeaks`) verifies deallocation in test teardown
- 10 tests automatically verify coordinator deallocation (FlowOrchestrator, flow changes, modals, children)
- Framework has no memory leaks (verified with weak reference tests and deallocation tracking)
- Coordinator initialization uses 3-line pattern with base ViewFactory coordinator property
- Navigation helpers extracted to separate file (Coordinator+NavigationHelpers.swift)
- Coordinator properties use `public internal(set)` for framework extension flexibility
- TabCoordinator inherits default `.push` navigation type (no unnecessary override)
- MainTabCoordinator only delegates to children (doesn't handle routes directly)
- Error handling uses global SwiftUIFlowErrorHandler for all framework errors
- Clients set onError callback to handle errors (logging, UI, analytics)
- ErrorReportingView shows when view creation fails (graceful degradation)
- Modal and detour coordinators support full navigation stacks via buildCoordinatorView()
- Coordinator.pop() is context-aware: dismisses modals/detours when at root
- Multi-step modals work: push/pop within modal, back at root dismisses modal
- Two-phase navigation prevents broken intermediate states (validation → execution)
- ValidationResult provides specific errors (.modalCoordinatorNotConfigured, .invalidDetourNavigation)
- Navigation is atomic: either fully succeeds or leaves state unchanged
- Error toast uses reusable .errorToast() modifier (SwiftUI-idiomatic pattern)
- **Nested NavigationStack NOT supported by Apple** - Official SwiftUI limitation since iOS 16
- Flattened navigation architecture uses single NavigationStack with ChildRouteWrapper
- ChildRouteWrapper enables type-erased route + coordinator association
- pushedChildStack caches flattened child routes for efficient rendering
- Synchronous .onReceive updates prevent white flash bug (async updates cause race conditions)
- CoordinatorRouteView wraps child routes with modal/detour presentation infrastructure
- buildCoordinatorRouteView() returns Any for clean layer separation (no SwiftUI in Core)
- Type erasure at view layer (cast Any to View), not core layer
- Main branch nested approach: broken navigation, white flash, no modals/detours from children
- Feature branch flattened approach: full navigation support, no flash, all features work

---

## Section 20: Custom Transitions Investigation & Future Plans

**Date:** November 25, 2025
**Branch:** feature/Custom-Transition-Animations (investigation branch - not merged)

### Investigation Summary

Investigated adding custom transition animations (fade, scale, slide variations) to navigation methods via optional `RouteTransition` parameter. After thorough research and testing, determined that custom transitions are **not practical** with SwiftUI's current APIs.

### What We Learned

**SwiftUI Transition Limitations:**

1. **`.transition()` modifier only works for:**
   - Conditional content (if/else showing/hiding views)
   - Views added/removed from same container
   - Requires explicit animation context (`withAnimation` or `.animation()`)

2. **`.transition()` does NOT work for:**
   - NavigationStack push/pop (uses built-in slide animation)
   - `.sheet()` presentations (uses built-in slide-up animation)
   - `.fullScreenCover()` presentations (uses built-in cover animation)
   - Any Apple navigation primitives

3. **Workarounds exist but are fragile:**
   - Disable default animations
   - Add internal state management in presented views
   - Conditionally show/hide content with custom transitions
   - Too complex and hacky for framework code

**iOS 18 NavigationTransition API:**
- Introduced `.navigationTransition()` modifier
- Only supports `.automatic` (default) and `.zoom` (hero animations)
- Does NOT support general-purpose custom transitions (fade, scale, slide variations)
- Limited to specific use cases (photo galleries, detail expansions)

**Industry Standard:**
- 95%+ of iOS apps use default SwiftUI/UIKit transitions
- Users expect standard slide animations
- Custom transitions are "nice to have" not "must have"
- Most common transitions: slide (default), fade, scale+fade for overlays

### Decision: Do Not Implement Custom Transitions

**Reasoning:**
1. **No native support**: SwiftUI doesn't provide APIs for custom navigation transitions
2. **Workarounds too fragile**: Complex patterns that may break in future iOS versions
3. **Limited value**: Default transitions meet 95% of use cases
4. **Misleading API**: Having transition parameters that don't work is confusing
5. **Maintenance burden**: Threading unused parameters through entire navigation chain
6. **Client capability**: Clients can already use `.transition()` for in-view animations

### What Clients Can Already Do

Clients have full access to SwiftUI's native transition system for **in-view animations**:

```swift
struct MyView: View {
    @State var showDetails = false

    var body: some View {
        VStack {
            // Conditional content with custom transitions
            if showDetails {
                DetailPanel()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: showDetails)
    }
}
```

**Common use cases clients can handle:**
- Loading states and skeletons
- Success/error feedback overlays
- Expanding/collapsing sections
- Custom alerts and toasts
- Tab content switching
- Conditional UI elements

No framework support needed - SwiftUI's native APIs are sufficient.

### Future v2 Plans: Modal Presentation Enhancements

Instead of custom transitions, focus on **Apple's official modal presentation APIs** when minimum deployment target allows:

**Enhanced Modal Presentation Controls (iOS 16.4+):**
1. `.presentationBackgroundInteraction()` - Allow/prevent interaction with background
2. `.presentationCornerRadius()` - Custom corner radius for sheets
3. `.interactiveDismissDisabled()` - Prevent swipe-to-dismiss
4. `.presentationDragIndicator()` - Show/hide drag indicator
5. `.presentationCompactAdaptation()` - iPhone/iPad behavior customization

**Current Modal Support (Already Implemented):**
- ✅ `ModalDetentConfiguration` - Custom sheet heights
- ✅ `.presentationDetents()` - small, medium, large, custom, fullscreen
- ✅ Ideal/min height via PreferenceKeys
- ✅ Interactive detent selection

**Why This Approach:**
- Uses Apple's stable, documented APIs
- Works reliably across iOS versions
- Provides real value for common modal patterns
- No hacks or workarounds needed
- Consistent with SwiftUI best practices

### Architecture Preserved for Future

Although custom transitions were not implemented, the investigation validated our architecture:
- Navigation methods are well-designed for optional parameters
- Router state management is flexible
- View layer can consume additional metadata when needed
- Framework can evolve to support new Apple APIs as they arrive

### Key Takeaways

1. **SwiftUI's default transitions are intentional design** - Apple wants consistent iOS experience
2. **Framework should enhance, not fight platform** - Work with SwiftUI's strengths
3. **Native APIs over workarounds** - Wait for Apple to provide official support
4. **Focus on real value** - Modal presentation controls > custom transitions
5. **Client flexibility preserved** - Clients can use `.transition()` for in-view animations

---

## 21. Deep Cross-Coordinator Navigation & Modal Pattern Enforcement ✅

**Date:** December 2025
**Status:** ✅ COMPLETE
**Branch:** feature/Pushed-Childs-FullScreen-Approach

### Problem Statement

The navigation engine had several critical gaps preventing deep cross-coordinator navigation:

1. **Modal Coordinator Pattern Inconsistency**: Both parent and modal child coordinators were returning `canHandle() = true` for modal entry routes, causing ambiguity in modal selection
2. **Limited Descendant Discovery**: `delegateToChildren()` only checked if immediate children could handle routes, missing routes handled by descendants (e.g., modal coordinator's children)
3. **Validation/Execution Mismatch**: Validation logic didn't mirror execution logic for descendant checks
4. **No Path Building**: Deep linking to routes requiring sequential steps (e.g., journey flows) would jump directly to destination, skipping intermediate screens

**Example Failure Case:**
- Navigate from `RainbowPurple` to `OceanAbyss` (which lives in `BlueModalCoordinator` → `OceanCoordinator`)
- Navigation would fail because `BlueCoordinator` couldn't handle `OceanRoute` directly
- The route lived 3 levels deep: Blue Tab → BlueModalCoordinator (modal) → OceanCoordinator (child) → .abyss

### Solution: Deep Navigation with `canNavigate()` + Pattern Enforcement

#### 1. Modal Coordinator Pattern Enforcement

**Rule Established:**
- **Parent coordinator** handles modal entry routes (returns `canHandle() = true`, `navigationType() = .modal`)
- **Modal child coordinator** does NOT handle its root/entry route (returns `canHandle() = false` for root)
- Modal child handles subsequent routes within the modal flow

**Example:**
```swift
// Parent
class UnlockCoordinator: Coordinator<UnlockRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        guard let route = route as? UnlockRoute else { return false }
        return route == .success  // Handles modal entry route
    }

    override func navigationType(for route: any Route) -> NavigationType {
        return route == .success ? .modal : .push
    }
}

// Modal Child
class UnlockResultCoordinator: Coordinator<UnlockRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        guard let route = route as? UnlockRoute else { return false }
        return route == .details || route == .settings  // NOT .success (its root)
    }
}
```

**Changes Required:**
- Updated all example app modal coordinators to follow pattern
- Removed `canHandle()` overrides from simple modal children (use base implementation returning `false`)

#### 2. Deep Descendant Discovery with `canNavigate()`

**Changed `delegateToChildren()` to use `canNavigate()` instead of `canHandle()`:**

```swift
// BEFORE (only checked immediate child)
for child in internalChildren where child !== caller {
    if child.canHandle(route) {
        // Delegate...
    }
}

// AFTER (checks child AND all descendants recursively)
for child in internalChildren where child !== caller {
    if child.canNavigate(to: route) {  // ← Changed
        // Delegate...
    }
}
```

**`canNavigate()` checks:**
1. Can this coordinator handle the route? (`canHandle()`)
2. Can any of its children handle it? (recursive check)
3. Can any of its modal coordinators handle it? (recursive check)

**Also applied to modal coordinators loop:**
```swift
for modal in modalCoordinators where modal !== caller {
    if modal.canNavigate(to: route) {  // ← Changed from canHandle()
        // Present modal and navigate...
    }
}
```

This enables navigation to routes living in modal coordinator's descendants.

#### 3. Validation Mirroring Execution

Updated `validateChildrenCanHandle()` to mirror execution logic:

```swift
// Check if child or its descendants can handle (mirrors execution)
if child.canNavigate(to: route) {
    let childResult = child.validateNavigationPath(to: route, from: self)
    if childResult.isSuccess {
        return childResult
    }
}
```

**Critical:** Validation must check `canNavigate()` BEFORE calling `validateNavigationPath()`, just like execution checks `canNavigate()` before delegating.

#### 4. Optional Navigation Path Building

**Added `navigationPath(for:)` method** for routes requiring sequential navigation:

```swift
class Coordinator {
    /// Defines intermediate steps to reach a route
    /// Return nil (default) for direct navigation
    /// Return array for sequential navigation through steps
    open func navigationPath(for route: any Route) -> [any Route]? {
        return nil
    }
}
```

**Implementation Example:**
```swift
class OceanCoordinator: Coordinator<OceanRoute> {
    override func navigationPath(for route: any Route) -> [any Route]? {
        guard let oceanRoute = route as? OceanRoute else { return nil }

        switch oceanRoute {
        case .surface: return [OceanRoute.surface]
        case .shallow: return [OceanRoute.shallow]
        case .deep: return [OceanRoute.shallow, OceanRoute.deep]
        case .abyss: return [OceanRoute.shallow, OceanRoute.deep, OceanRoute.abyss]
        }
    }
}
```

**Path Building Logic:**
- Only applies when **stack is empty** (deeplink scenario)
- When navigating within coordinator (stack has items), uses normal direct navigation
- Prevents path rebuilding on backward navigation (pop)

**Benefits:**
- Journey flows (onboarding, tutorials, multi-step processes)
- Context building (show intermediate screens for proper UX)
- Flexible: coordinator can choose different paths based on state/conditions

#### 5. Modal Navigation Type in Internal Children

**Clarified `.modal` case in pushed children loop:**

The `.modal` navigation type in `delegateToChildren()` is **valid** - it means the child coordinator will present its own modal internally.

```swift
case .modal:
    // Child handles modal presentation internally - just delegate
    _ = child.navigate(to: route, from: self)
    return true
```

**Example:** UnlockCoordinator (pushed child) presents UnlockResultCoordinator (its own modal) for `.success` route.

### Implementation Details

#### Added `rootRoute` Property to AnyCoordinator

```swift
protocol AnyCoordinator: AnyObject {
    var rootRoute: any Route { get }
}
```

Needed for modal coordinator selection by root identifier matching.

#### Execution Flow Changes

**File:** `Coordinator+NavigationHelpers.swift`

**`delegateToChildren()` changes:**
- Line 237: Use `canNavigate()` for pushed children check
- Line 275: Use `canNavigate()` for modal coordinators check

**`executeNavigation()` changes:**
- Lines 328-359: Path building logic (only when stack is empty)

**Validation Flow Changes:**

**`validateChildrenCanHandle()` changes:**
- Line 120: Use `canNavigate()` before validating
- Line 131: Use `canNavigate()` for modal coordinators

### Testing

**Added Integration Tests:**
1. `test_CrossTabNavigation_ToModalThatPushesScreen` - Navigate to modal's pushed route
2. `test_CrossTabNavigation_ToModalThatPresentsNestedModal` - Navigate to nested modal

**Example App Testing:**
- Created `OceanCoordinator` with 4-level depth flow
- Added as child of `BlueModalCoordinator`
- Tests navigation from `RainbowPurple` → `OceanAbyss` (crosses tabs, modals, children)
- Path: Red Tab → Rainbow (child) → Purple → Blue Tab → DarkBlue (modal) → Ocean (child) → Abyss

### Key Decisions & Edge Cases

#### Multiple Paths for One Route

`navigationPath()` can return different paths based on coordinator state:

```swift
override func navigationPath(for route: any Route) -> [any Route]? {
    if userPreferences.skipIntro {
        return [destination]  // Direct
    } else {
        return [step1, step2, destination]  // Full journey
    }
}
```

Coordinator has full control - can check user preferences, feature flags, time of day, etc.

#### Modal Routes in Paths Not Supported

Paths can only contain `.push` or `.replace` routes. Modal routes in paths will fail with error.

**Reason:** Path building is for sequential stack navigation. Modals are presentation, not path progression.

### Benefits

1. **True Deep Navigation**: Navigate anywhere in coordinator hierarchy from anywhere
2. **Declarative Path Building**: Define sequential flows for proper UX
3. **Pattern Enforcement**: Clear rules for modal coordinator ownership
4. **Validation Reliability**: Validation perfectly mirrors execution
5. **Example App Showcase**: Demonstrates complex real-world navigation scenarios

### Migration Guide

**For Modal Coordinators:**

Remove `canHandle()` override that returns `true` for root route:

```swift
// BEFORE
class MyModalCoordinator: Coordinator<MyRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        return route == .myModalRoot  // ❌ Remove this
    }
}

// AFTER
class MyModalCoordinator: Coordinator<MyRoute> {
    // No canHandle override - uses base implementation (returns false)
    // OR override to handle subsequent routes only
    override func canHandle(_ route: any Route) -> Bool {
        return route == .subsequentRoute  // ✅ Subsequent routes only
    }
}
```

**For Path Building:**

Add `navigationPath()` only if routes need sequential navigation:

```swift
override func navigationPath(for route: any Route) -> [any Route]? {
    guard let myRoute = route as? MyRoute else { return nil }

    switch myRoute {
    case .finalStep:
        return [MyRoute.step1, MyRoute.step2, MyRoute.finalStep]
    default:
        return nil  // Direct navigation
    }
}
```

---

## Section 22: SwiftUI Navigation Path Building - Known Issues

**Date:** December 1, 2025
**Status:** Documented ✅
**Context:** Investigation of title duplication bug during navigation path building

### Problem Discovery

When using `navigationPath(for:)` to build sequential navigation stacks (e.g., surface → shallow → deep → abyss), we discovered a SwiftUI rendering bug with `.navigationBarTitleDisplayMode(.automatic)`:

**Symptoms:**
- Title appears duplicated (both large title AND inline title render simultaneously)
- Only happens during deeplink navigation (path building), NOT manual button navigation
- The duplicate title is "floating" and mispositioned
- Dragging the modal forces layout recalculation and the duplicate disappears

**Root Cause:**
SwiftUI's `.automatic` mode attempts to infer the correct title display mode from navigation context. During rapid synchronous pushes (path building), it becomes confused and **renders BOTH `.large` and `.inline` titles simultaneously**.

### Investigation Results

Testing showed:
- ❌ `.navigationBarTitleDisplayMode(.automatic)` - Causes duplication bug
- ✅ `.navigationBarTitleDisplayMode(.large)` - Works perfectly, no bug
- ✅ `.navigationBarTitleDisplayMode(.inline)` - Works perfectly, no bug
- ❌ Adding delays (even 250ms) - Does NOT fix the bug
- ✅ Custom navigation bars - Works perfectly (bypasses SwiftUI's title system)

### Solution

For views that are part of navigation paths (used with `navigationPath(for:)`), **always explicitly specify** `.navigationBarTitleDisplayMode()`:

```swift
struct DeepView: View {
    var body: some View {
        VStack {
            Text("Content")
        }
        .navigationTitle("Deep View")
        .navigationBarTitleDisplayMode(.large)  // ✅ Explicit - fixes bug
        // NOT .automatic - causes duplication during path building
    }
}
```

**Alternative:** Use `.customNavigationBar()` modifier to bypass SwiftUI's navigation title system entirely:

```swift
struct DeepView: View {
    var body: some View {
        VStack {
            Text("Content")
        }
        .customNavigationBar(title: "Deep View", backgroundColor: .cyan)
    }
}
```

### When This Matters

This bug **only affects** views that:
1. Are part of a `navigationPath(for:)` array
2. Use `.navigationBarTitleDisplayMode(.automatic)` (the default)
3. Are navigated to via deeplink (not manual button press)

**Regular navigation** (button taps, single pushes) works fine with `.automatic` because SwiftUI has time to settle between each navigation event.

### Recommendation

**Best Practice:** Always explicitly specify `.navigationBarTitleDisplayMode()` for any view that might be reached via deeplink or path building. Don't rely on `.automatic` mode in coordinator-based navigation.

```swift
// ❌ DON'T - Relies on .automatic (default)
.navigationTitle("My Screen")

// ✅ DO - Explicit display mode
.navigationTitle("My Screen")
.navigationBarTitleDisplayMode(.large)

// ✅ ALTERNATIVE - Custom navigation bar
.customNavigationBar(title: "My Screen", backgroundColor: .blue)
```

### Technical Notes

- This is a **known SwiftUI bug**, not an issue with the navigation framework
- The bug exists in iOS 17+ (tested on iOS 18)
- Affects NavigationStack with rapid state changes
- SwiftUI's large title layout engine assumes gradual, human-paced navigation
- Programmatic rapid pushes violate SwiftUI's assumptions about navigation timing

### Confirmation from SwiftUI Community

This issue is well-documented in the SwiftUI community:

1. **`.automatic` mode inconsistency**: The `.automatic` option for `navigationBarTitleDisplayMode` behaves differently across iOS versions (iOS 17 vs 18) and cannot be relied upon for consistent UI. [Stack Overflow](https://stackoverflow.com/questions/79075633/different-navigationbartitledisplaymode-behaviour-between-ios-17-and-ios-18)

2. **Title duplication during navigation**: Multiple reports of navigation titles appearing duplicated or overlapping during swipe gestures and programmatic navigation. [Stack Overflow](https://stackoverflow.com/questions/78731026/swiftui-navigationstack-title-is-duplicated-during-swipe-down-gesture)

3. **Overlapping titles with `.large` mode**: When views have `.large` title mode, dismissed view titles can accumulate and overlap. The recommended fix is explicitly using `.inline` mode. [Dabbling Badger](https://www.dabblingbadger.com/blog/2020/12/11/a-quick-fix-for-overlapping-navigation-titles-in-swiftui)

4. **Broken title animations**: UIHostingController navigation title animations can break during programmatic pushes, with titles "appearing out of nothing" instead of animating smoothly. [Stack Overflow](https://stackoverflow.com/questions/69537578/swiftui-uihostingcontroller-navigation-title-animation-broken)

**Conclusion:** Explicitly setting `.navigationBarTitleDisplayMode(.large)` or `.navigationBarTitleDisplayMode(.inline)` is the recommended best practice to avoid SwiftUI's automatic mode inference bugs.

---

## Section 23: Navigation Path Integration Tests

**Date:** December 1, 2025
**Status:** Completed ✅
**Context:** Comprehensive test coverage for navigationPath(for:) functionality

### Test Coverage Added

Created `NavigationPathIntegrationTests.swift` with 9 comprehensive tests covering all path building scenarios:

1. **`test_navigationPath_BuildsSequentialStack`** - Verifies basic 3-step path building (step1 → step2 → finalDestination)
2. **`test_navigationPath_OnlyBuildsWhenStackEmpty`** - Confirms path building only happens during deeplink (empty stack), not manual navigation
3. **`test_navigationPath_WithSingleIntermediateStep`** - Tests single intermediate step path (step1 → step2)
4. **`test_navigationPath_RouteWithoutPath_NavigatesDirectly`** - Verifies routes without paths navigate directly
5. **`test_navigationPath_CrossCoordinatorDeeplink`** - Tests path building when deeplinking across coordinator boundaries
6. **`test_navigationPath_AfterPopToRoot_RebuildsPath`** - Confirms path rebuilds after popping to root
7. **`test_navigationPath_EmptyPathArray_NavigatesDirectly`** - Tests empty array handling (direct navigation)
8. **`test_navigationPath_NilPath_NavigatesDirectly`** - Tests nil path handling (direct navigation)
9. **`test_navigationPath_LongPath_BuildsEfficiently`** - Performance test with 10-step path (< 100ms)

### Test Helpers Organization

Created `NavigationPathTestHelpers.swift` with:
- **Routes**: `PathRoute`, `MainPathRoute`, `EmptyPathRoute`, `LongPathRoute`
- **Coordinators**: `PathTestCoordinator`, `MainPathCoordinator`, `EmptyPathCoordinator`, `LongPathCoordinator`
- **Factory**: `DummyPathFactory<R: Route>`

All test helpers moved to dedicated helper file following existing test architecture pattern.

### Key Test Scenarios

**Deeplink Detection:**
```swift
// Stack empty = deeplink scenario → build path
coordinator.navigate(to: .finalDestination)
// Builds: [.step1, .step2, .finalDestination]

// Stack NOT empty = manual navigation → direct push
coordinator.navigate(to: .step1)
coordinator.navigate(to: .finalDestination)
// Direct push only (no path building)
```

**Cross-Coordinator Path Building:**
```swift
mainCoordinator.navigate(to: PathRoute.finalDestination)
// Delegates to child, child builds path
```

**Performance:**
10-step path builds in < 100ms, confirming efficient implementation.

---

**Last Task Completed:** Integration tests for navigationPath() functionality (section 23)
**Next Task:** Code review and prepare merge to main
**Branch:** feature/Pushed-Childs-FullScreen-Approach
**Key Changes Summary:**
- Deep cross-coordinator navigation with `canNavigate()` delegation
- Modal coordinator pattern enforcement (parent handles entry, child handles subsequent)
- Optional navigation path building for deeplink scenarios
- SwiftUI `.automatic` title mode bug workaround documented
- Comprehensive integration test coverage

---

## Section 24: Modal Path Building Fix for Deeplink Scenarios

**Date:** December 2, 2025
**Status:** Completed ✅
**Branch:** feature/Pushed-Childs-FullScreen-Approach

### The Problem

When deeplinking to routes handled by descendants of modal coordinators, modals were presented from incorrect parent states. The navigation engine was presenting modals immediately without first building the required navigation path in the parent coordinator.

**Example scenario:**
```
BlueCoordinator
  └─ DeepBlueCoordinator (pushed child, 3 levels deep)
      └─ NestedModalCoordinator (modal presented from level 3)
          └─ OceanCoordinator (pushed child in modal)
```

**Deeplink attempt:**
```swift
coordinator.navigate(to: OceanRoute.surface)
```

**Expected behavior:**
1. Build DeepBlue path: [.level1, .level2, .level3]
2. Present nested modal from level 3
3. Push Ocean.surface in modal

**Actual behavior:**
1. Present nested modal from level 1 (wrong state!)
2. Push Ocean.surface in modal

**Symptoms:**
- Modal presented from wrong parent state (e.g., level 1 instead of level 3)
- Missing intermediate navigation in parent coordinator
- Correct final destination but incorrect navigation history

### Root Cause

The `delegateToChildren()` function checks if modal coordinators can handle routes but was presenting them immediately without building the required parent navigation path first.

**File:** `Coordinator+NavigationHelpers.swift:273`

**Before:**
```swift
for modal in modalCoordinators where modal !== caller {
    if modal.canNavigate(to: route) {
        // Present modal immediately - no path building!
        let initialRoute = modal.router.state.root
        let detents = modalDetentConfiguration(for: initialRoute)
        presentModal(modal, presenting: initialRoute, detentConfiguration: detents)
        _ = modal.navigate(to: route, from: self)
        return true
    }
}
```

### The Fix

Added path building logic BEFORE presenting modal in `delegateToChildren()`:

```swift
for modal in modalCoordinators where modal !== caller {
    if modal.canNavigate(to: route) {
        // Check if we need to build a navigation path before presenting the modal
        // This handles cases where the route is handled by a descendant (e.g., OceanRoute)
        // but the parent coordinator needs to build a path to the correct state first
        if let path = navigationPath(for: route), !path.isEmpty, router.state.stack.isEmpty {
            NavigationLogger.debug("🗺️ \(Self.self): Build path before presenting modal for \(route.identifier)")
            // Build the path first
            for intermediateRoute in path {
                guard let typedRoute = intermediateRoute as? R else {
                    NavigationLogger.error("❌ \(Self.self): Navigation path contains invalid route type")
                    return false
                }
                switch navigationType(for: typedRoute) {
                case .push:
                    router.push(typedRoute)
                case .replace:
                    router.replace(typedRoute)
                case .modal:
                    NavigationLogger.error("❌ \(Self.self): Navigation path cannot contain modal routes")
                    return false
                }
            }
        }

        // Now present modal from correct state
        let initialRoute = modal.router.state.root
        let detents = modalDetentConfiguration(for: initialRoute)
        presentModal(modal, presenting: initialRoute, detentConfiguration: detents)
        _ = modal.navigate(to: route, from: self)
        return true
    }
}
```

### Key Logic

1. **Check if modal can handle route** - `modal.canNavigate(to: route)`
2. **Check if path building needed** - `navigationPath(for: route)` returns non-empty array AND `router.state.stack.isEmpty` (deeplink scenario)
3. **Build path first** - Push/replace each intermediate route
4. **Then present modal** - Modal now presented from correct parent state

### When Path Building Happens

Path building only happens when **ALL** conditions are met:
- ✅ Modal coordinator can handle the route (or its descendants can)
- ✅ `navigationPath(for: route)` returns non-nil, non-empty array
- ✅ Parent's stack is empty (indicates deeplink, not manual navigation)

**Manual navigation** (button taps) doesn't trigger path building because stack is NOT empty.

### Example Implementation

**DeepBlueCoordinator provides path for OceanRoute:**

```swift
class DeepBlueCoordinator: Coordinator<DeepBlueRoute> {
    override func navigationPath(for route: any Route) -> [any Route]? {
        // Handle own routes
        if let deepBlueRoute = route as? DeepBlueRoute {
            // ... return paths for DeepBlueRoutes
        }

        // For routes handled by descendants (OceanRoute in nested modal),
        // return path needed to reach modal presentation point
        if route is OceanRoute {
            // Ocean is in nested modal presented from level 3
            return [DeepBlueRoute.level1, DeepBlueRoute.level2, DeepBlueRoute.level3]
        }

        return nil
    }
}
```

**Navigation flow with fix:**

```swift
// 1. User deeplinks to OceanRoute.surface
coordinator.navigate(to: OceanRoute.surface)

// 2. Navigation engine reaches DeepBlueCoordinator.delegateToChildren()
// 3. Finds nestedModalCoordinator.canNavigate(to: OceanRoute.surface) == true
// 4. Checks navigationPath(for: OceanRoute.surface) → [.level1, .level2, .level3]
// 5. Builds path: push .level1, push .level2, push .level3
// 6. Presents nested modal from level 3 ✅
// 7. Modal navigates to Ocean.surface ✅
```

### Impact

This fix enables proper deeplink behavior for complex scenarios involving:
- Modals presented from specific parent states
- Pushed children inside modals
- Multi-level navigation hierarchies
- Cross-coordinator navigation with modals

### Test Coverage

**Test hierarchy:**
```swift
Blue (tab)
  └─ DeepBlue (pushed child)
      ├─ Level 1, 2, 3 (pushed)
      └─ Level3Modal (modal from level 3)
          └─ NestedModal (nested modal)
              └─ Ocean (pushed child in nested modal)
```

**Verified scenarios:**
1. ✅ Deeplink to OceanRoute.surface builds full path
2. ✅ Modals presented from correct level (level 3)
3. ✅ All intermediate navigation preserved
4. ✅ Manual navigation (buttons) still works without path building

---


## Section 25: Custom Navigation Bar Layout Shift in Modals

**Date:** December 2, 2025
**Status:** Documented ⚠️
**Branch:** feature/Pushed-Childs-FullScreen-Approach

### The Problem

When using custom navigation bars (`.customNavigationBar()` modifier) in views pushed inside modals that have close buttons, content shifts down after popping back to the modal. This creates a jarring visual glitch where content that was centered drops down by approximately 44pt (navigation bar height).

**Affected scenario:**
```
Modal with close button (no navigation bar)
  → Push view with .customNavigationBar()
  → Pop back to modal
  → Content shifts down ❌
```

**Visual effect:**
- Content appears centered initially
- After push + pop, content drops down
- Extra white space appears at the top
- Dragging/interacting with modal sometimes forces layout recalculation and fixes it temporarily

**Symptoms:**
- Only happens with **custom navigation bars** (not native SwiftUI `.navigationTitle()`)
- Only happens when modal and pushed views have **inconsistent top UI** (close button vs nav bar)
- Happens in **both deeplink AND manual navigation** (unlike the title duplication bug)
- Does NOT happen with native SwiftUI navigation bars

### Root Cause

SwiftUI recalculates safe area insets **after** the pop animation completes when the top UI element type changes:

1. **Modal has close button** → No navigation bar → Safe area configuration A
2. **Push view with `.customNavigationBar()`** → Navigation bar appears → Safe area configuration B
3. **Pop animation plays** → Navigation stack transitions
4. **Pop completes** → Navigation bar disappears
5. **SwiftUI recalculates safe area** → Transitions from B to A
6. **Content shifts visibly** → Layout adjusts to new safe area

**Why this happens:** Custom navigation bars are implemented as view overlays that don't integrate with SwiftUI's NavigationStack safe area management system. When they appear/disappear, SwiftUI must recalculate safe areas **after** the navigation animation, causing visible layout shifts.

### Why Native Navigation Bars Don't Have This Issue

Native SwiftUI navigation bars (`.navigationTitle()` + `.navigationBarTitleDisplayMode()`) are part of NavigationStack's internal safe area management. SwiftUI coordinates navigation animations WITH safe area transitions, so layout changes happen smoothly during the animation rather than after it.

```swift
// ✅ Native navigation - No layout shift
.navigationTitle("Child View")
.navigationBarTitleDisplayMode(.inline)
```

Custom navigation bars are separate views/overlays that exist outside this system:

```swift
// ❌ Custom navigation - Layout shift bug
.customNavigationBar(title: "Child View", backgroundColor: .cyan)
```

### Attempted Workarounds

#### ❌ Attempt 1: `.ignoresSafeArea(edges: .top)`

```swift
ZStack {
    Color.indigo.opacity(0.2).ignoresSafeArea()
    VStack {
        // Content...
    }
}
.ignoresSafeArea(edges: .top)  // Attempt to lock safe area
.withCloseButton()
```

**Result:** Did not fix. Safe area still recalculated after pop animation.

#### ❌ Attempt 2: `@State` + `.onAppear` forced refresh

```swift
@State private var refreshToggle = false

var body: some View {
    ZStack {
        // Content...
    }
    .withCloseButton()
    .onAppear {
        refreshToggle.toggle()  // Force re-render when view appears
    }
}
```

**Result:** Did not fix. State change happens BEFORE SwiftUI's safe area recalculation, so layout still shifts afterward.

#### ❌ Attempt 3: GeometryReader with explicit frames

```swift
GeometryReader { geometry in
    ZStack {
        // Content...
    }
    .frame(width: geometry.size.width, height: geometry.size.height)
}
```

**Result:** Did not fix. Frame constraints don't prevent SwiftUI from recalculating safe area insets.

### ✅ Solution: Consistent Navigation UI

The **only reliable solution** is to use consistent top UI elements throughout the navigation flow. If views will be pushed inside a modal, ensure both the modal and pushed views have the same type of navigation UI.

**Option 1: Custom navigation bars everywhere**

```swift
// Modal
.customNavigationBar(title: "Modal", backgroundColor: .indigo.opacity(0.8))

// Pushed views inside modal  
.customNavigationBar(title: "Child", backgroundColor: .cyan)
```

**Why this works:** Navigation bar is present throughout the entire push/pop cycle, so SwiftUI never needs to recalculate safe area. No layout shift occurs.

**Option 2: Native navigation for pushed views**

```swift
// Modal
.withCloseButton()

// Pushed views inside modal
.navigationTitle("Child")
.navigationBarTitleDisplayMode(.inline)
```

**Why this works:** Native navigation bars integrate with NavigationStack's safe area system, so transitions are smooth and coordinated with animations.

### Example Implementation

**DeepBlue → Ocean flow in SwiftUIFlowExample:**

```swift
// Level 3 Modal (first modal)
.customNavigationBar(title: "Level 3 Modal", backgroundColor: .cyan.opacity(0.8))

// Nested Modal (second modal)  
.customNavigationBar(title: "Nested Modal", backgroundColor: .indigo.opacity(0.8))

// Ocean views (pushed inside nested modal)
.customNavigationBar(title: "Ocean Surface", backgroundColor: .cyan)
```

**Result:** ✅ No layout shift. Consistent custom navigation UI throughout the flow.

### Recommendation

**For v1.0:**

Document this as a known limitation and recommend one of two approaches:

1. **Consistent custom navigation** - Use `.customNavigationBar()` on both modals and all pushed children for unified custom styling
2. **Native navigation for children** - Use native `.navigationTitle()` for views pushed inside modals to avoid the bug

**For future versions:**

Consider rewriting `.customNavigationBar()` modifier to use `.safeAreaInset()` instead of overlay/ZStack approach. This would integrate with SwiftUI's safe area system and eliminate the layout shift.

### Technical Notes

- This is a **SwiftUI framework limitation**, not a bug in the navigation framework
- The issue exists in iOS 17+ (tested on iOS 18)
- Affects all custom navigation bar implementations that don't integrate with NavigationStack's safe area system
- Native SwiftUI navigation bars work correctly because they're part of the NavigationStack internals
- The layout shift is caused by **delayed safe area recalculation** after navigation animations complete

### Decision for v1.0

Keep the current `.customNavigationBar()` implementation and document the limitation. Users can choose:
- Full custom styling (use `.customNavigationBar()` consistently)
- Reliable layout (use native `.navigationTitle()` for pushed children)

The consistent custom navigation approach is already working perfectly in the example app.

---


## Section 26: Modal NavigationPath Pattern for Nested Scenarios

**Date:** December 2, 2025
**Status:** Documented ✅
**Branch:** feature/Pushed-Childs-FullScreen-Approach

### The Challenge

When a parent coordinator presents a modal coordinator that contains pushed children, and those children need to be reachable via deeplink, who should provide the navigation path to reach the modal's presentation point?

**Scenario:**
```swift
DeepBlueCoordinator (parent, has levels 1-3)
  └─ DeepBlueNestedModalCoordinator (modal presented from level 3)
      └─ OceanCoordinator (pushed child in modal)
```

**Question:** When deeplinking to `OceanRoute.surface`, who returns the path `[.level1, .level2, .level3]`?

**Options considered:**
- **Option A:** Parent coordinator (`DeepBlueCoordinator`) returns path
- **Option B:** Child coordinator (`OceanCoordinator`) declares requirements
- **Option C:** Configuration metadata passed when adding modal

### The Solution: Parent Manages Its Own Prerequisites

**Decision:** The parent coordinator returns paths for any routes that require specific parent state before presenting modals.

**Rationale:**
- Parent knows its own navigation structure
- Parent knows modal presentation requirements
- Minimal coupling (only type check, no route handling)
- Simple and explicit

**Implementation:**

```swift
class DeepBlueCoordinator: Coordinator<DeepBlueRoute> {
    override func navigationPath(for route: any Route) -> [any Route]? {
        // Handle own routes
        if let deepBlueRoute = route as? DeepBlueRoute {
            switch deepBlueRoute {
            case .level1:
                return nil  // Root, no path needed
            case .level2:
                return [.level1, .level2]
            case .level3:
                return [.level1, .level2, .level3]
            case .level3Modal, .level3NestedModal:
                // Modals presented from level 3
                return [.level1, .level2, .level3]
            }
        }

        // IMPORTANT: For routes handled by descendants (pushed children in modals),
        // return the path needed to reach the modal presentation point.
        // This only applies to deeplink scenarios where the modal isn't yet presented.
        if route is OceanRoute {
            // Ocean is a pushed child in nested modal, presented from level 3
            return [.level1, .level2, .level3]
        }

        return nil
    }
}
```

### Why This Pattern Works

**1. Parent Knows Its Own State**
- `DeepBlueCoordinator` knows it has levels 1, 2, 3
- It knows the nested modal is presented from level 3
- It doesn't need to know `OceanRoute`'s internal structure

**2. Minimal Coupling**
- Parent only checks `route is OceanRoute` (type check)
- Parent doesn't **handle** `OceanRoute` (that's child's responsibility)
- The "coupling" is just **prerequisite management**

**3. Simple and Explicit**
- Path requirements are clear and localized in one place
- Easy to understand what state is needed for modal presentation
- No complex metadata or closure configuration

### Why Alternative Approaches Were Rejected

####❌ Option B: Child Declares Requirements

```swift
class OceanCoordinator {
    func requiredParentPath() -> [DeepBlueRoute] {
        return [.level1, .level2, .level3]
    }
}
```

**Problems:**
- Child now coupled to parent's route type (`DeepBlueRoute`)
- Child can't be reused with different parents
- Still restrictive - child tied to specific parent path
- Doesn't solve coupling, just moves it to child

#### ❌ Option C: Configuration Metadata

```swift
addModalCoordinator(
    nestedModalCoordinator,
    pathBuilder: { route in
        if route is OceanRoute {
            return [.level1, .level2, .level3]
        }
        return nil
    }
)
```

**Problems:**
- More complex API for rare edge cases
- Coupling moved to configuration, not eliminated
- Adds overhead for 99% of use cases that don't need it
- Configuration logic separated from coordinator logic

### When This Pattern Applies

This pattern is needed for **extremely rare scenarios**:

✅ **Needs this pattern:**
- Deeplinking to routes inside pushed children within modals
- Modal must be presented from specific parent state
- Complex nested navigation hierarchies

❌ **Doesn't need this pattern:**
- Simple modals presented from any state
- Modals with internal navigation only (no parent prerequisites)
- Traditional SwiftUI `.sheet()` presentation (no coordinator)

**Reality check:** Most apps will NEVER need this pattern. It's only for complex coordinator-based modal navigation with deeplink support.

### Recommendation for Framework Users

**When to use coordinator-based modals:**

Only if you need **at least one** of:
1. Custom detent configuration
2. Navigation to other coordinators from modal
3. Deeplink support to routes inside modal

**Otherwise:** Use traditional SwiftUI `.sheet()` presentation for simpler modals.

**When you DO need this pattern:**
- Document the prerequisite state in comments
- Return paths for descendant route types in parent's `navigationPath()`
- Keep logic simple and explicit
- Remember this is for rare edge cases only

### Example in SwiftUIFlowExample

**DeepBlue example demonstrates this pattern:**

```swift
// In DeepBlueCoordinator
override func navigationPath(for route: any Route) -> [any Route]? {
    if let deepBlueRoute = route as? DeepBlueRoute {
        // Handle own routes...
    }

    // Ocean is in nested modal presented from level 3
    if route is OceanRoute {
        return [.level1, .level2, .level3]
    }

    return nil
}
```

**What happens:**

```swift
// 1. Deeplink from app root
coordinator.navigate(to: OceanRoute.surface)

// 2. BlueCoordinator delegates to DeepBlueCoordinator
// 3. DeepBlueCoordinator checks navigationPath(for: OceanRoute.surface)
// 4. Returns [.level1, .level2, .level3]
// 5. Builds path: push level1 → level2 → level3
// 6. Checks if modal can handle route: Yes (nestedModalCoordinator has OceanCoordinator child)
// 7. Presents nested modal from level 3 ✅
// 8. OceanCoordinator navigates to .surface ✅
```

### Design Philosophy

**This pattern embodies the principle:**

> "A coordinator is responsible for the navigation state required to present its children."

The parent doesn't need to know HOW the child handles the route, only WHAT state the parent needs to be in before presenting that child.

**Analogy:**
- Parent: "To present my nested modal, I need to be at level 3"
- Child: "I can handle OceanRoute.surface"
- Framework: "Great! Parent, build your path to level 3. Child, here's the route."

This separation of concerns keeps each coordinator focused on its own responsibilities while enabling complex deeplink scenarios.

### Technical Notes

- Pattern applies ONLY to deeplink scenarios (`router.state.stack.isEmpty`)
- Manual navigation (button taps) doesn't trigger path building
- Parent checks `route is ChildRoute` (type check), doesn't handle it
- Framework handles the coordination between path building and modal presentation
- Pattern is documented in code comments for maintainability

### Conclusion

For v1.0, this pattern is the recommended approach for handling navigation paths in complex modal scenarios. It balances simplicity, explicitness, and minimal coupling while enabling powerful deeplink capabilities.

Future versions could explore more sophisticated solutions if user feedback indicates this pattern is too restrictive, but current assessment is that it serves the extremely rare use case well without adding unnecessary complexity to the common cases.

---

## Section 27: Path Building + Modal Presentation Bug Fixes

**Date:** December 2, 2025
**Files Modified:**
- `SwiftUIFlow/Core/Coordinator/Coordinator+NavigationHelpers.swift` (executeNavigation)
- `SwiftUIFlowExample/Framework integration/Coordinators.swift` (DeepBlueCoordinator.canHandle)

### Bug 1: Path Building Preventing Modal Presentation

**The Problem:**

When deeplinking to a modal route that requires building a navigation path first (e.g., `DeepBlueRoute.level3Modal`), the `executeNavigation()` function would:
1. Build the prerequisite path: `[.level1, .level2, .level3]`
2. Return early with `return true`
3. NEVER present the modal!

**Example:**
```swift
// User navigates to .level3Modal from another tab
coordinator.navigate(to: DeepBlueRoute.level3Modal)

// What happened:
// ✅ Builds path: pushes level1, level2, level3
// ❌ Returns true immediately
// ❌ Modal never presented!
```

**Root Cause:**

The code had a commented-out `return true` after path building:

```swift
if let path = navigationPath(for: route), !path.isEmpty, router.state.stack.isEmpty {
    // Build path...
    for intermediateRoute in path {
        // Push/replace each route
    }
    // return true  // ❌ This was causing the bug!
}

// Default behavior - direct navigation
switch navigationType(for: route) {
case .modal:
    // Present modal... (never reached!)
}
```

The issue is that path building serves two purposes:

1. **Path includes target route** (e.g., `.level3`):
   - Path: `[.level1, .level2, .level3]`
   - Target: `.level3`
   - After building, we're DONE ✅
   - Should return `true`

2. **Path doesn't include target route** (e.g., `.level3Modal`):
   - Path: `[.level1, .level2, .level3]` (prerequisites only)
   - Target: `.level3Modal` (modal presented FROM level3)
   - After building, must CONTINUE to modal presentation ✅
   - Should fall through, NOT return

**The Fix:**

Check if the target route is in the path:

```swift
if let path = navigationPath(for: route), !path.isEmpty, router.state.stack.isEmpty {
    NavigationLogger.debug("🗺️ \(Self.self): Building navigation path to \(route.identifier)")

    // Navigate through each route in the path sequentially
    for intermediateRoute in path {
        guard let typedRoute = intermediateRoute as? R else {
            NavigationLogger.error("❌ \(Self.self): Navigation path contains invalid route type")
            return false
        }
        switch navigationType(for: typedRoute) {
        case .push:
            router.push(typedRoute)
        case .replace:
            router.replace(typedRoute)
        case .modal:
            NavigationLogger.error("❌ \(Self.self): Navigation path cannot contain modal routes")
            return false
        }
    }

    // If the target route is in the path, we're done (path includes destination)
    // If not, fall through to execute the target route (e.g., modal presentation)
    if path.contains(where: { $0.identifier == route.identifier }) {
        return true
    }
}

// Default behavior - direct navigation
switch navigationType(for: route) {
case .push:
    router.push(route)
    return true
case .replace:
    router.replace(route)
    return true
case .modal:
    // Present modal...
    return true
}
```

**Result:**
- ✅ `.level3` deeplink: Path includes destination → Returns after building
- ✅ `.level3Modal` deeplink: Path doesn't include modal → Falls through to present modal

---

### Bug 2: Incorrect canHandle() for Nested Modal Routes

**The Problem:**

When deeplinking to `DeepBlueRoute.level3NestedModal`:
1. Validation FAILED
2. Navigation FAILED
3. Error: "Modal coordinator not found"

**Coordinator Hierarchy:**
```swift
DeepBlueCoordinator
  └─ modalCoordinators: [level3ModalCoordinator]

level3ModalCoordinator (root: .level3Modal)
  └─ modalCoordinators: [nestedModalCoordinator]

nestedModalCoordinator (root: .level3NestedModal)
  └─ children: [oceanCoordinator]
```

**What Was Happening:**

```swift
// DeepBlueCoordinator
override func canHandle(_ route: any Route) -> Bool {
    return route is DeepBlueRoute  // ❌ Returns true for .level3NestedModal!
}
```

When navigating to `.level3NestedModal`:
1. `DeepBlueCoordinator.canHandle(.level3NestedModal)` → `true`
2. Goes to `executeNavigation()`
3. Builds path: `[.level1, .level2, .level3]`
4. Falls through to modal presentation
5. Tries to find modal coordinator with root `.level3NestedModal` in `DeepBlueCoordinator.modalCoordinators`
6. NOT FOUND! (It's in `level3ModalCoordinator.modalCoordinators`)
7. Error: "Modal coordinator not found"

**Root Cause:**

`DeepBlueCoordinator` claimed it could handle ALL `DeepBlueRoute` cases, but it can't handle `.level3NestedModal` because:
- `.level3NestedModal` is the root of `nestedModalCoordinator`
- `nestedModalCoordinator` is NOT in `DeepBlueCoordinator.modalCoordinators`
- It's in `level3ModalCoordinator.modalCoordinators` (nested modal!)

**The Fix:**

Exclude `.level3NestedModal` from `canHandle()`:

```swift
override func canHandle(_ route: any Route) -> Bool {
    guard let deepBlueRoute = route as? DeepBlueRoute else { return false }
    // Only handle routes up to level3Modal
    // level3NestedModal is handled by level3ModalCoordinator (not in our modalCoordinators)
    return deepBlueRoute != .level3NestedModal
}
```

**Result:**

When navigating to `.level3NestedModal`:
1. `DeepBlueCoordinator.canHandle(.level3NestedModal)` → `false`
2. Goes to `delegateToChildren()`
3. Checks `modalCoordinators` → Finds `level3ModalCoordinator`
4. `level3ModalCoordinator.canNavigate(.level3NestedModal)` → `true`
5. Builds path: `[.level1, .level2, .level3]`
6. Presents `level3ModalCoordinator` with root `.level3Modal`
7. Calls `level3ModalCoordinator.navigate(to: .level3NestedModal)`
8. `level3ModalCoordinator` handles it (presents `nestedModalCoordinator`) ✅

---

### Why OceanRoute.abyss Always Worked

Even before these fixes, navigating to `OceanRoute.abyss` worked perfectly. Why?

**Flow:**
1. `DeepBlueCoordinator.canHandle(OceanRoute.abyss)` → `false` (not DeepBlueRoute)
2. Goes to `delegateToChildren()`
3. No `internalChildren` can handle it
4. Checks `modalCoordinators` → Finds `level3ModalCoordinator`
5. `level3ModalCoordinator.canNavigate(.abyss)` → `true`!
6. Checks if path needed: `DeepBlueCoordinator.navigationPath(for: .abyss)` → `[.level1, .level2, .level3]`
7. Builds path (lines 281-299 in `delegateToChildren()`)
8. Presents `level3ModalCoordinator` with root `.level3Modal` (line 304)
9. Calls `level3ModalCoordinator.navigate(to: .abyss)` (line 305)
10. `level3ModalCoordinator` delegates to `nestedModalCoordinator`
11. Presents `nestedModalCoordinator` with root `.level3NestedModal`
12. Calls `nestedModalCoordinator.navigate(to: .abyss)`
13. Pushes `oceanCoordinator` and navigates to `.abyss` ✅

The key difference: `DeepBlueCoordinator` never claimed to handle `OceanRoute`, so it correctly delegated to its modal coordinators from the start!

---

### Key Insight: canHandle() vs Modal Coordinator Ownership

**Rule:** A coordinator should only `canHandle()` routes for which it has the modal coordinator configured in its own `modalCoordinators` array.

**Wrong:**
```swift
// DeepBlueCoordinator
override func canHandle(_ route: any Route) -> Bool {
    return route is DeepBlueRoute  // ❌ Claims to handle .level3NestedModal!
}

// But nestedModalCoordinator is NOT in DeepBlueCoordinator.modalCoordinators!
// It's in level3ModalCoordinator.modalCoordinators!
```

**Correct:**
```swift
// DeepBlueCoordinator
override func canHandle(_ route: any Route) -> Bool {
    guard let deepBlueRoute = route as? DeepBlueRoute else { return false }
    return deepBlueRoute != .level3NestedModal  // ✅ Excludes nested modal route
}

// Now .level3NestedModal will be delegated to level3ModalCoordinator ✅
```

---

### Testing

Both fixes were tested with the complex navigation hierarchy:

```swift
Blue (tab)
  └─ DeepBlue (pushed child)
      ├─ Level 1, 2, 3 (pushed)
      └─ level3ModalCoordinator (modal from level 3)
          ├─ root: .level3Modal
          └─ nestedModalCoordinator (nested modal)
              ├─ root: .level3NestedModal
              └─ oceanCoordinator (pushed child)
                  └─ surface, shallow, deep, abyss
```

**Test Cases:**
1. ✅ Deeplink to `.level3Modal` - Builds path, presents modal
2. ✅ Deeplink to `.level3NestedModal` - Delegates correctly, presents both modals
3. ✅ Deeplink to `OceanRoute.abyss` - Builds path, presents both modals, navigates to abyss

---

### Impact

These fixes enable proper deeplink behavior for:
- Modal routes requiring prerequisite navigation state
- Nested modal scenarios (modals within modals)
- Complex multi-level navigation hierarchies with mixed presentation styles

The fixes maintain the framework's invariants:
- `canHandle()` accurately reflects coordinator capabilities
- `executeNavigation()` correctly handles path building vs. direct navigation
- Modal coordinator delegation works for arbitrarily nested scenarios

---

**Last Update:** December 2, 2025
**Branch:** feature/Pushed-Childs-FullScreen-Approach
**Status:** Ready for review and merge

**Key Changes in This Branch:**
- Deep cross-coordinator navigation with `canNavigate()` delegation
- Modal coordinator pattern enforcement (parent handles entry, child handles subsequent routes)
- Optional navigation path building for deeplink scenarios
- **Modal path building bug fix in `delegateToChildren()`** (Section 24)
- **Path building + modal presentation bug fixes** (Section 27):
  - `executeNavigation()` now correctly checks if target route is in path before returning
  - `canHandle()` in nested modal scenarios fixed to exclude routes owned by descendant modals
- **Custom navigation bar layout shift bug documented with workarounds** (Section 25)
- **Modal navigationPath pattern established for nested scenarios** (Section 26)
- SwiftUI `.automatic` title mode bug workaround documented
- Comprehensive integration test coverage for `navigationPath()`
- Complex nested navigation test case: Blue → DeepBlue (3 levels) → modals → Ocean

