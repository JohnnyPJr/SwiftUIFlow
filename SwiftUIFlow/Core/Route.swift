//
//  Route.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Foundation

/// The fundamental protocol that all routes must conform to in SwiftUIFlow.
///
/// Define your app's navigation destinations as enum cases conforming to `Route`.
/// Each route represents a unique screen or destination in your app's navigation flow.
///
/// ## Basic Usage
///
/// Create an enum for each coordinator's routes:
///
/// ```swift
/// enum ProductRoute: Route {
///     case list
///     case detail(productId: String)
///     case checkout
///
///     var identifier: String {
///         switch self {
///         case .list: return "product_list"
///         case .detail(let id): return "product_detail_\(id)"
///         case .checkout: return "checkout"
///         }
///     }
/// }
/// ```
///
/// ## Requirements
///
/// - **Hashable**: Routes must be hashable to work with SwiftUI's NavigationPath
/// - **Identifiable**: Routes need unique IDs for navigation and analytics
/// - **identifier**: Provide a unique string identifier for each route
///
/// ## Automatic Conformance
///
/// For simple enums without associated values, the identifier can match the case name:
///
/// ```swift
/// enum SettingsRoute: Route {
///     case profile
///     case notifications
///     case privacy
///
///     var identifier: String {
///         String(describing: self)  // Returns "profile", "notifications", etc.
///     }
/// }
/// ```
///
/// ## Routes with Associated Values
///
/// Include associated values in the identifier for uniqueness:
///
/// ```swift
/// enum UserRoute: Route {
///     case profile(userId: String)
///     case posts(userId: String)
///
///     var identifier: String {
///         switch self {
///         case .profile(let id): return "profile_\(id)"
///         case .posts(let id): return "posts_\(id)"
///         }
///     }
/// }
/// ```
///
/// ## Best Practices
///
/// - Use descriptive, lowercase identifiers with underscores (e.g., "product_detail")
/// - Include relevant associated values in identifiers for uniqueness
/// - Keep route definitions simple - complex logic belongs in coordinators
/// - Group related routes into the same enum
///
/// ## See Also
///
/// - `Coordinator` - Manages navigation for routes
/// - `ViewFactory.buildView(for:)` - Maps routes to views
public protocol Route: Hashable, Identifiable {
    /// A unique string identifier for this route.
    ///
    /// Used for navigation logging, analytics, and route comparison. Should be
    /// unique across all cases of your route enum, including associated values.
    ///
    /// ## Example
    ///
    /// ```swift
    /// enum AppRoute: Route {
    ///     case home
    ///     case settings
    ///     case profile(userId: String)
    ///
    ///     var identifier: String {
    ///         switch self {
    ///         case .home: return "home"
    ///         case .settings: return "settings"
    ///         case .profile(let id): return "profile_\(id)"
    ///         }
    ///     }
    /// }
    /// ```
    var identifier: String { get }
}

/// Default implementation of `Identifiable.id` using the route's identifier.
///
/// This allows routes to automatically conform to `Identifiable` without
/// additional implementation. SwiftUI uses `id` for list rendering and animations.
public extension Route {
    /// The stable identity of this route, derived from its identifier.
    var id: String { identifier }
}
