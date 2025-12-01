//
//  Coordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Combine
import Foundation

/// The base coordinator class for managing navigation and view presentation in SwiftUI applications.
///
/// `Coordinator` is the foundation of SwiftUIFlow's navigation architecture. Each coordinator manages
/// a specific navigation scope, owns a `Router` for navigation state, and delegates view creation to
/// a `ViewFactory`.
///
/// ## Basic Usage
///
/// Subclass `Coordinator` and override key methods to define your navigation behavior:
///
/// ```swift
/// class ProductCoordinator: Coordinator<ProductRoute> {
///     init() {
///         let router = Router(initial: .list, factory: ProductViewFactory())
///         super.init(router: router)
///     }
///
///     override func canHandle(_ route: any Route) -> Bool {
///         return route is ProductRoute
///     }
///
///     override func navigationType(for route: any Route) -> NavigationType {
///         guard let productRoute = route as? ProductRoute else { return .push }
///         switch productRoute {
///         case .list, .detail: return .push
///         case .checkout: return .modal
///         }
///     }
/// }
/// ```
///
/// ## Key Responsibilities
///
/// - **Route handling**: Determine which routes this coordinator can handle via `canHandle(_:)`
/// - **Navigation types**: Specify how routes are presented via `navigationType(for:)`
/// - **Modal configuration**: Customize modal presentation via `modalDetentConfiguration(for:)`
/// - **Child coordinators**: Manage child coordinators for nested navigation flows
///
/// ## Coordinator Hierarchy
///
/// Coordinators form a parent-child hierarchy. When a route cannot be handled locally,
/// it automatically bubbles up to the parent coordinator. This enables deep linking
/// and cross-flow navigation without tight coupling.
///
/// ## See Also
///
/// - `TabCoordinator` - Specialized coordinator for tab-based navigation
/// - `FlowOrchestrator` - Specialized coordinator for managing major app flow transitions
/// - `Router` - Manages navigation state and view presentation
/// - `ViewFactory` - Maps routes to SwiftUI views
open class Coordinator<R: Route>: AnyCoordinator {
    weak var parent: AnyCoordinator?

    /// The router managing navigation state.
    public let router: Router<R>

    /// All routes for this coordinator (root + stack)
    /// Computed property for immediate access
    var allRoutes: [any Route] {
        [router.state.root] + router.state.stack
    }

    /// The root/initial route for this coordinator (type-erased)
    var rootRoute: any Route {
        router.state.root
    }

    /// Publisher that emits when this coordinator's routes change
    /// Type-erased so parent coordinators can subscribe without knowing route type
    var routesDidChange: AnyPublisher<[any Route], Never> {
        router.routesDidChange.eraseToAnyPublisher()
    }

    /// How this coordinator is presented in the navigation hierarchy.
    var presentationContext: CoordinatorPresentationContext = .root

    /// Internal storage for child coordinators
    /// **Framework internal only** - Subclasses can access via internalChildren
    var internalChildren: [AnyCoordinator] = []

    /// Read-only access to child coordinators for custom UI implementations.
    ///
    /// Use this when implementing custom tab bars or other UI that needs to directly access
    /// and render child coordinators. Each child conforms to `CoordinatorUISupport`, providing
    /// methods like `buildCoordinatorView()` and `tabItem`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// struct CustomTabBar: View {
    ///     let tabCoordinator: TabCoordinator<AppRoute>
    ///
    ///     var body: some View {
    ///         HStack {
    ///             ForEach(Array(tabCoordinator.children.enumerated()), id: \.offset) { index, child in
    ///                 TabButton(
    ///                     title: child.tabItem?.text ?? "",
    ///                     icon: child.tabItem?.image ?? "",
    ///                     isSelected: index == currentTab
    ///                 )
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: Array of child coordinators conforming to `CoordinatorUISupport`
    public var children: [CoordinatorUISupport] {
        return internalChildren
    }

    var modalCoordinators: [Coordinator<R>] = []
    var currentModalCoordinator: AnyCoordinator?
    var detourCoordinator: AnyCoordinator?

    public init(router: Router<R>) {
        self.router = router
    }

    /// Build a view for a given route using this coordinator's ViewFactory
    /// **Framework internal only**
    func buildView(for route: any Route) -> Any? {
        guard let typedRoute = route as? R else { return nil }
        return router.view(for: typedRoute)
    }

    /// Build a SwiftUI view for this coordinator with full navigation support.
    ///
    /// Creates a `CoordinatorView` that renders this coordinator's navigation hierarchy.
    /// This is primarily used when implementing custom tab bars or custom UI that needs
    /// to embed a coordinator's view hierarchy.
    ///
    /// ## Usage
    ///
    /// Use this when building custom tab bars to render each tab's coordinator:
    ///
    /// ```swift
    /// struct CustomTabBar: View {
    ///     let coordinator: MainTabCoordinator
    ///     @ObservedObject private var router: Router<AppRoute>
    ///
    ///     init(coordinator: MainTabCoordinator) {
    ///         self.coordinator = coordinator
    ///         router = coordinator.router
    ///     }
    ///
    ///     var body: some View {
    ///         ZStack(alignment: .bottom) {
    ///             // Render the selected tab's coordinator
    ///             if router.state.selectedTab < coordinator.children.count {
    ///                 let selectedChild = coordinator.children[router.state.selectedTab]
    ///                 let coordinatorView = selectedChild.buildCoordinatorView()
    ///                 eraseToAnyView(coordinatorView)
    ///             }
    ///
    ///             // Your custom tab bar UI
    ///             customTabBar
    ///         }
    ///     }
    /// }
    ///
    /// // Helper to erase type
    /// func eraseToAnyView(_ value: Any) -> AnyView {
    ///     if let view = value as? any View {
    ///         return AnyView(view)
    ///     }
    ///     return AnyView(EmptyView())
    /// }
    /// ```
    ///
    /// - Returns: A type-erased `CoordinatorView` (use `eraseToAnyView` helper to cast)
    public func buildCoordinatorView() -> Any {
        return CoordinatorView(coordinator: self)
    }

    /// Build a view for a specific route with modal/detour presentation support.
    ///
    /// Creates a `CoordinatorRouteView` that renders a specific route while preserving
    /// modal and detour presentation capabilities. This is an advanced API used internally
    /// by the framework for flattened navigation hierarchies.
    ///
    /// - Parameter route: The route to build a view for
    /// - Returns: A type-erased `CoordinatorRouteView`
    public func buildCoordinatorRouteView(for route: any Route) -> Any {
        return CoordinatorRouteView(coordinator: self, route: route)
    }

    /// Tab item configuration for coordinators used as tabs.
    ///
    /// Override this property in subclasses that will be used as tabs within a `TabCoordinator`.
    /// The framework uses this to display tab bar items with appropriate text and SF Symbol icons.
    ///
    /// ## Example
    ///
    /// ```swift
    /// class HomeCoordinator: Coordinator<HomeRoute> {
    ///     override var tabItem: (text: String, image: String)? {
    ///         return ("Home", "house.fill")
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: A tuple containing the tab text label and SF Symbol image name, or `nil` if not used as a tab
    open var tabItem: (text: String, image: String)? {
        return nil
    }

    /// Determines how a route should be presented in the navigation hierarchy.
    ///
    /// Override this method to specify different navigation types for different routes.
    /// The framework uses this to decide whether to push, present as modal, or replace.
    ///
    /// ## Navigation Types
    ///
    /// - `.push` - Standard stack navigation (default)
    /// - `.modal` - Present as a modal sheet
    /// - `.replace` - Replace current screen in stack
    ///
    /// ## Example
    ///
    /// ```swift
    /// override func navigationType(for route: any Route) -> NavigationType {
    ///     guard let myRoute = route as? MyRoute else { return .push }
    ///
    ///     switch myRoute {
    ///     case .details, .settings:
    ///         return .push
    ///     case .editProfile, .confirmation:
    ///         return .modal
    ///     case .result:
    ///         return .replace  // Replace previous screen
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter route: The route being navigated to
    /// - Returns: The navigation type to use for this route
    open func navigationType(for route: any Route) -> NavigationType {
        return .push
    }

    /// Defines the intermediate navigation steps required to reach a route.
    ///
    /// Override this method to specify that certain routes require building a navigation stack
    /// through intermediate steps rather than navigating directly. This is useful for flows that
    /// represent a journey or sequential process.
    ///
    /// ## Behavior
    ///
    /// - Return `nil` (default) - Navigate directly to the route
    /// - Return an array - Navigate through each route in sequence
    ///
    /// ## Example
    ///
    /// ```swift
    /// override func navigationPath(for route: any Route) -> [any Route]? {
    ///     guard let oceanRoute = route as? OceanRoute else { return nil }
    ///
    ///     switch oceanRoute {
    ///     case .shallow: return [.shallow]
    ///     case .deep: return [.shallow, .deep]
    ///     case .abyss: return [.shallow, .deep, .abyss]
    ///     default: return nil
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter route: The destination route
    /// - Returns: An array of routes to navigate through sequentially, or `nil` for direct navigation
    open func navigationPath(for route: any Route) -> [any Route]? {
        return nil
    }

    /// Configure modal presentation detents (size options) for a route.
    ///
    /// Override this method to customize how modals are presented. The framework calls this when
    /// `navigationType(for:)` returns `.modal` to determine the available sheet sizes.
    ///
    /// ## Detent Options
    ///
    /// - `.large` - Full screen height
    /// - `.medium` - Half screen height
    /// - `.custom` - Specific height or percentage
    /// - `.height(adaptive:)` - Adaptive height based on content
    ///
    /// ## Example
    ///
    /// ```swift
    /// override func modalDetentConfiguration(for route: any Route) -> ModalDetentConfiguration {
    ///     guard let myRoute = route as? MyRoute else {
    ///         return ModalDetentConfiguration(detents: [.large])
    ///     }
    ///
    ///     switch myRoute {
    ///     case .quickSettings:
    ///         // Allow dragging between medium and large
    ///         return ModalDetentConfiguration(detents: [.medium, .large])
    ///     case .profile:
    ///         // Sized by the view's content
    ///         return ModalDetentConfiguration(detents: [.custom])
    ///     case .confirmation:
    ///         // Custom height modal
    ///         return ModalDetentConfiguration(detents: [.height(adaptive: true)])
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter route: The route being presented as a modal
    /// - Returns: Configuration specifying available detent sizes. Default is `.large` only
    open func modalDetentConfiguration(for route: any Route) -> ModalDetentConfiguration {
        return ModalDetentConfiguration(detents: [.large])
    }

    /// Add a child coordinator to this coordinator's hierarchy.
    ///
    /// Child coordinators handle navigation for specific sub-flows of your app. When a route
    /// cannot be handled by this coordinator, it automatically delegates to child coordinators.
    ///
    /// ## Usage
    ///
    /// Add child coordinators in your coordinator's initializer:
    ///
    /// ```swift
    /// class MainTabCoordinator: TabCoordinator<AppRoute> {
    ///     init() {
    ///         let router = Router(initial: .home, factory: AppViewFactory())
    ///         super.init(router: router)
    ///
    ///         addChild(HomeCoordinator())       // First tab
    ///         addChild(SearchCoordinator())     // Second tab
    ///         addChild(ProfileCoordinator())    // Third tab
    ///     }
    /// }
    /// ```
    ///
    /// ## Automatic Configuration
    ///
    /// The framework automatically configures:
    /// - Back button visibility based on context
    /// - Parent-child relationships
    /// - Presentation context (`.pushed` for regular coordinators, `.tab` for TabCoordinator)
    ///
    /// ## Important Notes
    ///
    /// - Circular references are prevented - you cannot add a coordinator as its own child
    /// - Duplicate children are prevented - each coordinator can only be added once
    /// - The framework automatically sets up the parent-child relationship
    ///
    /// - Parameter coordinator: The child coordinator to add
    public func addChild(_ coordinator: Coordinator<some Route>) {
        addChild(coordinator, context: .pushed)
    }

    /// Internal version of addChild with explicit context control
    /// **Framework internal only**
    func addChild(_ coordinator: Coordinator<some Route>, context: CoordinatorPresentationContext) {
        // Check for circular reference
        if coordinator === self {
            let error = SwiftUIFlowError.circularReference(coordinator: String(describing: type(of: self)))
            reportError(error)
            return
        }

        // Check for duplicate child
        if internalChildren.contains(where: { $0 === coordinator }) {
            let error = SwiftUIFlowError.duplicateChild(coordinator: String(describing: type(of: coordinator)))
            reportError(error)
            return
        }

        internalChildren.append(coordinator)
        coordinator.parent = self
        coordinator.presentationContext = context
    }

    /// Remove a child coordinator from this coordinator's hierarchy.
    ///
    /// Removes the parent-child relationship and stops delegating navigation to this child.
    /// Use this when you need to dynamically change the coordinator hierarchy.
    ///
    /// ## Example
    ///
    /// ```swift
    /// class SettingsCoordinator: Coordinator<SettingsRoute> {
    ///     var accountCoordinator: AccountCoordinator?
    ///
    ///     func handleLogout() {
    ///         if let account = accountCoordinator {
    ///             removeChild(account)
    ///             accountCoordinator = nil
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter coordinator: The child coordinator to remove
    public func removeChild(_ coordinator: Coordinator<some Route>) {
        internalChildren.removeAll { $0 === coordinator }
        if coordinator.parent === self {
            coordinator.parent = nil
        }
    }

    /// Remove a child coordinator (internal version for framework use)
    /// **Framework internal only**
    func removeChild(_ coordinator: AnyCoordinator) {
        internalChildren.removeAll { $0 === coordinator }
        if coordinator.parent === self {
            coordinator.parent = nil
        }
    }

    /// Add a modal coordinator that can be presented when navigating to modal routes.
    ///
    /// Modal coordinators are specialized coordinators that manage modal presentation flows.
    /// When `navigationType(for:)` returns `.modal` for a route, the framework automatically
    /// presents the registered modal coordinator.
    ///
    /// ## Usage
    ///
    /// Register modal coordinators in your coordinator's initializer:
    ///
    /// ```swift
    /// class ProductCoordinator: Coordinator<ProductRoute> {
    ///     init() {
    ///         let router = Router(initial: .list, factory: ProductViewFactory())
    ///         super.init(router: router)
    ///
    ///         // Register modal coordinator for checkout flow
    ///         let checkoutRouter = Router(initial: .reviewOrder, factory: ProductViewFactory())
    ///         addModalCoordinator(Coordinator(router: checkoutRouter))
    ///     }
    ///
    ///     override func navigationType(for route: any Route) -> NavigationType {
    ///         guard let productRoute = route as? ProductRoute else { return .push }
    ///         return productRoute == .checkout ? .modal : .push
    ///     }
    /// }
    /// ```
    ///
    /// ## Important Notes
    ///
    /// - Modal coordinator must use the same route type `R` as the parent coordinator
    /// - The modal coordinator is presented automatically when navigating to a modal route
    /// - Only one modal can be presented at a time
    ///
    /// - Parameter coordinator: The modal coordinator to register (must have same route type)
    public func addModalCoordinator(_ coordinator: Coordinator<R>) {
        modalCoordinators.append(coordinator)
    }

    /// Remove a registered modal coordinator.
    ///
    /// Unregisters a modal coordinator that was previously added with `addModalCoordinator(_:)`.
    ///
    /// - Parameter coordinator: The modal coordinator to remove
    public func removeModalCoordinator(_ coordinator: Coordinator<R>) {
        modalCoordinators.removeAll { $0 === coordinator }
    }

    /// Determines whether this coordinator can handle navigation to a specific route.
    ///
    /// Override this method to define which routes your coordinator is responsible for.
    /// The framework calls this during navigation to find the appropriate coordinator
    /// in the hierarchy that should handle the route.
    ///
    /// ## Important Notes
    ///
    /// - Return `true` only for routes this coordinator directly owns, can navigate and you want to handle
    /// - Don't check child coordinators here - the framework handles delegation automatically
    /// - This method should be fast as it's called during navigation path validation
    ///
    /// ## Example
    ///
    /// ```swift
    /// class ProductCoordinator: Coordinator<ProductRoute> {
    ///     override func canHandle(_ route: any Route) -> Bool {
    ///         return route is ProductRoute
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter route: The route to check
    /// - Returns: `true` if this coordinator can navigate to the route, `false` otherwise
    open func canHandle(_ route: any Route) -> Bool {
        return false
    }

    /// Validates navigation path without side effects - mirrors navigate() logic exactly.
    /// Override in subclasses if needed. Default implementation delegates to extension helper.
    func validateNavigationPath(to route: any Route, from caller: AnyCoordinator?) -> ValidationResult {
        return validateNavigationPathBase(to: route, from: caller)
    }

    /// Check a FlowOrchestrator Coordinator can handle a flow change for the given route.
    ///
    /// Override this to return true for routes that `handleFlowChange` would handle,
    /// WITHOUT executing the flow change. This is necessary during validation.
    ///
    /// ```swift
    /// override func canHandleFlowChange(to route: any Route) -> Bool {
    ///     guard let appRoute = route as? AppRoute else { return false }
    ///     return appRoute == .login || appRoute == .mainApp
    /// }
    /// ```
    open func canHandleFlowChange(to route: any Route) -> Bool {
        return false
    }

    /// Handle major flow transitions (e.g., Login ↔ Main App).
    ///
    /// Called when a route bubbles to root and cannot be handled. Override to orchestrate
    /// flow changes: deallocate old coordinators, create fresh ones, call `transitionToNewFlow(root:)`.
    ///
    /// ```swift
    /// override func handleFlowChange(to route: any Route) -> Bool {
    ///     guard let appRoute = route as? AppRoute else { return false }
    ///     switch appRoute {
    ///     case .login: showLogin(); return true
    ///     case .mainApp: showMainApp(); return true
    ///     default: return false
    ///     }
    /// }
    /// ```
    open func handleFlowChange(to route: any Route) -> Bool {
        return false
    }

    /// Check if this coordinator or any of its children can navigate to a route
    func canNavigate(to route: any Route) -> Bool {
        if canHandle(route) {
            return true
        }

        for child in internalChildren {
            if child.canNavigate(to: route) {
                return true
            }
        }

        for modal in modalCoordinators {
            if modal.canNavigate(to: route) {
                return true
            }
        }

        return false
    }

    /// Navigate to a route anywhere in your app's coordinator hierarchy.
    ///
    /// This is the primary navigation method in SwiftUIFlow. Call it from anywhere to navigate
    /// to any route, and the framework automatically finds the right coordinator to handle it.
    ///
    /// ## How It Works
    ///
    /// 1. **Local handling**: If this coordinator can handle the route, it navigates directly
    /// 2. **Child delegation**: If not, tries child coordinators recursively
    /// 3. **Parent bubbling**: If no child can handle it, bubbles up to parent coordinators
    /// 4. **Smart navigation**: Automatically pops/dismisses when navigating to existing routes
    ///
    /// ## Usage Examples
    ///
    /// ```swift
    /// // Navigate from a view
    /// Button("View Profile") {
    ///     coordinator.navigate(to: ProfileRoute.detail(userId: "123"))
    /// }
    ///
    /// // Navigate after business logic
    /// func handlePurchase() async {
    ///     await processPurchase()
    ///     coordinator.navigate(to: CheckoutRoute.confirmation)
    /// }
    ///
    /// // Deep linking
    /// func handle(url: URL) {
    ///     if let route = parseDeepLink(url) {
    ///         rootCoordinator.navigate(to: route)
    ///     }
    /// }
    /// ```
    ///
    /// ## Presentation Types
    ///
    /// The navigation type is determined by `navigationType(for:)`:
    /// - `.push` - Pushes onto the navigation stack
    /// - `.modal` - Presents as a modal sheet
    /// - `.replace` - Replaces the current route in the stack
    ///
    /// ## Return Value
    ///
    /// Returns `true` if navigation succeeded, `false` if no coordinator in the hierarchy
    /// could handle the route. Validation errors are reported through the global error handler.
    ///
    /// - Parameter route: The route to navigate to
    /// - Returns: `true` if navigation was handled, `false` otherwise
    @discardableResult
    public func navigate(to route: any Route) -> Bool {
        return navigate(to: route, from: nil)
    }

    /// Internal navigation with caller tracking
    func navigate(to route: any Route, from caller: AnyCoordinator?) -> Bool {
        // Phase 1: Validation - ONLY at entry point (caller == nil)
        if caller == nil {
            let validationResult = validateNavigationPath(to: route, from: caller)
            if case let .failure(error) = validationResult {
                NavigationLogger.error("❌ \(Self.self): Navigation validation failed for \(route.identifier)")
                reportError(error)
                return false
            }
        }

        // Phase 2: Execution (side effects happen here)
        NavigationLogger.debug("🔍 \(Self.self): Navigating to \(route.identifier)")

        if let typedRoute = route as? R, trySmartNavigation(to: typedRoute) {
            // If caller is a pushed child, pop it (navigating back to parent)
            if let caller, router.state.pushedChildren.contains(where: { $0 === caller }) {
                router.popChild()
                NavigationLogger
                    .debug("👈 \(Self.self): Popped child coordinator after bubbling back")
            }
            // If caller is current modal, dismiss it (modal bubbled a route we're already at)
            else if let caller, currentModalCoordinator === caller {
                NavigationLogger
                    .debug("🚪 \(Self.self): Dismissing modal after smart navigation to \(route.identifier)")
                dismissModal()
            }
            // If caller is detour, dismiss it (detour bubbled a route we're already at)
            else if let caller, detourCoordinator === caller {
                NavigationLogger
                    .debug("🔙 \(Self.self): Dismissing detour after smart navigation to \(route.identifier)")
                dismissDetour()
            }
            // If we are a pushed child and navigating to parent's route, tell parent to pop us
            else if caller == nil, let parent, parent is Coordinator<R> {
                if let parentCoordinator = parent as? Coordinator<R>,
                   parentCoordinator.router.state.pushedChildren.contains(where: { $0 === self })
                {
                    parentCoordinator.router.popChild()
                    NavigationLogger.debug("👈 \(Self.self): Popped self from parent after navigating to parent route")
                }
            }
            return true
        }

        if handleModalNavigation(to: route, from: caller) {
            return true
        }

        if handleDetourNavigation(to: route, from: caller) {
            return true
        }

        if let typedRoute = route as? R, canHandle(typedRoute) {
            NavigationLogger.debug("✅ \(Self.self): Executing navigation for \(route.identifier)")
            return executeNavigation(for: typedRoute)
        }

        if delegateToChildren(route: route, caller: caller) {
            return true
        }

        return bubbleToParent(route: route)
    }

    func shouldDismissModalFor(route: any Route) -> Bool {
        return !(route is R)
    }

    func shouldCleanStateForBubbling(route: any Route) -> Bool {
        return detourCoordinator != nil ||
            currentModalCoordinator != nil ||
            !router.state.stack.isEmpty ||
            !router.state.pushedChildren.isEmpty
    }

    func cleanStateForBubbling() {
        if detourCoordinator != nil {
            dismissDetour()
        }

        if currentModalCoordinator != nil {
            dismissModal()
        }

        if !router.state.stack.isEmpty {
            router.popToRoot()
        }

        // Pop all pushed children
        while !router.state.pushedChildren.isEmpty {
            router.popChild()
        }
    }

    /// Called by the framework when navigationType returns .modal
    func presentModal(_ coordinator: AnyCoordinator,
                      presenting route: R,
                      detentConfiguration: ModalDetentConfiguration)
    {
        currentModalCoordinator = coordinator
        coordinator.parent = self
        coordinator.presentationContext = .modal
        router.present(route, detentConfiguration: detentConfiguration)
    }

    /// Dismiss the currently presented modal
    /// **Framework internal only** - modals are dismissed automatically
    func dismissModal() {
        if currentModalCoordinator?.parent === self {
            currentModalCoordinator?.parent = nil
        }
        currentModalCoordinator = nil
        router.dismissModal()
    }

    /// Present a detour coordinator for a full-screen temporary flow.
    ///
    /// Detours are full-screen flows that temporarily overlay your app while preserving
    /// the underlying navigation context. Unlike modals which are part of the navigation flow,
    /// detours are independent, temporary interruptions that don't affect the main navigation stack.
    ///
    /// ## Use Cases
    ///
    /// - Onboarding flows that appear over the main app
    /// - Feature discovery tours
    /// - Temporary full-screen interruptions
    /// - Guest-mode flows before authentication
    ///
    /// ## Usage
    ///
    /// ```swift
    /// class MainCoordinator: Coordinator<AppRoute> {
    ///     func showOnboarding() {
    ///         let onboardingRouter = Router(
    ///             initial: OnboardingRoute.welcome,
    ///             factory: OnboardingViewFactory()
    ///         )
    ///         let onboardingCoordinator = Coordinator(router: onboardingRouter)
    ///         presentDetour(onboardingCoordinator, presenting: OnboardingRoute.welcome)
    ///     }
    /// }
    /// ```
    ///
    /// ## Dismissal
    ///
    /// Detours are dismissed with a back/close button or programmatically via `dismissDetour()`
    /// Or if a navigation action bubbles back.
    /// Unlike modals, detours don't participate in navigation bubbling.
    ///
    /// - Parameters:
    ///   - coordinator: The detour coordinator to present
    ///   - route: The initial route for the detour flow
    public func presentDetour(_ coordinator: Coordinator<some Route>, presenting route: any Route) {
        detourCoordinator = coordinator
        coordinator.parent = self
        coordinator.presentationContext = .detour
        router.presentDetour(route)
    }

    /// Dismiss the currently presented detour
    /// **Framework internal only** - detours are dismissed via back/close button or navigation bubbling
    func dismissDetour() {
        if detourCoordinator?.parent === self {
            detourCoordinator?.parent = nil
        }
        detourCoordinator = nil
        router.dismissDetour()
    }

    /// Reset coordinator to clean state (root, no modals/detours)
    func resetToCleanState() {
        router.resetToRoot()
        dismissModal()
        dismissDetour()
    }

    // MARK: - Admin Operations (Framework Internal)

    /// **ADMIN OPERATION** - Transition to a completely new flow with a new root.
    /// **Framework internal only** - Used by FlowOrchestrator
    /// Sets new root route, clears stack, and dismisses modals/detours.
    /// Use for major transitions like Login → Home, not for regular navigation.
    func transitionToNewFlow(root: R) {
        router.setRoot(root)
        dismissModal()
        dismissDetour()
    }

    // MARK: - Internal Error Reporting

    /// Report an error through the global error handler
    func reportError(_ error: SwiftUIFlowError) {
        SwiftUIFlowErrorHandler.shared.report(error)
    }

    /// Helper to create error with automatic coordinator/route info extraction
    func makeError(for route: any Route, errorType: SwiftUIFlowError.ErrorType) -> SwiftUIFlowError {
        let coordinatorName = String(describing: Self.self)
        let routeId = route.identifier
        let routeType = String(describing: type(of: route))

        switch errorType {
        case let .navigationFailed(context):
            return .navigationFailed(coordinator: coordinatorName,
                                     route: routeId,
                                     routeType: routeType,
                                     context: context)
        case .modalCoordinatorNotConfigured:
            return .modalCoordinatorNotConfigured(coordinator: coordinatorName,
                                                  route: routeId,
                                                  routeType: routeType)
        case .invalidDetourNavigation:
            return .invalidDetourNavigation(coordinator: coordinatorName,
                                            route: routeId,
                                            routeType: routeType)
        case let .viewCreationFailed(viewType):
            return .viewCreationFailed(coordinator: coordinatorName,
                                       route: routeId,
                                       routeType: routeType,
                                       viewType: viewType)
        }
    }
}
