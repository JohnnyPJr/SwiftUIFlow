//
//  AnyCoordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 8/8/25.
//

import Combine
import Foundation

/// Public protocol for coordinator UI operations
/// Provides minimal interface for custom UI implementations (e.g., custom tab bars)
public protocol CoordinatorUISupport: AnyObject {
    /// Build a CoordinatorView for this coordinator
    func buildCoordinatorView() -> Any

    /// Tab item configuration (if this coordinator is used as a tab)
    var tabItem: (text: String, image: String)? { get }
}

/// Internal protocol for type-erased coordinator operations
protocol AnyCoordinator: CoordinatorUISupport {
    var parent: AnyCoordinator? { get set }

    /// How this coordinator is presented in the navigation hierarchy.
    /// **Set by framework only** - Do not modify directly.
    var presentationContext: CoordinatorPresentationContext { get set }

    func navigationType(for route: any Route) -> NavigationType
    func navigate(to route: any Route, from caller: AnyCoordinator?) -> Bool
    func validateNavigationPath(to route: any Route, from caller: AnyCoordinator?) -> ValidationResult
    func canHandle(_ route: any Route) -> Bool
    func canNavigate(to route: any Route) -> Bool
    func resetToCleanState()
    func dismissModal()
    func dismissDetour()
    func pop()

    func buildView(for route: any Route) -> Any?
    func buildCoordinatorView() -> Any

    /// Build a view for a specific route with modal/detour presentation support
    /// Used for rendering child coordinator routes in flattened navigation
    /// Returns type-erased Any to avoid SwiftUI dependency in protocol
    func buildCoordinatorRouteView(for route: any Route) -> Any

    var tabItem: (text: String, image: String)? { get }

    /// All routes for this coordinator (root + stack)
    /// Used for flattening child routes into parent's NavigationPath
    var allRoutes: [any Route] { get }

    /// Publisher that emits when this coordinator's routes change
    /// Type-erased so parent coordinators can subscribe without knowing route type
    var routesDidChange: AnyPublisher<[any Route], Never> { get }
}

// MARK: - Child Route Wrapper (Internal)
/// A Hashable wrapper for child route + coordinator pairs
/// **Framework internal only** - Used for flattened navigation
struct ChildRouteWrapper: Hashable {
    let route: any Route
    let coordinator: AnyCoordinator

    func hash(into hasher: inout Hasher) {
        hasher.combine(route.identifier)
        hasher.combine(ObjectIdentifier(coordinator))
    }

    static func == (lhs: ChildRouteWrapper, rhs: ChildRouteWrapper) -> Bool {
        return lhs.route.identifier == rhs.route.identifier &&
            lhs.coordinator === rhs.coordinator
    }
}
