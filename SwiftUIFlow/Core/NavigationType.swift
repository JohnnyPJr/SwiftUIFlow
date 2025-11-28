//
//  NavigationType.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 15/9/25.
//

import Foundation

/// Defines how a route should be presented in the navigation hierarchy.
///
/// Return these values from `Coordinator.navigationType(for:)` to control how
/// the framework navigates to each route. The navigation type determines the
/// visual presentation and behavior when navigating.
///
/// ## Usage
///
/// ```swift
/// class ProductCoordinator: Coordinator<ProductRoute> {
///     override func navigationType(for route: any Route) -> NavigationType {
///         guard let productRoute = route as? ProductRoute else { return .push }
///
///         switch productRoute {
///         case .list, .detail:
///             return .push           // Standard navigation stack
///         case .confirmation:
///             return .replace        // Replace current screen
///         case .checkout:
///             return .modal          // Present as modal sheet
///         }
///     }
/// }
/// ```
///
/// ## See Also
///
/// - `Coordinator.navigationType(for:)` - Override to specify navigation types
/// - `Coordinator.modalDetentConfiguration(for:)` - Configure modal presentation
public enum NavigationType: Equatable {
    /// Push the route onto the navigation stack.
    case push

    /// Replace the current route in the stack with the new route.
    ///
    /// Instead of pushing a new screen, this replaces the current screen while
    /// maintaining the stack depth. Useful for replacing a loading screen with
    /// results, or stepping through a screen where you don't want back navigation.
    case replace

    /// Present the route as a modal sheet.
    case modal
}
