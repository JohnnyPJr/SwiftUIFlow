//
//  TabCoordinatorView.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 31/10/25.
//

import SwiftUI

/// **Convenience view** for rendering a tab-based coordinator using SwiftUI's native `TabView`.
///
/// This view provides a quick, standard implementation of tab-based navigation by:
/// - Creating a `TabView` with each child coordinator rendered in its own tab
/// - Using each coordinator's `tabItem` property for tab labels and icons
/// - Automatically syncing tab selection with the coordinator's state
///
/// ## Important: This is Optional!
///
/// `TabCoordinatorView` is a **convenience helper**, not a requirement. You can build completely
/// custom tab bar UIs by directly observing the `TabCoordinator`'s state:
/// - Access tabs via `coordinator.children`
/// - Read selected tab via `coordinator.router.state.selectedTab`
/// - Switch tabs via `coordinator.switchToTab(index)`
/// - Render each tab using `child.buildCoordinatorView()`
///
/// This allows you to create custom tab bars with any design (floating, sidebar, custom animations, etc.)
/// while preserving all navigation capabilities (modals, detours, navigation stacks).
///
/// ## Basic Usage (Standard TabView):
/// ```swift
/// struct MyApp: View {
///     let tabCoordinator: MyTabCoordinator
///
///     var body: some View {
///         TabCoordinatorView(coordinator: tabCoordinator)
///     }
/// }
/// ```
///
/// ## Custom Tab Bar Example:
/// ```swift
/// struct CustomTabBar: View {
///     let coordinator: MyTabCoordinator
///     @ObservedObject private var router: Router<MyRoute>
///
///     init(coordinator: MyTabCoordinator) {
///         self.coordinator = coordinator
///         self.router = coordinator.router
///     }
///
///     var body: some View {
///         VStack {
///             // Render selected tab's content
///             if router.state.selectedTab < coordinator.children.count {
///                 let child = coordinator.children[router.state.selectedTab]
///                 eraseToAnyView(child.buildCoordinatorView())
///             }
///
///             // Your custom tab bar UI
///             HStack {
///                 ForEach(coordinator.children.indices, id: \.self) { index in
///                     Button("Tab \(index)") {
///                         coordinator.switchToTab(index)
///                     }
///                 }
///             }
///         }
///         .withTabCoordinatorModals(coordinator: coordinator)  // Add modal/detour support
///     }
/// }
/// ```
public struct TabCoordinatorView<R: Route>: View {
    private let coordinator: TabCoordinator<R>
    @ObservedObject private var router: Router<R>

    public init(coordinator: TabCoordinator<R>) {
        self.coordinator = coordinator
        router = coordinator.router
    }

    public var body: some View {
        TabView(selection: selectedTabBinding) {
            ForEach(Array(coordinator.internalChildren.enumerated()), id: \.offset) { index, child in
                tabContent(for: child, at: index)
                    .tag(index)
            }
        }
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

    /// Create the content for a single tab
    @ViewBuilder
    private func tabContent(for child: AnyCoordinator, at index: Int) -> some View {
        if let item = child.tabItem {
            // Coordinator provided tab item - render normally
            let coordinatorView = child.buildCoordinatorView()
            eraseToAnyView(coordinatorView)
                .tabItem {
                    Label(item.text, systemImage: item.image)
                }
        } else {
            // Programmer error: tab coordinator didn't provide tabItem
            let coordinatorName = String(describing: type(of: child))
            let error = SwiftUIFlowError.configurationError(
                message: "Tab coordinator '\(coordinatorName)' at index \(index) must override 'tabItem' property"
            )
            ErrorReportingView(error: error)
                .tabItem {
                    Label("Error", systemImage: "exclamationmark.triangle")
                }
        }
    }

    /// Create a binding to the selected tab that syncs with the coordinator
    private var selectedTabBinding: Binding<Int> {
        Binding(get: {
                    // Get current selected tab from router
                    router.state.selectedTab
                },
                set: { newIndex in
                    // Handle tab switching (user tapped different tab)
                    coordinator.switchToTab(newIndex)
                })
    }
}
