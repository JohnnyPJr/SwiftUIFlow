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
    
    public init(router: Router<R>) {
        self.router = router
    }
    
    public func addChild(_ coordinator: Coordinator) {
        children.append(coordinator)
    }
    
    public func removeChild(_ coordinator: Coordinator) {
        children.removeAll { $0 === coordinator }
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
        
        return false
    }
    
    public func presentModal(_ coordinator: Coordinator) {
        modalCoordinator = coordinator
    }
    
    public func dismissModal() {
        modalCoordinator = nil
    }
}
