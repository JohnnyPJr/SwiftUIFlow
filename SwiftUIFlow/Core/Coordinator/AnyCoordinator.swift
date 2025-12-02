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
    func buildCoordinatorRouteView(for route: any Route) -> Any

    var tabItem: (text: String, image: String)? { get }

    var allRoutes: [any Route] { get }
    var routesDidChange: AnyPublisher<[any Route], Never> { get }

    var rootRoute: any Route { get }
}

// MARK: - Child Route Wrapper (Internal)
/// A Hashable wrapper for child route + coordinator pairs
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
