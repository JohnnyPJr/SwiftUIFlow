//
//  CustomTabCoordinatorView.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 9/12/25.
//

import SwiftUI

/// **Wrapper view** for building custom tab bar designs with automatic presentation support.
///
/// Use this when you want to create a custom tab bar UI (floating tabs, sidebar, custom animations, etc.)
/// while ensuring modals and detours work automatically. This is the **recommended approach** for custom
/// tab bars because it handles all presentation logic for you.
///
/// ## When to Use This
///
/// ✅ You want a **custom tab bar design** (not the native iOS tab bar)
/// ✅ You want **automatic modal/detour support** (recommended)
/// ✅ You want to **prevent forgetting** to add presentation modifiers
///
/// ## Why This Approach?
///
/// Custom tab bars need to handle modal sheets, fullscreen modals, and detours. This wrapper does it
/// automatically, so you can focus on your custom UI without worrying about presentation logic.
///
/// ## Basic Usage
///
/// ```swift
/// struct MyCustomTabBar: View {
///     let coordinator: MainTabCoordinator
///     @ObservedObject private var router: Router<MainTabRoute>
///
///     init(coordinator: MainTabCoordinator) {
///         self.coordinator = coordinator
///         self.router = coordinator.router
///     }
///
///     var body: some View {
///         CustomTabCoordinatorView(coordinator: coordinator) {
///             ZStack(alignment: .bottom) {
///                 // Render selected tab's content
///                 if router.state.selectedTab < coordinator.children.count {
///                     let child = coordinator.children[router.state.selectedTab]
///                     eraseToAnyView(child.buildCoordinatorView())
///                 }
///
///                 // Your custom tab bar UI
///                 customTabBar
///             }
///         }
///     }
///
///     private var customTabBar: some View {
///         HStack {
///             ForEach(coordinator.children.indices, id: \.self) { index in
///                 Button("Tab \(index)") {
///                     coordinator.switchToTab(index)
///                 }
///             }
///         }
///         .padding()
///         .background(Color.white)
///     }
/// }
/// ```
///
/// ## What It Handles Automatically
///
/// - ✅ Modal sheets with detent support
/// - ✅ Fullscreen cover modals
/// - ✅ Cross-type modals (modals with different route types than parent)
/// - ✅ Fullscreen detours for deep linking
/// - ✅ Swipe-to-dismiss gesture handling
/// - ✅ All presentation/dismissal logic
///
/// ## Alternative: Manual Modifier (Advanced)
///
/// For advanced use cases where you need fine-grained control over presentation layering,
/// use `.withTabCoordinatorPresentations(coordinator:)` directly. See `TabCoordinatorPresentationsModifier`
/// documentation for details.
///
/// However, this wrapper is **strongly recommended** because:
/// - You can't forget to add presentation support (compile-time safety)
/// - Clearer intent and better readability
/// - Less boilerplate code
public struct CustomTabCoordinatorView<R: Route, Content: View>: View {
    private let coordinator: TabCoordinator<R>
    private let content: Content

    /// Creates a custom tab coordinator view with automatic presentation handling.
    ///
    /// - Parameters:
    ///   - coordinator: The `TabCoordinator` managing the tab-based navigation
    ///   - content: A closure that returns your custom tab bar UI
    public init(coordinator: TabCoordinator<R>, @ViewBuilder content: () -> Content) {
        self.coordinator = coordinator
        self.content = content()
    }

    public var body: some View {
        content
            .withTabCoordinatorPresentations(coordinator: coordinator)
    }
}
