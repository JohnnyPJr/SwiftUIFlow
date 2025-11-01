# SwiftUIFlow - Development Progress

**Last Updated:** October 31, 2025

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

### In Progress 🔄
- [ ] Build TabCoordinatorView for tab navigation

### Pending 📋
- [ ] Create example app to validate all features
- [ ] Comprehensive error handling (NavigationError enum, callbacks, logging)
- [ ] Add sheet presentation styles (detents, custom sizing)
- [ ] Add snapshot tests for view layer (optional)

---

## Next Steps

### Immediate: Build TabCoordinatorView

Build specialized view for TabCoordinator:
- Renders TabView bound to coordinator's selectedTab
- Manages tab switching
- Integrates with child coordinators per tab
- Test cross-tab navigation

### After TabCoordinatorView: Example App

Create minimal example demonstrating:
- Push navigation (3 screens)
- Modal presentation
- Tab navigation
- Cross-flow detour navigation

Validate everything works in real SwiftUI environment.

### After Example App: Polish & Future Enhancements

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

---

**Last Task Completed:** Updated DEVELOPMENT.md with all recent architectural decisions
**Next Task:** Build TabCoordinatorView
**Branch:** Add-View-layer
