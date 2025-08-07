//
//  Coordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/8/25.
//

open class Coordinator<R: Route>: AnyCoordinator {
    public let router: Router<R>
    public private(set) var children: [AnyCoordinator] = []
    public private(set) var modalCoordinator: AnyCoordinator?
    public weak var parent: AnyCoordinator?

    public init(router: Router<R>) {
        self.router = router
    }

    public func addChild(_ coordinator: AnyCoordinator) {
        children.append(coordinator)
        (coordinator as? Coordinator)?.parent = self as AnyCoordinator
    }

    public func removeChild(_ coordinator: AnyCoordinator) {
        children.removeAll { $0 === coordinator }

        if let coordinator = coordinator as? Coordinator, coordinator.parent === self as AnyCoordinator {
            coordinator.parent = nil
        }
    }

    open func handle(route: R) -> Bool {
        return false
    }

    public func navigate(to route: any Route) -> Bool {
        guard let currentRoute = route as? R else {
            return children.contains { $0.navigate(to: route) } || (parent?.navigate(to: route) ?? false)
        }

        if handle(route: currentRoute) {
            return true
        }

        for child in children {
            if child.navigate(to: currentRoute) {
                return true
            }
        }

        return children.contains { $0.navigate(to: route) } || (parent?.navigate(to: route) ?? false)
    }

    public func presentModal(_ coordinator: AnyCoordinator) {
        modalCoordinator = coordinator
    }

    public func dismissModal() {
        modalCoordinator = nil
    }
}

extension Coordinator: DeeplinkHandler {
    public func canHandle(_ route: any Route) -> Bool {
        guard let typed = route as? R else { return false }
        return handle(route: typed)
    }

    public func handleDeeplink(_ route: any Route) {
        guard let typed = route as? R else {
            for child in children {
                if child.canHandle(route) {
                    child.handleDeeplink(route)
                    return
                }
            }

            parent?.handleDeeplink(route)
            return
        }

        if handle(route: typed) { return }

        for child in children {
            if child.canHandle(route) {
                child.handleDeeplink(route)
                return
            }
        }

        parent?.handleDeeplink(route)
    }
}
