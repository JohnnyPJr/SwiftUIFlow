//
//  TabCoordinatorView.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 31/10/25.
//

import SwiftUI

/// **Convenience view** for rendering a tab-based coordinator using SwiftUI's native `TabView`.
///
/// This view provides a quick, standard implementation of tab-based navigation using the native
/// iOS tab bar appearance. Use this when you want the standard iOS tab bar look and feel.
///
/// ## When to Use This
///
/// ✅ You want the **native iOS tab bar** appearance
/// ✅ You want a **quick, zero-configuration** solution
/// ✅ You don't need custom tab bar styling
///
/// ## Basic Usage
///
/// ```swift
/// struct MyApp: View {
///     let tabCoordinator: MyTabCoordinator
///
///     var body: some View {
///         TabCoordinatorView(coordinator: tabCoordinator)  // ✅ That's it!
///     }
/// }
/// ```
///
/// ## Want a Custom Tab Bar Instead?
///
/// If you need custom tab bar styling (floating tabs, sidebar, custom animations, etc.),
/// use `CustomTabCoordinatorView` instead. See its documentation for examples.
///
/// ## Features
///
/// - Automatically renders each child coordinator in its own tab
/// - Uses each coordinator's `tabItem` property for tab labels and icons
/// - Syncs tab selection with coordinator state
/// - Handles all modal sheets, fullscreen modals, and detours automatically
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
        .withTabCoordinatorPresentations(coordinator: coordinator)
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
