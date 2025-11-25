//
//  Coordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Combine
import Foundation

open class Coordinator<R: Route>: AnyCoordinator {
    weak var parent: AnyCoordinator?

    /// The router managing navigation state.
    public let router: Router<R>

    /// All routes for this coordinator (root + stack)
    /// Computed property for immediate access
    public var allRoutes: [any Route] {
        [router.state.root] + router.state.stack
    }

    /// Type-erased publisher for route changes
    public var routesDidChange: AnyPublisher<[any Route], Never> {
        router.routesDidChange.eraseToAnyPublisher()
    }

    /// How this coordinator is presented in the navigation hierarchy.
    /// **Framework internal only**
    var presentationContext: CoordinatorPresentationContext = .root

    /// Internal storage for child coordinators
    /// **Framework internal only** - Subclasses can access via internalChildren
    var internalChildren: [AnyCoordinator] = []

    /// Public read-only access to child coordinators for custom UI implementations
    /// Each element conforms to CoordinatorUISupport for UI operations
    /// Cast to your concrete coordinator type if you need type-specific access
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

    /// Build a CoordinatorView for this coordinator with full navigation support
    /// Used by custom UI implementations (e.g., custom tab bars)
    public func buildCoordinatorView() -> Any {
        return CoordinatorView(coordinator: self)
    }

    /// Build a view for a specific route with modal/detour presentation support
    public func buildCoordinatorRouteView(for route: any Route) -> Any {
        return CoordinatorRouteView(coordinator: self, route: route)
    }

    /// Tab item configuration for coordinators used as tabs.
    /// Override this in subclasses that are used as tabs in a TabCoordinator
    open var tabItem: (text: String, image: String)? {
        return nil
    }

    open func navigationType(for route: any Route) -> NavigationType {
        return .push
    }

    /// Configure modal presentation detents for a route.
    open func modalDetentConfiguration(for route: any Route) -> ModalDetentConfiguration {
        return ModalDetentConfiguration(detents: [.large])
    }

    /// Add a child coordinator - PUBLIC API
    /// Clients pass concrete Coordinator<ChildRoute>, stored internally as AnyCoordinator
    public func addChild(_ coordinator: Coordinator<some Route>, context: CoordinatorPresentationContext = .pushed) {
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

    /// Remove a child coordinator - Public API
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

    /// Add a modal coordinator that can be presented via navigate() when navigationType returns .modal
    /// - Parameter coordinator: Must be Coordinator with same route type as parent
    public func addModalCoordinator(_ coordinator: Coordinator<R>) {
        modalCoordinators.append(coordinator)
    }

    /// Remove a modal coordinator - Public API
    public func removeModalCoordinator(_ coordinator: Coordinator<R>) {
        modalCoordinators.removeAll { $0 === coordinator }
    }

    open func canHandle(_ route: any Route) -> Bool {
        return false
    }

    /// Validates navigation path without side effects - mirrors navigate() logic exactly.
    /// **Framework internal only**
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

        if let modal = currentModalCoordinator {
            if modal.canNavigate(to: route) {
                return true
            }
        }

        return false
    }

    /// Navigate to a route - Public API
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

    open func shouldDismissModalFor(route: any Route) -> Bool {
        return !(route is R)
    }

    open func shouldCleanStateForBubbling(route: any Route) -> Bool {
        if case .tabSwitch = navigationType(for: route) {
            return false
        }
        return detourCoordinator != nil ||
            currentModalCoordinator != nil ||
            !router.state.stack.isEmpty ||
            !router.state.pushedChildren.isEmpty
    }

    open func cleanStateForBubbling() {
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

    /// Present a detour coordinator - Public API
    /// Detours are full-screen temporary flows that preserve underlying context
    /// Clients pass concrete Coordinator<DetourRoute>, stored internally as AnyCoordinator
    public func presentDetour(_ coordinator: Coordinator<some Route>, presenting route: any Route) {
        detourCoordinator = coordinator
        coordinator.parent = self
        coordinator.presentationContext = .detour
        router.presentDetour(route)
    }

    /// Dismiss the currently presented detour
    /// **Framework internal only** - detours are dismissed by user gesture
    func dismissDetour() {
        if detourCoordinator?.parent === self {
            detourCoordinator?.parent = nil
        }
        detourCoordinator = nil
        router.dismissDetour()
    }

    /// Reset coordinator to clean state (root, no modals/detours)
    /// **Framework internal only**
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
