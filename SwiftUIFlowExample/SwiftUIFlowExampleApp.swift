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
        // AppCoordinator now handles initialization internally
        // It starts at login and manages flow transitions via handleFlowChange
        appCoordinator = AppCoordinator()
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
            // Use our completely custom tab bar with MainTabCoordinator
            if let mainTabCoordinator = appState.appCoordinator.currentFlow as? MainTabCoordinator {
                CustomTabBarView(coordinator: mainTabCoordinator)
            } else {
                Text("Main app loading...")
            }
        case .login:
            // Render login coordinator
            if let loginCoordinator = appState.appCoordinator.currentFlow as? LoginCoordinator {
                CoordinatorView(coordinator: loginCoordinator)
            } else {
                Text("Login loading...")
            }
        }
    }
}
