//
//  TabCoordinatorView.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 31/10/25.
//

import SwiftUI

/// A SwiftUI view that renders a tab-based coordinator's navigation state.
///
/// This view creates a TabView with each child coordinator rendered in its own tab.
/// It observes the coordinator's router and automatically updates when tab selection changes.
///
/// Usage:
/// ```swift
/// struct MyApp: View {
///     let tabCoordinator: MyTabCoordinator
///
///     var body: some View {
///         TabCoordinatorView(coordinator: tabCoordinator)
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
            ForEach(Array(coordinator.children.enumerated()), id: \.offset) { index, child in
                tabContent(for: child, at: index)
                    .tag(index)
            }
        }
    }

    /// Create the content for a single tab
    @ViewBuilder
    private func tabContent(for child: AnyCoordinator, at index: Int) -> some View {
        // Each tab gets its own CoordinatorView with NavigationStack
        // The coordinator returns a CoordinatorView which we need to type-erase
        let coordinatorView = child.buildCoordinatorView()

        // Wrap in AnyView to handle the type erasure
        eraseToAnyView(coordinatorView)
            .tabItem {
                // Tab coordinators should provide custom tab labels
                // For now, use a default label
                Label("Tab \(index + 1)", systemImage: "\(index + 1).circle")
            }
    }

    /// Helper to type-erase any view
    private func eraseToAnyView(_ view: Any) -> AnyView {
        // The view should be a SwiftUI View, so we can cast it
        if let swiftUIView = view as? any View {
            return AnyView(swiftUIView)
        } else {
            return AnyView(Text("View unavailable"))
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
