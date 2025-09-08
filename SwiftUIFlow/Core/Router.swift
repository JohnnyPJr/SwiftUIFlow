//
//  Router.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Combine
import Foundation
import SwiftUI

public final class Router<R: Route>: ObservableObject {
    @Published public private(set) var state: NavigationState<R>
    private let factory: ViewFactory<R>

    public init(initial: R, factory: ViewFactory<R>) {
        state = NavigationState(root: initial)
        self.factory = factory
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

    public func selectTab(_ index: Int) {
        state.selectedTab = index
    }

    public func popToRoot() {
        state.stack.removeAll()
    }

    public func dismissAllModals() {
        state.presented = nil
    }

    public func resetToRoot() {
        state.stack.removeAll()
        state.presented = nil
    }

    // MARK: - View Building
    public func view(for route: R) -> AnyView? {
        factory.buildView(for: route)
    }
}
