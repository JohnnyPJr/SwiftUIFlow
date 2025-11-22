//
//  AnyCoordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 8/8/25.
//

import Combine
import Foundation

public protocol AnyCoordinator: AnyObject {
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

    /// Present a detour coordinator
    func presentDetour(_ coordinator: AnyCoordinator, presenting route: any Route)

    /// Dismiss the currently presented modal
    func dismissModal()

    /// Dismiss the currently presented detour
    func dismissDetour()

    /// Pop one screen from the navigation stack
    func pop()

    /// Build a view for a given route using this coordinator's ViewFactory
    /// Returns type-erased Any to avoid SwiftUI dependency in protocol
    func buildView(for route: any Route) -> Any?

    /// Build a CoordinatorView for this coordinator with full navigation support
    /// Returns type-erased Any to avoid SwiftUI dependency in protocol
    func buildCoordinatorView() -> Any

    /// Build a view for a specific route with modal/detour presentation support
    /// Used for rendering child coordinator routes in flattened navigation
    /// Returns type-erased Any to avoid SwiftUI dependency in protocol
    func buildCoordinatorRouteView(for route: any Route) -> Any

    /// Tab item configuration for coordinators used as tabs
    /// Return nil if this coordinator is not used as a tab
    var tabItem: (text: String, image: String)? { get }

    /// All routes for this coordinator (root + stack)
    /// Used for flattening child routes into parent's NavigationPath
    var allRoutes: [any Route] { get }

    /// Publisher that emits when this coordinator's routes change
    /// Type-erased so parent coordinators can subscribe without knowing route type
    var routesDidChange: AnyPublisher<[any Route], Never> { get }
}

// MARK: - Hashable Wrappers for NavigationPath

/// A wrapper for child routes that includes coordinator reference
/// This allows rendering child routes in parent's NavigationStack (flattened hierarchy)
public struct ChildRouteWrapper: Hashable {
    public let route: any Route
    public let coordinator: AnyCoordinator

    public init(route: any Route, coordinator: AnyCoordinator) {
        self.route = route
        self.coordinator = coordinator
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(route.identifier)
        hasher.combine(ObjectIdentifier(coordinator))
    }

    public static func == (lhs: ChildRouteWrapper, rhs: ChildRouteWrapper) -> Bool {
        return lhs.route.identifier == rhs.route.identifier && lhs.coordinator === rhs.coordinator
    }
}
