//
//  NavigationState.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Foundation

/// The navigation state for a coordinator, tracking the current navigation hierarchy.
///
/// This struct contains all the navigation state managed by a `Router`. Clients can
/// read this state via `coordinator.router.state` to inspect the current navigation
/// position, check what's on the stack, or observe state changes.
///
/// ## Usage
///
/// ```swift
/// // Check current route
/// let current = coordinator.router.state.currentRoute
///
/// // Check if we're at root
/// if coordinator.router.state.stack.isEmpty {
///     Logger().info("At root of navigation")
/// }
///
/// // Get navigation depth
/// let depth = coordinator.router.state.stack.count
///
/// // Check if modal is presented
/// if coordinator.router.state.presented != nil {
///     Logger().info("Modal is active")
/// }
/// ```
///
/// ## Observing State Changes
///
/// Since `Router` is an `ObservableObject` with `@Published var state`, you can
/// observe navigation state changes in SwiftUI views:
///
/// ```swift
/// struct NavigationDebugView: View {
///     @ObservedObject var router: Router<AppRoute>
///
///     var body: some View {
///         VStack {
///             Text("Current: \(router.state.currentRoute.identifier)")
///             Text("Stack depth: \(router.state.stack.count)")
///         }
///     }
/// }
/// ```
///
/// - Note: This struct is read-only for clients. Use `Coordinator.navigate(to:)` to modify navigation state.
public struct NavigationState<R: Route>: Equatable {
    /// The root route of this coordinator's navigation hierarchy.
    ///
    /// This is the initial route set when creating the `Router`. It cannot be changed
    /// except by `FlowOrchestrator` during major flow transitions.
    public var root: R

    /// The navigation stack of pushed routes.
    ///
    /// Each element represents a route that was pushed via `.push` navigation type.
    /// The last element in the stack is the currently visible route (if no modal is presented).
    public var stack: [R]

    /// The currently selected tab index (for TabCoordinator only).
    ///
    /// For non-tab coordinators, this remains at its default value of 0.
    /// For `TabCoordinator`, this tracks which child coordinator is currently active.
    public var selectedTab: Int

    /// The currently presented modal route, if any.
    ///
    /// When a route is navigated to with `.modal` navigation type, it's stored here.
    /// When the modal is dismissed, this becomes `nil`.
    public var presented: R?

    /// The currently presented detour route, if any.
    ///
    /// Detours are full-screen overlays that preserve underlying navigation context.
    /// Type-erased because detour coordinators can use different route types.
    public var detour: (any Route)?

    /// Child coordinators currently pushed in the navigation stack
    /// **Framework internal only** - Maintained in parallel with the route stack for rendering
    var pushedChildren: [AnyCoordinator]

    /// Configuration for modal presentation detents (sheet sizes).
    ///
    /// When a modal is presented, this contains the available detent options
    /// (small, medium, large, etc.) configured via `modalDetentConfiguration(for:)`.
    public var modalDetentConfiguration: ModalDetentConfiguration?

    /// The current route being displayed to the user.
    ///
    /// Returns the route that's actually visible on screen, following this priority:
    /// 1. Presented modal route (if modal is active)
    /// 2. Top of navigation stack (if stack is not empty)
    /// 3. Root route (if at the root of navigation)
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Update analytics based on current route
    /// func trackCurrentScreen() {
    ///     let route = coordinator.router.state.currentRoute
    ///     Analytics.trackScreen(route.identifier)
    /// }
    /// ```
    public var currentRoute: R {
        return presented ?? stack.last ?? root
    }

    public init(root: R) {
        self.root = root
        stack = []
        selectedTab = 0
        presented = nil
        detour = nil
        pushedChildren = []
        modalDetentConfiguration = nil
    }

    public static func == (lhs: NavigationState<R>, rhs: NavigationState<R>) -> Bool {
        lhs.root == rhs.root &&
            lhs.stack == rhs.stack &&
            lhs.selectedTab == rhs.selectedTab &&
            lhs.presented == rhs.presented &&
            lhs.detour?.identifier == rhs.detour?.identifier &&
            lhs.pushedChildren.count == rhs.pushedChildren.count &&
            zip(lhs.pushedChildren, rhs.pushedChildren).allSatisfy { $0 === $1 } &&
            lhs.modalDetentConfiguration == rhs.modalDetentConfiguration
    }
}
