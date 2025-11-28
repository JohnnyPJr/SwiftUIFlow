//
//  Router.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Combine
import Foundation
import SwiftUI

/// Manages navigation state and view creation for a coordinator.
///
/// `Router` is the engine that powers navigation in SwiftUIFlow. Each coordinator
/// owns a router that manages the navigation stack, tracks state, and builds views
/// for routes using a `ViewFactory`.
///
/// ## Usage
///
/// Create a router when initializing your coordinator:
///
/// ```swift
/// class ProductCoordinator: Coordinator<ProductRoute> {
///     init() {
///         let router = Router(
///             initial: .list,
///             factory: ProductViewFactory()
///         )
///         super.init(router: router)
///     }
/// }
/// ```
///
/// ## Accessing Router State
///
/// While the router is publicly accessible via `coordinator.router`, you should
/// primarily use it to **read** navigation state, not modify it:
///
/// ```swift
/// // Read state
/// let currentRoute = coordinator.router.state.currentRoute
/// let stackDepth = coordinator.router.state.stack.count
///
///
/// ## Observable State
///
/// Router conforms to `ObservableObject` with `@Published var state`, allowing
/// SwiftUI views to automatically react to navigation changes:
///
/// ```swift
/// struct DebugView: View {
///     @ObservedObject var router: Router<AppRoute>
///
///     var body: some View {
///         Text("Current: \(router.state.currentRoute.identifier)")
///     }
/// }
/// ```
///
/// ## Navigation Methods
///
/// Most router methods are framework-internal. Use `Coordinator.navigate(to:)`
/// for all navigation operations instead of calling router methods directly.
///
/// ## See Also
///
/// - `Coordinator` - Owns the router and provides navigation methods
/// - `NavigationState` - The state managed by the router
/// - `ViewFactory` - Builds views for routes
public final class Router<R: Route>: ObservableObject {
    /// The current navigation state.
    ///
    /// This published property contains the complete navigation state including
    /// the root route, stack, selected tab, and presented modals/detours.
    /// Changes to this property automatically trigger SwiftUI view updates.
    ///
    /// - Note: Read-only for clients. Use `Coordinator.navigate(to:)` to modify state.
    @Published public private(set) var state: NavigationState<R>

    private let factory: ViewFactory<R>

    /// Publisher for route changes (type-erased for parent observation)
    /// **Framework internal only** - Exposed via Coordinator.routesDidChange
    let routesDidChange = PassthroughSubject<[any Route], Never>()

    public init(initial: R, factory: ViewFactory<R>) {
        state = NavigationState(root: initial)
        self.factory = factory
    }

    // MARK: - Navigation Methods (Internal - Use Coordinator methods instead)

    /// Push a route onto the navigation stack.
    /// **Internal:** Use `Coordinator.navigate(to:)` instead.
    func push(_ route: R) {
        state.stack.append(route)
        notifyRoutesChanged()
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
        notifyRoutesChanged()
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
        notifyRoutesChanged()
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
    /// **Internal:** Used by TabCoordinator.switchToTab()
    func selectTab(_ index: Int) {
        state.selectedTab = index
    }

    /// Pop all routes and return to root.
    /// **Internal:** Use `Coordinator.popToRoot()` instead.
    func popToRoot() {
        state.stack.removeAll()
        notifyRoutesChanged()
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

    // MARK: - Private Helpers

    /// Notify subscribers that routes have changed
    private func notifyRoutesChanged() {
        let allRoutes: [any Route] = [state.root] + state.stack
        routesDidChange.send(allRoutes)
    }
}
