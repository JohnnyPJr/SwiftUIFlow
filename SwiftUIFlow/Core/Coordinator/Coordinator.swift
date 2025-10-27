//
//  Coordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Foundation

open class Coordinator<R: Route>: AnyCoordinator {
    public weak var parent: AnyCoordinator?
    let router: Router<R>
    public private(set) var children: [AnyCoordinator] = []
    public private(set) var modalCoordinator: AnyCoordinator?

    public init(router: Router<R>) {
        self.router = router
    }

    open func navigationType(for route: any Route) -> NavigationType {
        return .push
    }

    public func addChild(_ coordinator: AnyCoordinator) {
        children.append(coordinator)
        coordinator.parent = self
    }

    public func removeChild(_ coordinator: AnyCoordinator) {
        children.removeAll { $0 === coordinator }
        if coordinator.parent === self {
            coordinator.parent = nil
        }
    }

    // LOCAL ONLY - does THIS coordinator handle this route directly
    open func canHandle(_ route: any Route) -> Bool {
        return false
    }

    // RECURSIVE - can this coordinator OR its descendants handle the route
    public func canNavigate(to route: any Route) -> Bool {
        // Can I handle it directly?
        if canHandle(route) {
            return true
        }

        // Can any of my children handle it (recursively)?
        for child in children {
            if child.canNavigate(to: route) {
                return true
            }
        }

        // Can my modal handle it (recursively)?
        if let modal = modalCoordinator {
            if modal.canNavigate(to: route) {
                return true
            }
        }

        return false
    }

    public func navigate(to route: any Route, from caller: AnyCoordinator? = nil) -> Bool {
        print("🔍 \(Self.self): Navigating to \(route.identifier)")

        if let typedRoute = route as? R {
            // Early return: Are we already at this route?
            if isAlreadyAt(route: typedRoute) {
                print("✋ \(Self.self): Already at \(route.identifier), skipping navigation")
                return true
            }

            // Smart backward navigation: Check if route is in our stack
            if router.state.stack.firstIndex(where: { $0 == typedRoute }) != nil {
                print("⏪ \(Self.self): Popping back to \(route.identifier)")
                popTo(typedRoute)
                return true
            }

            // Check if navigating to root
            if typedRoute == router.state.root {
                if !router.state.stack.isEmpty {
                    print("⏪ \(Self.self): Popping to root \(route.identifier)")
                    popToRoot()
                    return true
                } else {
                    print("✋ \(Self.self): Already at root \(route.identifier)")
                    return true
                }
            }
        }

        // Check modal first if currently presented
        if let modal = modalCoordinator {
            var modalHandledRoute = false

            // Only try to navigate if it's not the caller (prevents infinite loop)
            if modal !== caller {
                modalHandledRoute = modal.navigate(to: route, from: self)
            }

            // If modal handled it and is still our modal, keep it
            if modalHandledRoute, modalCoordinator === modal {
                print("📱 \(Self.self): Modal handled \(route.identifier)")
                return true
            }

            // Modal is still present, and either:
            // 1. Didn't handle the route (including when it's the caller), OR
            // 2. Route is incompatible with modal type
            // Then dismiss it
            if modalCoordinator === modal {
                if !modalHandledRoute || shouldDismissModalFor(route: route) {
                    print("🚪 \(Self.self): Dismissing modal for \(route.identifier)")
                    dismissModal()
                }
            }
        }

        // Try to handle directly (after cleaning up incompatible modals)
        if let typedRoute = route as? R {
            if canHandle(typedRoute) {
                print("✅ \(Self.self): Executing navigation for \(route.identifier)")
                executeNavigation(for: typedRoute)
                return true
            }
        }

        // Check if any child can handle it - skip the caller (prevents infinite loop)
        for child in children where child !== caller {
            if child.navigate(to: route, from: self) {
                print("👶 \(Self.self): Child handled \(route.identifier)")
                return true
            }
        }

        // Bubble up to parent
        if let parent {
            print("⬆️ \(Self.self): Bubbling \(route.identifier) to parent")

            // Before bubbling up, should we clean our state?
            if shouldCleanStateForBubbling(route: route) {
                print("🧹 \(Self.self): Cleaning state before bubbling")
                cleanStateForBubbling()
            }

            return parent.navigate(to: route, from: self)
        }

        print("❌ \(Self.self): Could not handle \(route.identifier)")
        return false
    }

    // Check if we're already at the target route (idempotency check)
    private func isAlreadyAt(route: R) -> Bool {
        switch navigationType(for: route) {
        case let .tabSwitch(index):
            return router.state.selectedTab == index
        case .push, .replace:
            return router.state.currentRoute == route
        case .modal:
            return router.state.presented == route
        }
    }

    // Execute the actual navigation based on NavigationType
    private func executeNavigation(for route: R) {
        switch navigationType(for: route) {
        case .push:
            router.push(route)
        case .replace:
            router.replace(route)
        case .modal:
            router.present(route)
        case let .tabSwitch(index):
            router.selectTab(index)
        }
    }

    // Determine if we should dismiss modal for this route
    open func shouldDismissModalFor(route: any Route) -> Bool {
        // Default: dismiss if the route belongs to a different coordinator type
        return !(route is R)
    }

    // Determine if we should clean state when bubbling
    open func shouldCleanStateForBubbling(route: any Route) -> Bool {
        // Clean if we have a modal presented or if we're deep in a stack
        // Don't clean if we're a tab coordinator (they handle their own tab switching)
        if case .tabSwitch = navigationType(for: route) {
            return false
        }
        return modalCoordinator != nil || !router.state.stack.isEmpty
    }

    // Clean state when bubbling up
    open func cleanStateForBubbling() {
        // Dismiss modal coordinator if present (handles both coordinator and router state)
        if modalCoordinator != nil {
            dismissModal()
        }

        // Clean navigation stack (TabCoordinators override this to prevent cleaning)
        if !router.state.stack.isEmpty {
            router.popToRoot()
        }
    }

    public func presentModal(_ coordinator: AnyCoordinator, presenting route: R) {
        modalCoordinator = coordinator
        coordinator.parent = self
        router.present(route)
    }

    public func dismissModal() {
        if modalCoordinator?.parent === self {
            modalCoordinator?.parent = nil
        }
        modalCoordinator = nil
        router.dismissModal()
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
        // Find the route in the stack
        guard let index = router.state.stack.firstIndex(where: { $0 == route }) else {
            return
        }

        // Pop everything after that route
        let popCount = router.state.stack.count - index - 1
        for _ in 0 ..< popCount {
            router.pop()
        }
    }

    public func resetToCleanState() {
        router.resetToRoot()
        dismissModal()
    }
}
