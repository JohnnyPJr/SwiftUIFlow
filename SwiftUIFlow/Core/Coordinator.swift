//
//  Coordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Foundation

open class Coordinator<R: Route>: AnyCoordinator {
    public weak var parent: AnyCoordinator?

    public let router: Router<R>
    public private(set) var children: [AnyCoordinator] = []
    public private(set) var modalCoordinator: AnyCoordinator?

    public init(router: Router<R>) {
        self.router = router
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

    open func handle(route: R) -> Bool {
        return false
    }

    public func navigate(to route: any Route) -> Bool {
        print("📍 \(Self.self): Received route \(route.identifier)")

        // STEP 1: Route is not of this coordinator's type
        guard let currentRoute = route as? R else {
            // Recursively find the first capable coordinator in the whole subtree
            if let target = findCoordinatorThatCanHandle(route) {
                print("🔁 \(Self.self): Forwarding unmatched route \(route.identifier) to \(type(of: target))")
                return target.navigate(to: route)
            }

            // Bubble up to parent
            if let parent {
                print("⬆️ \(Self.self): Bubbling unmatched route \(route.identifier) to parent: \(type(of: parent))")
                return parent.navigate(to: route)
            }

            print("🚫 \(Self.self): Unmatched route \(route.identifier) could not be handled")
            return false
        }

        // STEP 2: Route is of this type — try to handle locally
        if handle(route: currentRoute) {
            print("✅ \(Self.self): Handled route \(route.identifier)")
            return true
        }

        // STEP 3: If we didn’t handle, exhaustively search children + modals
        if let target = findCoordinatorThatCanHandle(route) {
            print("🔁 \(Self.self): Forwarding route \(route.identifier) to \(type(of: target))")
            return target.navigate(to: route)
        }

        // STEP 4: Bubble up
        if let parent {
            print("⬆️ \(Self.self): Bubbling route \(route.identifier) to parent: \(type(of: parent))")
            return parent.navigate(to: route)
        }

        return false
    }

    private func findCoordinatorThatCanHandle(_ route: any Route) -> AnyCoordinator? {
        for child in children {
            if child.canHandle(route) {
                return child
            }

            // Recursive search
            if let deepChild = (child as? Coordinator)?.findCoordinatorThatCanHandle(route) {
                return deepChild
            }
        }

        // Also check modal recursively
        if let modal = modalCoordinator {
            if modal.canHandle(route) {
                return modal
            }

            if let deepModal = (modal as? Coordinator)?.findCoordinatorThatCanHandle(route) {
                return deepModal
            }
        }

        return nil
    }

    public func presentModal(_ coordinator: AnyCoordinator) {
        modalCoordinator = coordinator
        coordinator.parent = self
    }

    public func dismissModal() {
        if modalCoordinator?.parent === self {
            modalCoordinator?.parent = nil
        }
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
