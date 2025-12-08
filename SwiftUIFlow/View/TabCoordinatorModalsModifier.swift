//
//  TabCoordinatorModalsModifier.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 8/12/25.
//

import SwiftUI

/// A view modifier that adds modal and detour rendering support to custom tab bar views.
///
/// This modifier is designed for custom tab bar implementations that replace `TabCoordinatorView`.
/// It handles all modal and detour presentation/dismissal logic internally, so clients don't need
/// to access internal framework methods.
///
/// ## Usage Example
///
/// ```swift
/// struct CustomTabBarView: View {
///     let coordinator: MainTabCoordinator
///     @ObservedObject private var router: Router<AppRoute>
///
///     init(coordinator: MainTabCoordinator) {
///         self.coordinator = coordinator
///         router = coordinator.router
///     }
///
///     var body: some View {
///         ZStack(alignment: .bottom) {
///             // Render selected tab's content
///             if router.state.selectedTab < coordinator.children.count {
///                 let child = coordinator.children[router.state.selectedTab]
///                 let coordinatorView = child.buildCoordinatorView()
///                 eraseToAnyView(coordinatorView)
///             }
///
///             // Your custom tab bar UI
///             customTabBar
///         }
///         .withTabCoordinatorModals(coordinator: coordinator)  // ✅ Add this modifier
///     }
/// }
/// ```
///
/// ## What It Handles
///
/// The modifier automatically renders:
/// - **Modal sheets** - Regular modals with detent support
/// - **Fullscreen modals** - Fullscreen cover modals
/// - **Cross-type modals** - Modals with different route types than parent
/// - **Detours** - Fullscreen detours for deep linking
///
/// All dismissal logic is handled internally, including swipe-to-dismiss gestures.
public struct TabCoordinatorModalsModifier<R: Route>: ViewModifier {
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
    /// Adds modal and detour rendering support for custom tab bar implementations.
    ///
    /// Use this modifier when you create a custom tab bar view to replace `TabCoordinatorView`.
    /// It handles all modal sheets, fullscreen modals, and detours automatically.
    ///
    /// - Parameter coordinator: The `TabCoordinator` managing the tab-based navigation
    /// - Returns: A view with modal and detour rendering support
    func withTabCoordinatorModals(coordinator: TabCoordinator<some Route>) -> some View {
        modifier(TabCoordinatorModalsModifier(coordinator: coordinator))
    }
}
