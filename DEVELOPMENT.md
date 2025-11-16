# SwiftUIFlow - Development Progress

**Last Updated:** November 16, 2025

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
2. **NavigationState** - State container (root, stack, selectedTab, presented, currentRoute, pushedChildren)
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
- `currentModalCoordinator: AnyCoordinator?` - the one currently presented (type-erased)
- Modal navigation finds coordinator via `canHandle()`, then presents it
- Only one modal presented at a time
- **Smart modal dismissal**: Modals auto-dismiss when they bubble to parent route already displayed

**Type Constraint Rationale:**
- Ensures modal coordinators can handle same routes as parent
- Compile-time safety for modal registration
- Parent and modal share same route enum for seamless navigation
- Detours are NOT type-constrained (use AnyCoordinator) for flexibility

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
       public weak var coordinator: (any AnyCoordinator)?
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
   public protocol AnyCoordinator: AnyObject {
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
   public var pushedChildren: [AnyCoordinator]
   ```

2. **Router.pushChild() / popChild()** - Methods to manage pushed children
   ```swift
   func pushChild(_ coordinator: AnyCoordinator)
   func popChild()
   ```

3. **CoordinatorView Integration** - Renders pushed children coordinators
   - Uses `buildCoordinatorView()` to get child's full navigation view
   - Child coordinators have their own NavigationStack
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
public func navigate(to route: any Route, from caller: AnyCoordinator? = nil) -> Bool {
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
- `.large` - Maximum sheet without fullscreen
- `.extraLarge` - True 100% height but still dismissible
- `.fullscreen` - Immersive experiences (onboarding, media)
- `.custom` - Content-first design (forms, dynamic content)

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
- [x] Update development.md with all branch changes
- [x] Fix SwiftLint warnings

### In Progress 🔄
- [ ] Merge branch to main

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

**Branch:** Currently on `feature/Navigation-Engine-Missing-Implementation-For-Childs` (ready for merge to main)

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

---

**Last Task Completed:** Updated development.md with all changes from feature/Navigation-Engine-Missing-Implementation-For-Childs branch
**Next Task:** Merge branch to main
**Branch:** feature/Navigation-Engine-Missing-Implementation-For-Childs
