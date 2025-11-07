//
//  Coordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Foundation

open class Coordinator<R: Route>: AnyCoordinator {
    public weak var parent: AnyCoordinator?

    /// The router managing navigation state.
    ///
    /// **For observation only** - Views should observe this for rendering.
    /// Do NOT call mutation methods directly (push, pop, etc.).
    /// Use `navigate(to:)` instead for all navigation.
    public let router: Router<R>

    /// How this coordinator is presented in the navigation hierarchy.
    /// Determines whether the root view should show a back button.
    public var presentationContext: CoordinatorPresentationContext = .root

    public internal(set) var children: [AnyCoordinator] = []
    public internal(set) var modalCoordinators: [AnyCoordinator] = []
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

    /// Tab item configuration for coordinators used as tabs
    /// Override this in subclasses that are used as tabs in a TabCoordinator
    open var tabItem: (text: String, image: String)? {
        return nil
    }

    open func navigationType(for route: any Route) -> NavigationType {
        return .push
    }

    public func addChild(_ coordinator: AnyCoordinator, context: CoordinatorPresentationContext = .pushed) {
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

    public func addModalCoordinator(_ coordinator: AnyCoordinator) {
        modalCoordinators.append(coordinator)
    }

    public func removeModalCoordinator(_ coordinator: AnyCoordinator) {
        modalCoordinators.removeAll { $0 === coordinator }
    }

    open func canHandle(_ route: any Route) -> Bool {
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
        print("🔍 \(Self.self): Navigating to \(route.identifier)")

        if let typedRoute = route as? R, trySmartNavigation(to: typedRoute) {
            return true
        }

        if handleModalNavigation(to: route, from: caller) {
            return true
        }

        if handleDetourNavigation(to: route, from: caller) {
            return true
        }

        if let typedRoute = route as? R, canHandle(typedRoute) {
            print("✅ \(Self.self): Executing navigation for \(route.identifier)")
            executeNavigation(for: typedRoute)
            return true
        }

        if delegateToChildren(route: route, caller: caller) {
            return true
        }

        return bubbleToParent(route: route)
    }

    open func shouldDismissModalFor(route: any Route) -> Bool {
        return !(route is R)
    }

    open func shouldDismissDetourFor(route: any Route) -> Bool {
        return true
    }

    open func shouldCleanStateForBubbling(route: any Route) -> Bool {
        if case .tabSwitch = navigationType(for: route) {
            return false
        }
        return detourCoordinator != nil || currentModalCoordinator != nil || !router.state.stack.isEmpty
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
    }

    public func presentModal(_ coordinator: AnyCoordinator, presenting route: R) {
        currentModalCoordinator = coordinator
        coordinator.parent = self
        coordinator.presentationContext = .modal
        router.present(route)
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
    public func pop() {
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
}
