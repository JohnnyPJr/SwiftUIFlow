//
//  CoordinatorRouteView.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 20/11/25.
//

import SwiftUI

// MARK: - Coordinator Route View

/// A view that renders a single route from a coordinator with full modal/detour presentation support
/// This allows pushed child coordinators to present modals and detours
struct CoordinatorRouteView<R: Route>: View {
    let coordinator: Coordinator<R>
    let route: any Route
    @ObservedObject var router: Router<R>

    init(coordinator: Coordinator<R>, route: any Route) {
        self.coordinator = coordinator
        self.route = route
        router = coordinator.router
    }

    var body: some View {
        Group {
            if let viewAny = coordinator.buildView(for: route),
               let view = viewAny as? AnyView
            {
                view
                    .environment(\.navigationBackAction) {
                        if let parent = coordinator.parent {
                            parent.pop()
                        }
                    }
                    .environment(\.canNavigateBack, true)
            } else {
                Text("Failed to build view for \(route.identifier)")
            }
        }
        // Same modal presentation as CoordinatorView
        .sheet(isPresented: Binding(get: { coordinator.currentModalCoordinator != nil && router.state.presented == nil },
                                    set: { if !$0 { coordinator.dismissModal() }}))
        {
            if let modal = coordinator.currentModalCoordinator {
                let coordinatorView = modal.buildCoordinatorView()
                eraseToAnyView(coordinatorView)
            }
        }
        .sheet(item: Binding(get: { router.state.presented },
                             set: { if $0 == nil { coordinator.dismissModal() }}))
        { _ in
            if let modal = coordinator.currentModalCoordinator {
                let coordinatorView = modal.buildCoordinatorView()
                eraseToAnyView(coordinatorView)
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: Binding(get: { coordinator.detourCoordinator != nil },
                                              set: { if !$0 { coordinator.dismissDetour() }}))
        {
            if let detour = coordinator.detourCoordinator {
                let coordinatorView = detour.buildCoordinatorView()
                eraseToAnyView(coordinatorView)
            }
        }
        #else
        .sheet(isPresented: Binding(get: { coordinator.detourCoordinator != nil },
                                    set: { if !$0 { coordinator.dismissDetour() }}))
        {
            if let detour = coordinator.detourCoordinator {
                let coordinatorView = detour.buildCoordinatorView()
                eraseToAnyView(coordinatorView)
            }
                }
        #endif
    }
}

// MARK: - Child Coordinator Route View

/// A wrapper view that renders a child coordinator's route with full modal/detour presentation support
/// This allows pushed children to present modals and detours from their views
struct ChildCoordinatorRouteView: View {
    let wrapper: ChildRouteWrapper

    var body: some View {
        // buildCoordinatorRouteView returns CoordinatorRouteView as Any
        // Cast it to a View and wrap in AnyView for type erasure
        if let view = wrapper.coordinator.buildCoordinatorRouteView(for: wrapper.route) as? any View {
            AnyView(view)
        } else {
            AnyView(Text("Failed to build coordinator route view"))
        }
    }
}
