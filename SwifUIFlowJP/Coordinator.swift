//
//  Coordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/8/25.
//

open class Coordinator<R: Route>: AnyObject {
    public let router: Router<R>
    public private(set) var children: [Coordinator] = []
    public private(set) var modalCoordinator: Coordinator?
    public weak var parent: Coordinator?

    public init(router: Router<R>) {
        self.router = router
    }
    
    public func addChild(_ coordinator: Coordinator) {
        children.append(coordinator)
        coordinator.parent = self
    }
    
    public func removeChild(_ coordinator: Coordinator) {
        children.removeAll { $0 === coordinator }
        
        if coordinator.parent === self {
            coordinator.parent = nil
        }
    }
    
    open func handle(route: R) -> Bool {
        return false
    }
    
    open func navigate(to route: R) -> Bool {
        if handle(route: route) {
            return true
        }
        
        for child in children {
            if child.navigate(to: route) {
                return true
            }
        }
        
        return parent?.navigate(to: route) ?? false
    }
    
    public func presentModal(_ coordinator: Coordinator) {
        modalCoordinator = coordinator
    }
    
    public func dismissModal() {
        modalCoordinator = nil
    }
}

extension Coordinator: DeeplinkHandler {
    public func canHandle(_ route: R) -> Bool {
        handle(route: route)
    }

    public func handleDeeplink(_ route: R) {
        if handle(route: route) { return }
        for child in children {
            if child.canHandle(route) {
                child.handleDeeplink(route)
                return
            }
        }
        parent?.handleDeeplink(route)
    }
}
