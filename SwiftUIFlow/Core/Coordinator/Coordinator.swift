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

    public private(set) var children: [AnyCoordinator] = []
    public private(set) var modalCoordinators: [AnyCoordinator] = []
    public private(set) var currentModalCoordinator: AnyCoordinator?
    public private(set) var detourCoordinator: AnyCoordinator?

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

    // MARK: - Private Navigation Helpers

    private func trySmartNavigation(to route: R) -> Bool {
        if isAlreadyAt(route: route) {
            print("✋ \(Self.self): Already at \(route.identifier), skipping navigation")
            return true
        }

        if router.state.stack.firstIndex(where: { $0 == route }) != nil {
            print("⏪ \(Self.self): Popping back to \(route.identifier)")
            popTo(route)
            return true
        }

        if route == router.state.root {
            if !router.state.stack.isEmpty {
                print("⏪ \(Self.self): Popping to root \(route.identifier)")
                popToRoot()
                return true
            } else {
                print("✋ \(Self.self): Already at root \(route.identifier)")
                return true
            }
        }

        return false
    }

    private func handleModalNavigation(to route: any Route, from caller: AnyCoordinator?) -> Bool {
        guard let modal = currentModalCoordinator else { return false }

        var modalHandledRoute = false

        if modal !== caller {
            modalHandledRoute = modal.navigate(to: route, from: self)
        }

        if modalHandledRoute, currentModalCoordinator === modal {
            print("📱 \(Self.self): Modal handled \(route.identifier)")
            return true
        }

        if currentModalCoordinator === modal {
            if !modalHandledRoute || shouldDismissModalFor(route: route) {
                print("🚪 \(Self.self): Dismissing modal for \(route.identifier)")
                dismissModal()
            }
        }

        return false
    }

    private func handleDetourNavigation(to route: any Route, from caller: AnyCoordinator?) -> Bool {
        guard let detour = detourCoordinator else { return false }

        var detourHandledRoute = false

        if detour !== caller {
            detourHandledRoute = detour.navigate(to: route, from: self)
        }

        if detourHandledRoute, detourCoordinator === detour {
            print("🚀 \(Self.self): Detour handled \(route.identifier)")
            return true
        }

        if detourCoordinator === detour {
            if !detourHandledRoute || shouldDismissDetourFor(route: route) {
                print("🔙 \(Self.self): Dismissing detour for \(route.identifier)")
                dismissDetour()
            }
        }

        return false
    }

    private func delegateToChildren(route: any Route, caller: AnyCoordinator?) -> Bool {
        for child in children where child !== caller {
            if child.navigate(to: route, from: self) {
                print("👶 \(Self.self): Child handled \(route.identifier)")
                return true
            }
        }
        return false
    }

    private func bubbleToParent(route: any Route) -> Bool {
        guard let parent else {
            print("❌ \(Self.self): Could not handle \(route.identifier)")
            return false
        }

        print("⬆️ \(Self.self): Bubbling \(route.identifier) to parent")

        if shouldCleanStateForBubbling(route: route) {
            print("🧹 \(Self.self): Cleaning state before bubbling")
            cleanStateForBubbling()
        }

        return parent.navigate(to: route, from: self)
    }

    private func isAlreadyAt(route: R) -> Bool {
        switch navigationType(for: route) {
        case let .tabSwitch(index):
            return router.state.selectedTab == index
        case .push, .replace:
            return router.state.currentRoute == route
        case .modal:
            return router.state.presented == route
        case .detour:
            return router.state.detour?.identifier == route.identifier
        }
    }

    private func executeNavigation(for route: R) {
        switch navigationType(for: route) {
        case .push:
            router.push(route)
        case .replace:
            router.replace(route)
        case .modal:
            if let currentModal = currentModalCoordinator, currentModal.canHandle(route) {
                router.present(route)
                _ = currentModal.navigate(to: route, from: self)
                return
            }

            guard let modalChild = modalCoordinators.first(where: { $0.canHandle(route) }) else {
                assertionFailure("Modal navigation a navigator that can handle route: \(route.identifier).")
                return
            }

            currentModalCoordinator = modalChild
            modalChild.parent = self
            modalChild.presentationContext = .modal
            router.present(route)
            _ = modalChild.navigate(to: route, from: self)
        case .detour:
            assertionFailure("Detours must be presented explicitly via presentDetour(), not through navigate()")
            return
        case let .tabSwitch(index):
            router.selectTab(index)
        }
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
