//
//  TabCoordinatorPresentationsModifier.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 8/12/25.
//

import SwiftUI

/// **Advanced modifier** for adding modal and detour presentation support to custom tab bar views.
///
/// ## ⚠️ Most Users Should Use `CustomTabCoordinatorView` Instead
///
/// This modifier is for **advanced use cases** where you need fine-grained control over where
/// presentations are applied in the view hierarchy. For most custom tab bars, use
/// `CustomTabCoordinatorView` wrapper instead—it's safer and prevents forgetting to add this modifier.
///
/// ## When to Use This Modifier
///
/// Use this modifier directly only if you need:
/// - Custom presentation layer ordering
/// - Multiple presentation modifiers in complex view hierarchies
/// - Integration with other custom modifiers that must be ordered specifically
///
/// ## Standard Usage (Use `CustomTabCoordinatorView` Instead)
///
/// ```swift
/// // ✅ RECOMMENDED: Use the wrapper
/// CustomTabCoordinatorView(coordinator: coordinator) {
///     // Your custom tab UI
/// }
///
/// // If Preffered: Manual modifier approach
/// var body: some View {
///     ZStack {
///         // Your custom tab UI
///     }
///     .withTabCoordinatorPresentations(coordinator: coordinator)
/// }
/// ```
///
/// ## What This Handles
///
/// - Modal sheets with detent support
/// - Fullscreen cover modals
/// - Cross-type modals (modals with different route types than parent)
/// - Fullscreen detours for deep linking
/// - All dismissal logic including swipe-to-dismiss gestures
public struct TabCoordinatorPresentationsModifier<R: Route>: ViewModifier {
    private let coordinator: TabCoordinator<R>
    @ObservedObject private var router: Router<R>

    public init(coordinator: TabCoordinator<R>) {
        self.coordinator = coordinator
        router = coordinator.router
    }

    public func body(content: Content) -> some View {
        content
            .sheet(item: shouldUseFullScreenCover ? .constant(nil) : presentedRoute) { route in
                // Render modal sheet with full coordinator navigation support
                if let modalCoordinator = coordinator.currentModalCoordinator {
                    let coordinatorView = modalCoordinator.buildCoordinatorView()
                    eraseToAnyView(coordinatorView)
                } else {
                    ErrorReportingView(error: coordinator
                        .makeError(for: route,
                                   errorType: .viewCreationFailed(viewType: .modal)))
                }
            }
            .sheet(isPresented: hasModalCoordinator, onDismiss: {
                coordinator.dismissModal()
            }) {
                // Render cross-type modal sheet (when coordinator exists but no typed route)
                if let modalCoordinator = coordinator.currentModalCoordinator {
                    let coordinatorView = modalCoordinator.buildCoordinatorView()
                    eraseToAnyView(coordinatorView)
                }
            }
        #if os(iOS)
            .fullScreenCover(item: shouldUseFullScreenCover ? presentedRoute : .constant(nil), onDismiss: {
                coordinator.dismissModal()
            }) { route in
                // Render fullscreen modal with full coordinator navigation support
                if let modalCoordinator = coordinator.currentModalCoordinator {
                    let coordinatorView = modalCoordinator.buildCoordinatorView()
                    eraseToAnyView(coordinatorView)
                } else {
                    ErrorReportingView(error: coordinator
                        .makeError(for: route,
                                   errorType: .viewCreationFailed(viewType: .modal)))
                }
            }
            .fullScreenCover(isPresented: hasDetour, onDismiss: {
                coordinator.dismissDetour()
            }) {
                // Render detour with full coordinator navigation support
                if let detourCoordinator = coordinator.detourCoordinator {
                    let coordinatorView = detourCoordinator.buildCoordinatorView()
                    eraseToAnyView(coordinatorView)
                }
            }
        #endif
    }

    // MARK: - Bindings

    /// Create a binding to the presented modal route that syncs with the coordinator
    private var presentedRoute: Binding<R?> {
        Binding(get: {
                    // Get presented route from router
                    router.state.presented
                },
                set: { newValue in
                    // Handle modal dismissal (user swiped down or tapped X)
                    if newValue == nil, router.state.presented != nil {
                        coordinator.dismissModal()
                    }
                })
    }

    /// Binding for cross-type modal presentation (when modal coordinator exists but no typed route)
    private var hasModalCoordinator: Binding<Bool> {
        Binding(get: {
                    // Modal coordinator exists but no typed route (cross-type modal)
                    coordinator.currentModalCoordinator != nil && router.state.presented == nil
                },
                set: { _ in
                    // This is called when sheet is dismissed by user gesture
                    // The onDismiss closure handles the actual cleanup
                })
    }

    /// Binding for detour presentation state
    private var hasDetour: Binding<Bool> {
        Binding(get: { coordinator.detourCoordinator != nil },
                set: { if !$0 { coordinator.dismissDetour() } })
    }

    /// Check if the current modal should use fullScreenCover
    private var shouldUseFullScreenCover: Bool {
        router.state.modalDetentConfiguration?.shouldUseFullScreenCover ?? false
    }
}

// MARK: - View Extension

public extension View {
    /// Adds modal and detour presentation support for custom tab bar implementations.
    ///
    /// Use this modifier when you create a custom tab bar view to replace `TabCoordinatorView`.
    /// It handles all modal sheets, fullscreen modals, and detours automatically.
    ///
    /// - Parameter coordinator: The `TabCoordinator` managing the tab-based navigation
    /// - Returns: A view with modal and detour presentation support
    func withTabCoordinatorPresentations(coordinator: TabCoordinator<some Route>) -> some View {
        modifier(TabCoordinatorPresentationsModifier(coordinator: coordinator))
    }
}
