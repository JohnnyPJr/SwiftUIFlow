//
//  SwiftUIFlowExampleApp.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI
import SwiftUIFlow

@main
struct SwiftUIFlowExampleApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppRootView(appState: appState)
        }
    }
}

class AppState: ObservableObject {
    let appCoordinator: AppCoordinator

    init() {
        appCoordinator = AppCoordinator()
        // Start with login screen
        appCoordinator.transitionToNewFlow(root: .login)
    }
}

struct AppRootView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var router: Router<AppRoute>

    init(appState: AppState) {
        self.appState = appState
        router = appState.appCoordinator.router
    }

    var body: some View {
        // Observe router.state.root to rebuild when it changes
        let currentRoot = router.state.root

        // Dynamically render based on current root
        switch currentRoot {
        case .tabRoot:
            TabCoordinatorView(coordinator: appState.appCoordinator)
        case .login:
            CoordinatorView(coordinator: appState.appCoordinator)
        }
    }
}
