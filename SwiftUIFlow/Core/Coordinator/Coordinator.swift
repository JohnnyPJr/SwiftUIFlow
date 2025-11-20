//
//  Coordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Combine
import Foundation

open class Coordinator<R: Route>: AnyCoordinator {
    public weak var parent: AnyCoordinator?

    /// The router managing navigation state.
    ///
    /// **For observation only** - Views should observe this for rendering.
    /// Do NOT call mutation methods directly (push, pop, etc.).
    /// Use `navigate(to:)` instead for all navigation.
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
    /// Determines whether the root view should show a back button.
    public var presentationContext: CoordinatorPresentationContext = .root

    public internal(set) var children: [AnyCoordinator] = []
    public internal(set) var modalCoordinators: [Coordinator<R>] = []
    public internal(set) var currentModalCoordinator: AnyCoordinator?
    public internal(set) var detourCoordinator: AnyCoordinator?

    public init(router: Router<R>) {
        self.router = router
    }

    /// Build a view for a given route using this coordinator's ViewFactory
    public func buildView(for route: any Route) -> Any? {
        guard let typedRoute = route as? R else { return nil }
        return router.view(for: typedRoute)
    }

    /// Build a CoordinatorView for this coordinator with full navigation support
    public func buildCoordinatorView() -> Any {
        return CoordinatorView(coordinator: self)
    }

    /// Build a view for a specific route with modal/detour presentation support
    /// Returns CoordinatorRouteView as type-erased Any (caller should cast to AnyView)
    public func buildCoordinatorRouteView(for route: any Route) -> Any {
        return CoordinatorRouteView(coordinator: self, route: route)
    }

    /// Tab item configuration for coordinators used as tabs
    /// Override this in subclasses that are used as tabs in a TabCoordinator
    open var tabItem: (text: String, image: String)? {
        return nil
    }

    open func navigationType(for route: any Route) -> NavigationType {
        return .push
    }

    /// Configure modal presentation detents for a route.
    /// Override this to customize how modals are presented.
    /// Only called when navigationType returns .modal
    open func modalDetentConfiguration(for route: any Route) -> ModalDetentConfiguration {
        return ModalDetentConfiguration(detents: [.large])
    }

    public func addChild(_ coordinator: AnyCoordinator, context: CoordinatorPresentationContext = .pushed) {
        // Check for circular reference
        if coordinator === self {
            let error = SwiftUIFlowError.circularReference(coordinator: String(describing: type(of: self)))
            reportError(error)
            return
        }

        // Check for duplicate child
        if children.contains(where: { $0 === coordinator }) {
            let error = SwiftUIFlowError.duplicateChild(coordinator: String(describing: type(of: coordinator)))
            reportError(error)
            return
        }

        children.append(coordinator)
        coordinator.parent = self
        coordinator.presentationContext = context
    }

    public func removeChild(_ coordinator: AnyCoordinator) {
        children.removeAll { $0 === coordinator }
        if coordinator.parent === self {
            coordinator.parent = nil
        }
    }

    /// Add a modal coordinator that can be presented via navigate() when navigationType returns .modal
    /// - Parameter coordinator: Must be Coordinator<R> (same route type as parent)
    public func addModalCoordinator(_ coordinator: Coordinator<R>) {
        modalCoordinators.append(coordinator)
    }

    public func removeModalCoordinator(_ coordinator: Coordinator<R>) {
        modalCoordinators.removeAll { $0 === coordinator }
    }

    open func canHandle(_ route: any Route) -> Bool {
        return false
    }

    /// Validates navigation path without side effects - mirrors navigate() logic exactly.
    /// Override in subclasses if needed. Default implementation delegates to extension helper.
    open func validateNavigationPath(to route: any Route, from caller: AnyCoordinator?) -> ValidationResult {
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

    public func canNavigate(to route: any Route) -> Bool {
        if canHandle(route) {
            return true
        }

        for child in children {
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

    public func navigate(to route: any Route, from caller: AnyCoordinator? = nil) -> Bool {
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
        return detourCoordinator != nil || currentModalCoordinator != nil || !router.state.stack.isEmpty || !router.state.pushedChildren.isEmpty
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

    /// **Internal:** Present a modal coordinator with a route.
    /// **Clients should use `navigate(to:)` instead.**
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

    public func dismissModal() {
        if currentModalCoordinator?.parent === self {
            currentModalCoordinator?.parent = nil
        }
        currentModalCoordinator = nil
        router.dismissModal()
    }

    public func presentDetour(_ coordinator: AnyCoordinator, presenting route: any Route) {
        detourCoordinator = coordinator
        coordinator.parent = self
        coordinator.presentationContext = .detour
        router.presentDetour(route)

        // Navigate detour coordinator to the presenting route
        _ = coordinator.navigate(to: route, from: self)
    }

    public func dismissDetour() {
        if detourCoordinator?.parent === self {
            detourCoordinator?.parent = nil
        }
        detourCoordinator = nil
        router.dismissDetour()
    }

    // MARK: - Navigation Stack Control

    /// Pop one screen from the navigation stack
    /// If at root and presented as modal/detour, dismisses instead
    public func pop() {
        // Check if we have pushed child coordinators
        if let lastChild = router.state.pushedChildren.last {
            // Check if child has routes in its stack (beyond root)
            if lastChild.allRoutes.count > 1 {
                // Child has internal stack - pop from child
                lastChild.pop()
            } else {
                // Child is at its root - pop entire child coordinator
                router.popChild()
            }
            return
        }

        // If we're at the root (no pushed screens) and presented as modal/detour,
        // dismiss instead of attempting to pop
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

    /// Pop all screens and return to the root of this coordinator's flow
    public func popToRoot() {
        router.popToRoot()
    }

    /// Pop to a specific route in the stack (if it exists)
    public func popTo(_ route: R) {
        guard let index = router.state.stack.firstIndex(where: { $0 == route }) else {
            return
        }

        let popCount = router.state.stack.count - index - 1
        for _ in 0 ..< popCount {
            router.pop()
        }
    }

    public func resetToCleanState() {
        router.resetToRoot()
        dismissModal()
        dismissDetour()
    }

    // MARK: - Admin Operations (Major Flow Transitions)

    /// **ADMIN OPERATION** - Transition to a completely new flow with a new root.
    /// Sets new root route, clears stack, and dismisses modals/detours.
    /// Use for major transitions like Login → Home, not for regular navigation.
    public func transitionToNewFlow(root: R) {
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
