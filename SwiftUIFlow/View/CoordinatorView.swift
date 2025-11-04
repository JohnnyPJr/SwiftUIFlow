//
//  CoordinatorView.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 30/10/25.
//

import SwiftUI

/// A SwiftUI view that renders a coordinator's navigation state.
///
/// This view observes the coordinator's router and automatically updates when navigation changes.
/// It handles NavigationStack rendering and will support modals/sheets in subsequent updates.
///
/// Usage:
/// ```swift
/// struct MyApp: View {
///     let coordinator: MyCoordinator
///
///     var body: some View {
///         CoordinatorView(coordinator: coordinator)
///     }
/// }
/// ```
public struct CoordinatorView<R: Route>: View {
    private let coordinator: Coordinator<R>
    @ObservedObject private var router: Router<R>

    public init(coordinator: Coordinator<R>) {
        self.coordinator = coordinator
        router = coordinator.router
    }

    public var body: some View {
        NavigationStack(path: navigationPath) {
            // Render root view
            if let rootView = router.view(for: router.state.root) {
                rootView
                    .environment(\.navigationBackAction) { coordinator.pop() }
                    // Root view back button visibility determined by presentation context
                    .environment(\.canNavigateBack, coordinator.presentationContext.shouldShowBackButton)
                    .navigationDestination(for: R.self) { route in
                        // Render pushed views
                        router.view(for: route)
                            .environment(\.navigationBackAction) { coordinator.pop() }
                            .environment(\.canNavigateBack, true) // Pushed views can go back
                    }
            } else {
                // Fallback if view factory doesn't provide a view
                Text("No view for route: \(router.state.root.identifier)")
                    .foregroundColor(.red)
            }
        }
        .sheet(item: presentedRoute) { route in
            // Render modal sheet using the modal coordinator
            if let modalCoordinator = coordinator.currentModalCoordinator,
               let modalView = modalCoordinator.buildView(for: route) as? AnyView
            {
                modalView
                    .environment(\.navigationBackAction) { coordinator.dismissModal() }
                    .environment(\.canNavigateBack, true) // Modals always show back button
            } else {
                Text("No view for modal route: \(route.identifier)")
                    .foregroundColor(.red)
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: hasDetour, onDismiss: {
            // Handle detour dismissal (user swiped down or dismissed)
            coordinator.dismissDetour()
        }) {
            // Render detour with its own navigation wrapper
            if let detourCoordinator = coordinator.detourCoordinator,
               let detourRoute = router.state.detour
            {
                NavigationStack {
                    // Use buildView to get just the view, then wrap it ourselves
                    if let detourView = detourCoordinator.buildView(for: detourRoute) as? AnyView {
                        detourView
                            .environment(\.navigationBackAction) { coordinator.dismissDetour() }
                            .environment(\.canNavigateBack, true) // Detours always show back button
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button(action: {
                                        coordinator.dismissDetour()
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "chevron.left")
                                                .font(.system(size: 17, weight: .semibold))
                                            Text("Back")
                                        }
                                    }
                                }
                            }
                    } else {
                        Text("Detour view not available")
                            .foregroundColor(.red)
                    }
                }
            } else {
                Text("Detour view not available")
                    .foregroundColor(.red)
            }
        }
        #else
                // macOS: fullScreenCover is not available, use sheet instead
        .sheet(isPresented: hasDetour, onDismiss: {
                    coordinator.dismissDetour()
                }) {
                    if let detourCoordinator = coordinator.detourCoordinator,
                       let detourRoute = router.state.detour
                    {
                        NavigationStack {
                            if let detourView = detourCoordinator.buildView(for: detourRoute) as? AnyView {
                                detourView
                                    .environment(\.navigationBackAction) { coordinator.dismissDetour() }
                                    .environment(\.canNavigateBack, true) // Detours always show back button
                                    .toolbar {
                                        ToolbarItem(placement: .cancellationAction) {
                                            Button(action: {
                                                coordinator.dismissDetour()
                                            }) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "chevron.left")
                                                        .font(.system(size: 17, weight: .semibold))
                                                    Text("Back")
                                                }
                                            }
                                        }
                                    }
                            } else {
                                Text("Detour view not available")
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        Text("Detour view not available")
                            .foregroundColor(.red)
                    }
                }
        #endif
    }

    /// Create a binding to the navigation path that syncs with the coordinator
    private var navigationPath: Binding<[R]> {
        Binding(get: {
                    // Get current stack from router
                    router.state.stack
                },
                set: { newStack in
                    // Handle back navigation (user tapped back or swiped)
                    let currentStack = router.state.stack

                    if newStack.count < currentStack.count {
                        // User went back - pop the difference
                        let popCount = currentStack.count - newStack.count
                        for _ in 0 ..< popCount {
                            coordinator.pop()
                        }
                    }
                    // Note: Forward navigation is handled by coordinator.navigate(),
                    // not through this binding. This binding only handles back navigation.
                })
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
                    // Note: Presenting modals is handled by coordinator.navigate() with .modal NavigationType
                })
    }

    /// Create a binding to track detour presentation state
    private var hasDetour: Binding<Bool> {
        Binding(get: {
                    // Check if detour is present
                    router.state.detour != nil
                },
                set: { _ in
                    // This is called when fullScreenCover is dismissed by user gesture
                    // The onDismiss closure handles the actual cleanup
                })
    }
}
