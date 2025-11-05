//
//  FlowOrchestrator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 5/11/25.
//

import Foundation

/// A specialized coordinator for orchestrating major application flows.
///
/// `FlowOrchestrator` simplifies the common pattern of managing transitions between
/// major application flows (e.g., Login ↔ Main App, Onboarding → Home). It automatically
/// handles coordinator lifecycle management, ensuring previous flows are deallocated and
/// new flows are created fresh.
///
/// ## Usage
///
/// Subclass `FlowOrchestrator` for your root coordinator and override `handleFlowChange(to:)`
/// to define your flow transitions:
///
/// ```swift
/// class AppCoordinator: FlowOrchestrator<AppRoute> {
///     init() {
///         let router = Router(initial: .login, factory: AppViewFactory())
///         super.init(router: router)
///
///         // Start with initial flow
///         transitionToFlow({ LoginCoordinator() }, root: .login)
///     }
///
///     override func handleFlowChange(to route: any Route) -> Bool {
///         guard let appRoute = route as? AppRoute else { return false }
///
///         switch appRoute {
///         case .login:
///             transitionToFlow({ LoginCoordinator() }, root: .login)
///             return true
///         case .mainApp:
///             transitionToFlow({ MainTabCoordinator() }, root: .mainApp)
///             return true
///         }
///     }
/// }
/// ```
///
/// ## Benefits
///
/// - **Automatic cleanup**: Previous flow coordinators are deallocated
/// - **Fresh state**: New coordinators created on each transition
/// - **Reduced boilerplate**: Eliminates repetitive cleanup/setup code
/// - **Consistent pattern**: Enforces best practices across all apps
/// - **Type safety**: Compiler ensures correct route types
///
/// ## How It Works
///
/// When you call `transitionToFlow(_:root:)`, the orchestrator:
/// 1. Removes and deallocates the previous flow coordinator (if any)
/// 2. Creates a new coordinator using the provided factory closure
/// 3. Adds the new coordinator as a child
/// 4. Transitions to the new root route
///
/// The factory closure pattern allows you to perform any necessary setup
/// before returning the coordinator.
open class FlowOrchestrator<R: Route>: Coordinator<R> {
    /// The currently active flow coordinator.
    ///
    /// This property holds a reference to the coordinator managing the current flow.
    /// It's automatically updated when calling `transitionToFlow(_:root:)`.
    public private(set) var currentFlow: AnyCoordinator?

    /// Transition to a new application flow.
    ///
    /// This method handles the complete lifecycle of flow transitions:
    /// - Deallocates the previous flow coordinator
    /// - Installs the new flow coordinator
    /// - Transitions the router to the new root
    ///
    /// Dependencies should be injected via the coordinator's initializer.
    /// Service calls should happen after calling this method.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Simple transition
    /// transitionToFlow(LoginCoordinator(), root: .login)
    ///
    /// // With dependencies
    /// transitionToFlow(
    ///     MainTabCoordinator(userService: userService),
    ///     root: .mainApp
    /// )
    ///
    /// // With service calls after transition
    /// transitionToFlow(MainTabCoordinator(), root: .mainApp)
    /// fetchUserProfile()
    /// loadDashboardData()
    /// ```
    ///
    /// - Parameters:
    ///   - coordinator: The new flow coordinator to install
    ///   - root: The new root route to transition to
    public func transitionToFlow(_ coordinator: AnyCoordinator, root: R) {
        // 1. Deallocate old flow
        if let current = currentFlow {
            removeChild(current)
        }

        // 2. Install new flow
        addChild(coordinator)
        currentFlow = coordinator

        // 3. Transition root
        transitionToNewFlow(root: root)
    }
}
