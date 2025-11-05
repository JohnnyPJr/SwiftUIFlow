# SwiftUIFlow - Development Progress

**Last Updated:** November 5, 2025

---

## Project Overview

SwiftUIFlow is a coordinator-based navigation framework for SwiftUI that provides:
- Hierarchical navigation management
- Type-safe routing
- Smart backward navigation
- Deeplinking with context preservation (detours)
- Tab-based navigation support
- Multiple modal coordinator registration

---

## Phase 1: Navigation Engine ✅ COMPLETE

### What Was Built

**Core Components:**
1. **Route Protocol** - Type-safe navigation destinations
2. **NavigationState** - State container (root, stack, selectedTab, presented, currentRoute)
3. **Router** - Observable state machine managing navigation mutations
4. **NavigationType** - Enum defining navigation strategies (.push, .replace, .modal, .tabSwitch)
5. **Coordinator** - Navigation orchestration with smart features
6. **TabCoordinator** - Specialized coordinator for tab-based navigation
7. **AnyCoordinator** - Type-erased protocol for coordinator hierarchy

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
- ✅ Proper access control (public router for observation, internal mutation methods)
- ✅ Input file lists configured for build phase dependency tracking

---

## Phase 2: View Layer Integration 🔄 IN PROGRESS

### What's Been Built

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
   - Added `.detour` case to NavigationType enum
   - Implemented `presentDetour()` and `dismissDetour()` in Coordinator
   - Detours must be presented explicitly (not through navigate())
   - Automatic detour dismissal during cross-flow navigation
   - FullScreenCover presentation (slides from right, preserves context)
   - Integration tests for detour bubbling and dismissal

4. **Multiple Modal Coordinators** ✅
   - Changed from single modal coordinator to `modalCoordinators` array
   - Multiple modal coordinators can be registered per coordinator
   - Only one presented at a time via `currentModalCoordinator`
   - Modal navigation finds appropriate coordinator via `canHandle()`
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
    - Public API: `transitionToFlow(_ coordinator: AnyCoordinator, root: R)`
    - Property: `currentFlow: AnyCoordinator?` - the currently active flow coordinator
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

### 4. Cross-Flow Navigation: .detour Pattern

**Problem:** Deep linking across coordinators wipes navigation context

**Example:**
- User at: Tab2 → UnlockCoordinator → EnterCode → Loading → Failure
- Deep link: Navigate to ProfileSettings (different coordinator)
- Desired: Push ProfileSettings, back button returns to Failure
- Problem: Without detours, bubbling up cleans state

**Solution:** `.detour` NavigationType
- Presents as fullScreenCover (slides from right like push)
- Preserves underlying navigation context
- Auto-dismisses during cross-flow navigation (via shouldDismissDetourFor)
- Must be presented explicitly via `presentDetour()`, NOT through `navigate()`
- Returns assertionFailure if `.detour` returned from `navigationType(for:)`

**Implementation Details:**
- `detourCoordinator` property holds the currently presented detour
- `handleDetourNavigation()` checks detour first, similar to modal handling
- Default `shouldDismissDetourFor()` returns true (always dismiss)
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

### 7. Multiple Modal Coordinators Pattern

**Decision:** Support multiple modal coordinator registration per coordinator

**Pattern:**
```swift
let mainCoordinator = MainCoordinator(...)
let profileModalCoord = ProfileModalCoordinator(...)
let settingsModalCoord = SettingsModalCoordinator(...)

mainCoordinator.addModalCoordinator(profileModalCoord)
mainCoordinator.addModalCoordinator(settingsModalCoord)

// When navigating to a modal route, framework finds the right coordinator
mainCoordinator.navigate(to: .profile)  // Uses profileModalCoord
mainCoordinator.navigate(to: .settings) // Uses settingsModalCoord
```

**Implementation:**
- `modalCoordinators: [AnyCoordinator]` - array of registered modal coordinators
- `currentModalCoordinator: AnyCoordinator?` - the one currently presented
- Modal navigation finds coordinator via `canHandle()`, then presents it
- Only one modal presented at a time

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
    public private(set) var currentFlow: AnyCoordinator?

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
    public func transitionToFlow(_ coordinator: AnyCoordinator, root: R) {
        // 1. Deallocate old flow
        if let current = currentFlow {
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

### In Progress 🔄
- [ ] Review and polish Phase 2 implementation

### Pending 📋
- [ ] Comprehensive error handling (NavigationError enum, callbacks, logging)
- [ ] Add sheet presentation styles (detents, custom sizing)
- [ ] Add snapshot tests for view layer (optional)

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

**Branch:** Currently on `origin/Add-View-layer` (will merge to main after Phase 2A complete)

---

## Questions / Decisions Needed

None currently - proceeding with TabCoordinatorView implementation.

---

## Notes

- All router mutation methods are `internal` (public observation only)
- Coordinator hierarchy is permanent (children), modals/detours are temporary
- Multiple modal coordinators can be registered, but only one presented at a time
- currentRoute priority: Detour → Modal → Stack top → Root
- Smart navigation auto-detects backward navigation and pops instead of push
- Tab switching doesn't clean state (tabs manage their own state)
- Cross-flow bubbling cleans state unless presented as detour
- Detours must be presented explicitly via `presentDetour()`, NOT through `navigate()`
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

---

**Last Task Completed:** Added memory leak tracking helper and updated 10 tests with automatic verification
**Next Task:** Review and polish Phase 2 implementation
**Branch:** origin/Add-View-layer
