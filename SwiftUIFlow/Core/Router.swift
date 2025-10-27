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

    // MARK: - Navigation Methods (Internal - Use Coordinator.navigate() instead)

    /// Push a route onto the navigation stack.
    /// **Internal:** Use `Coordinator.navigate(to:)` instead.
    func push(_ route: R) {
        state.stack.append(route)
    }

    /// Replace the current route with a new one (no back navigation).
    /// **Internal:** Use `Coordinator.navigate(to:)` with `.replace` NavigationType instead.
    func replace(_ route: R) {
        // Replace current screen: pop last item (if any) and push new route
        // Useful for multi-step flows where you don't want back navigation
        if !state.stack.isEmpty {
            _ = state.stack.popLast()
        }
        state.stack.append(route)
    }

    /// Pop the top route from the navigation stack.
    /// **Internal:** Use `Coordinator.pop()` instead.
    func pop() {
        _ = state.stack.popLast()
    }

    /// Set a new root route and clear the stack.
    /// **Internal:** Use `Coordinator.navigate(to:)` for major flow transitions instead.
    func setRoot(_ route: R) {
        state.root = route
        state.stack.removeAll()
    }

    /// Present a route modally.
    /// **Internal:** Use `Coordinator.navigate(to:)` with `.modal` NavigationType instead.
    func present(_ route: R) {
        state.presented = route
    }

    /// Dismiss the currently presented modal.
    /// **Internal:** Use `Coordinator.dismissModal()` instead.
    func dismissModal() {
        state.presented = nil
    }

    /// Switch to a specific tab index.
    /// **Internal:** Use `Coordinator.navigate(to:)` with `.tabSwitch` NavigationType instead.
    func selectTab(_ index: Int) {
        state.selectedTab = index
    }

    /// Pop all routes and return to root.
    /// **Internal:** Use `Coordinator.popToRoot()` instead.
    func popToRoot() {
        state.stack.removeAll()
    }

    /// Dismiss all presented modals.
    /// **Internal:** Use `Coordinator.dismissModal()` instead.
    func dismissAllModals() {
        state.presented = nil
    }

    /// Reset to root and dismiss all modals.
    /// **Internal:** Use `Coordinator.resetToCleanState()` instead.
    func resetToRoot() {
        state.stack.removeAll()
        state.presented = nil
    }

    // MARK: - View Building
    public func view(for route: R) -> AnyView? {
        factory.buildView(for: route)
    }
}
