//
//  AnyCoordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 8/8/25.
//

import Foundation

public protocol AnyCoordinator: AnyObject {
    var parent: AnyCoordinator? { get set }

    /// How this coordinator is presented in the navigation hierarchy
    var presentationContext: CoordinatorPresentationContext { get set }

    func navigationType(for route: any Route) -> NavigationType
    func navigate(to route: any Route, from caller: AnyCoordinator?) -> Bool
    func canHandle(_ route: any Route) -> Bool
    func canNavigate(to route: any Route) -> Bool
    func resetToCleanState()

    /// Dismiss the currently presented modal
    func dismissModal()

    /// Dismiss the currently presented detour
    func dismissDetour()

    /// Build a view for a given route using this coordinator's ViewFactory
    /// Returns type-erased Any to avoid SwiftUI dependency in protocol
    func buildView(for route: any Route) -> Any?

    /// Build a CoordinatorView for this coordinator with full navigation support
    /// Returns type-erased Any to avoid SwiftUI dependency in protocol
    func buildCoordinatorView() -> Any

    /// Tab item configuration for coordinators used as tabs
    /// Return nil if this coordinator is not used as a tab
    var tabItem: (text: String, image: String)? { get }
}
