//
//  CoordinatorView.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 30/10/25.
//

import Combine
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

    // Cached stack of all pushed child routes (flattened)
    @State private var pushedChildStack: [ChildRouteWrapper] = []
    @State private var cancellables: Set<AnyCancellable> = []

    public init(coordinator: Coordinator<R>) {
        self.coordinator = coordinator
        router = coordinator.router
    }

    public var body: some View {
        return bodyContent
    }

    private var bodyContent: some View {
        NavigationStack(path: navigationPath) {
            // Render root view
            if let rootView = router.view(for: router.state.root) {
                rootView
                    .environment(\.navigationBackAction) { coordinator.pop() }
                    // Root view back button visibility determined by presentation context
                    .environment(\.canNavigateBack, coordinator.presentationContext.shouldShowBackButton)
                    .navigationDestination(for: R.self) { route in
                        // Render pushed views
                        if let view = router.view(for: route) {
                            view
                                .environment(\.navigationBackAction) { coordinator.pop() }
                                .environment(\.canNavigateBack, true) // Pushed views can go back
                        } else {
                            // Report error immediately and show empty view
                            ErrorReportingView(error: coordinator
                                .makeError(for: route,
                                           errorType: .viewCreationFailed(viewType: .pushed)))
                        }
                    }
                    .navigationDestination(for: ChildRouteWrapper.self) { wrapper in
                        // Render child coordinator routes with full modal/detour support
                        ChildCoordinatorRouteView(wrapper: wrapper)
                    }
            } else {
                // Fallback if view factory doesn't provide a view
                ErrorReportingView(error: coordinator
                    .makeError(for: router.state.root,
                               errorType: .viewCreationFailed(viewType: .root)))
            }
        }
        .onReceive(router.$state) { _ in
            // When router state changes (including pushedChildren), setup subscriptions
            setupChildSubscriptions()
        }
        .sheet(item: shouldUseFullScreenCover ? .constant(nil) : presentedRoute) { route in
            // Render modal sheet with full coordinator navigation support
            if let modalCoordinator = coordinator.currentModalCoordinator {
                let coordinatorView = modalCoordinator.buildCoordinatorView()
                eraseToAnyView(coordinatorView)
                    .onPreferenceChange(IdealHeightPreferenceKey.self) { height in
                        updateIdealHeight(height)
                    }
                    .onPreferenceChange(MinHeightPreferenceKey.self) { height in
                        updateMinHeight(height)
                    }
                    .presentationDetents(presentationDetentsSet,
                                         selection: presentationDetentSelection)
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
                    .onPreferenceChange(IdealHeightPreferenceKey.self) { height in
                        updateIdealHeight(height)
                    }
                    .onPreferenceChange(MinHeightPreferenceKey.self) { height in
                        updateMinHeight(height)
                    }
                    .presentationDetents(presentationDetentsSet,
                                         selection: presentationDetentSelection)
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
        #endif
        #if os(iOS)
        .fullScreenCover(isPresented: hasDetour, onDismiss: {
            // Handle detour dismissal (user swiped down or dismissed)
            coordinator.dismissDetour()
        }) {
            // Render detour with full coordinator navigation support
            if let detourCoordinator = coordinator.detourCoordinator {
                let coordinatorView = detourCoordinator.buildCoordinatorView()
                eraseToAnyView(coordinatorView)
            } else {
                if let detourRoute = router.state.detour {
                    ErrorReportingView(error: coordinator
                        .makeError(for: detourRoute,
                                   errorType: .viewCreationFailed(viewType: .detour)))
                }
            }
        }
        #else
                // macOS: fullScreenCover is not available, use sheet instead
        .sheet(isPresented: hasDetour, onDismiss: {
                    coordinator.dismissDetour()
                }) {
                    // Render detour with full coordinator navigation support
                    if let detourCoordinator = coordinator.detourCoordinator {
                        let coordinatorView = detourCoordinator.buildCoordinatorView()
                        eraseToAnyView(coordinatorView)
                    } else {
                        if let detourRoute = router.state.detour {
                            ErrorReportingView(error: coordinator
                                .makeError(for: detourRoute,
                                           errorType: .viewCreationFailed(viewType: .detour)))
                        }
                    }
                }
        #endif
    }

    /// Create a binding to the navigation path that syncs with the coordinator
    private var navigationPath: Binding<NavigationPath> {
        Binding(get: {
                    // Build flattened path with parent routes + cached child routes
                    var path = NavigationPath()

                    // Add parent's routes
                    for route in router.state.stack {
                        path.append(route)
                    }

                    // Add child routes (from cached stack)
                    for wrapper in pushedChildStack {
                        path.append(wrapper)
                    }

                    return path
                },
                set: { newPath in
                    // Handle back navigation (user tapped back or swiped)
                    let currentTotalCount = router.state.stack.count + pushedChildStack.count
                    let newCount = newPath.count

                    if newCount < currentTotalCount {
                        // User swiped back - pop the difference
                        let popCount = currentTotalCount - newCount
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

    // MARK: - Modal Detent Support

    /// Check if the current modal should use fullScreenCover
    private var shouldUseFullScreenCover: Bool {
        router.state.modalDetentConfiguration?.shouldUseFullScreenCover ?? false
    }

    /// Convert modal detent configuration to SwiftUI PresentationDetent set
    private var presentationDetentsSet: Set<PresentationDetent> {
        guard let config = router.state.modalDetentConfiguration else {
            return [.large]
        }

        return Set(config.detents.map { config.toPresentationDetent($0) })
    }

    /// Create a binding for the currently selected presentation detent
    private var presentationDetentSelection: Binding<PresentationDetent> {
        Binding(get: {
                    guard let config = router.state.modalDetentConfiguration,
                          let selected = config.selectedDetent
                    else {
                        return .large
                    }
                    return config.toPresentationDetent(selected)
                },
                set: { newDetent in
                    guard let config = router.state.modalDetentConfiguration else { return }
                    let modalDetent = config.fromPresentationDetent(newDetent)
                    router.updateModalSelectedDetent(modalDetent)
                })
    }

    /// Update the ideal height in the modal detent configuration
    private func updateIdealHeight(_ height: CGFloat?) {
        router.updateModalIdealHeight(height)
    }

    /// Update the minimum height in the modal detent configuration
    private func updateMinHeight(_ height: CGFloat?) {
        router.updateModalMinHeight(height)
    }

    // MARK: - Child Route Observation

    /// Setup subscriptions to child coordinators' route changes
    private func setupChildSubscriptions() {
        // Clear existing subscriptions
        cancellables.removeAll()

        // Subscribe to each child's routesDidChange publisher
        for child in router.state.pushedChildren {
            child.routesDidChange
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    rebuildPushedChildStack()
                }
                .store(in: &cancellables)
        }

        // Initial build of child stack
        rebuildPushedChildStack()
    }

    /// Rebuild the flattened stack of all pushed child routes
    private func rebuildPushedChildStack() {
        pushedChildStack = router.state.pushedChildren.flatMap { child in
            child.allRoutes.map { route in
                ChildRouteWrapper(route: route, coordinator: child)
            }
        }
    }
}
