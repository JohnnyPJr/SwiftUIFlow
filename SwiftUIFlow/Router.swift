//
//  Router.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Foundation
import Combine


public final class Router<R: Route>: ObservableObject {
    @Published public private(set) var state: NavigationState<R>
    
    public init(initial root: R) {
        self.state = NavigationState(root: root)
    }
    
    public func push(_ route: R) {
        state.stack.append(route)
    }
    
    public func pop() {
        _ = state.stack.popLast()
    }
    
    public func setRoot(_ route: R) {
        state.root = route
        state.stack.removeAll()
    }
    
    public func present(_ route: R) {
        state.presented = route
    }
    
    public func dismissModal() {
        state.presented = nil
    }
}
