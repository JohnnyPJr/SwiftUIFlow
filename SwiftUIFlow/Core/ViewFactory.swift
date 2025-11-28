//
//  ViewFactory.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 7/8/25.
//

import Combine
import Foundation
import SwiftUI

/// Factory class responsible for mapping routes to SwiftUI views.
///
/// `ViewFactory` separates view creation logic from navigation logic, keeping coordinators
/// focused on navigation flow while factories handle view instantiation and dependency injection.
///
/// ## Basic Usage
///
/// Subclass `ViewFactory` and override `buildView(for:)` to map your routes to views:
///
/// ```swift
/// class ProductViewFactory: ViewFactory<ProductRoute> {
///     override func buildView(for route: ProductRoute) -> AnyView? {
///         switch route {
///         case .list:
///             return view(ProductListView())
///         case .detail(let id):
///             return view(ProductDetailView(productId: id))
///         case .checkout:
///             return view(CheckoutView())
///         }
///     }
/// }
/// ```
///
/// ## Dependency Injection
///
/// ViewFactories are ideal for injecting dependencies into views:
///
/// ```swift
/// class ProductViewFactory: ViewFactory<ProductRoute> {
///     private let apiClient: APIClient
///
///     init(apiClient: APIClient) {
///         self.apiClient = apiClient
///         super.init()
///     }
///
///     override func buildView(for route: ProductRoute) -> AnyView? {
///         switch route {
///         case .list:
///             return view(ProductListView(apiClient: apiClient))
///         case .detail(let id):
///             return view(ProductDetailView(productId: id, apiClient: apiClient))
///         }
///     }
/// }
/// ```
///
/// ## Accessing the Coordinator
///
/// ViewFactories maintain a weak reference to their owning coordinator, allowing views
/// to trigger navigation through the factory:
///
/// ```swift
/// class ProductViewFactory: ViewFactory<ProductRoute> {
///     override func buildView(for route: ProductRoute) -> AnyView? {
///         switch route {
///         case .list:
///             return view(ProductListView(
///                 onSelect: { id in
///                     self.coordinator?.navigate(to: ProductRoute.detail(id: id))
///                 }
///             ))
///         }
///     }
/// }
/// ```
///
/// ## See Also
///
/// - `Coordinator` - Manages navigation and owns the ViewFactory
/// - `Router` - Uses the ViewFactory to build views for routes
open class ViewFactory<R: Route>: ObservableObject {
    /// Weak reference to the coordinator that owns this factory.
    /// Set this in your coordinator's init: `factory.coordinator = self`
    public weak var coordinator: Coordinator<R>?

    public init() {}

    /// Build and return the SwiftUI view for a given route.
    ///
    /// Override this method in your ViewFactory subclass to map routes to their corresponding views.
    /// Use the `view(_:)` helper to wrap your views in AnyView.
    ///
    /// - Parameter route: The route to build a view for
    /// - Returns: An AnyView containing the view for this route, or `nil` if the route is not recognized
    open func buildView(for route: R) -> AnyView? { nil }

    /// Helper to wrap any View in AnyView for cleaner syntax
    public func view(_ view: some View) -> AnyView {
        return AnyView(view)
    }
}
