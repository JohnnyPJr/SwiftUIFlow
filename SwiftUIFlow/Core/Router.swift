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

    // MARK: - Navigation Methods (Internal - Use Coordinator methods instead)

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

    /// Push a child coordinator onto the navigation stack.
    /// **Internal:** Used when delegating navigation to a child coordinator.
    func pushChild(_ coordinator: AnyCoordinator) {
        state.pushedChildren.append(coordinator)
    }

    /// Pop the top child coordinator from the navigation stack.
    /// **Internal:** Called when NavigationStack pops a child coordinator (user taps back).
    func popChild() {
        _ = state.pushedChildren.popLast()
    }

    /// Pop the top route from the navigation stack.
    /// **Internal:** Use `Coordinator.pop()` instead.
    func pop() {
        _ = state.stack.popLast()
    }

    /// **ADMIN OPERATION** - Set a new root route and clear the stack.
    ///
    /// This is for major app-level flow transitions (e.g., onboarding → login → home).
    /// Use `Coordinator.transitionToNewFlow(root:)` instead of calling this directly.
    ///
    /// **Not part of normal navigation** - use `Coordinator.navigate(to:)` for regular navigation.
    func setRoot(_ route: R) {
        state.root = route
        state.stack.removeAll()
    }

    /// Present a route modally.
    /// **Internal:** Use `Coordinator.navigate()` with .modal NavigationType instead.
    func present(_ route: R,
                 detentConfiguration: ModalDetentConfiguration = ModalDetentConfiguration(detents: [.large]))
    {
        state.presented = route
        state.modalDetentConfiguration = detentConfiguration
    }

    /// Dismiss the currently presented modal.
    /// **Internal:** Use `Coordinator.dismissModal()` instead.
    func dismissModal() {
        state.presented = nil
        state.modalDetentConfiguration = nil
    }

    /// Present a detour route (cross-coordinator navigation with context preservation).
    /// **Internal:** Use `Coordinator.presentDetour()` instead.
    func presentDetour(_ route: any Route) {
        state.detour = route
    }

    /// Dismiss the currently presented detour.
    /// **Internal:** Use `Coordinator.dismissDetour()` instead.
    func dismissDetour() {
        state.detour = nil
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
        state.detour = nil
    }

    /// Reset to root and dismiss all modals.
    /// **Internal:** Use `Coordinator.resetToCleanState()` instead.
    func resetToRoot() {
        state.stack.removeAll()
        state.presented = nil
        state.detour = nil
    }

    // MARK: - Modal Detent Configuration

    /// Update the ideal height in the modal detent configuration
    /// **Internal:** Called by CoordinatorView when PreferenceKey changes
    func updateModalIdealHeight(_ height: CGFloat?) {
        guard state.modalDetentConfiguration != nil else { return }
        state.modalDetentConfiguration?.idealHeight = height
    }

    /// Update the minimum height in the modal detent configuration
    /// **Internal:** Called by CoordinatorView when PreferenceKey changes
    func updateModalMinHeight(_ height: CGFloat?) {
        guard state.modalDetentConfiguration != nil else { return }
        state.modalDetentConfiguration?.minHeight = height
    }

    /// Update the selected detent in the modal detent configuration
    /// **Internal:** Called by CoordinatorView when user changes detent
    func updateModalSelectedDetent(_ detent: ModalPresentationDetent?) {
        guard state.modalDetentConfiguration != nil else { return }
        state.modalDetentConfiguration?.selectedDetent = detent
    }

    // MARK: - View Building
    public func view(for route: R) -> AnyView? {
        factory.buildView(for: route)
    }
}
