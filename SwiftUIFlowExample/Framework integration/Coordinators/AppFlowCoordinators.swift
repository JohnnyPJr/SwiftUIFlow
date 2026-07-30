//
//  AppFlowCoordinators.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import Foundation
import OSLog
import SwiftUIFlow

// MARK: - App Coordinator (Root Orchestrator)

/// Root coordinator that orchestrates major app flows.
/// Manages transitions between Login and MainTab coordinators.
/// Never recreated - exists for the lifetime of the app.
class AppCoordinator: FlowOrchestrator<AppRoute> {
    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .login, factory: factory))
        factory.coordinator = self
        // Start with login flow
        transitionToFlow(LoginCoordinator(), root: .login)
    }

    override func canHandle(_ route: any Route) -> Bool {
        // AppCoordinator doesn't directly handle routes - it delegates to child flow coordinators
        return false
    }

    /// Check if this coordinator can handle flow changes (without executing them).
    /// Used during navigation validation to avoid side effects.
    override func canHandleFlowChange(to route: any Route) -> Bool {
        guard let appRoute = route as? AppRoute else { return false }
        return appRoute == .login || appRoute == .tabRoot
    }

    /// Handle flow changes when routes bubble to the root.
    /// This is called when LoginCoordinator or any child coordinator navigates
    /// to an AppRoute that they can't handle - it bubbles here for orchestration.
    override func handleFlowChange(to route: any Route) -> Bool {
        guard let appRoute = route as? AppRoute else {
            return false
        }

        switch appRoute {
        case .login:
            transitionToFlow(LoginCoordinator(), root: .login)
            return true
        case .tabRoot:
            transitionToFlow(MainTabCoordinator(), root: .tabRoot)
            return true
        }
    }
}

// MARK: - Login Coordinator

/// Login flow coordinator.
/// Handles login, signup, forgot password flows.
/// Created fresh on logout, deallocated after successful login.
class LoginCoordinator: Coordinator<AppRoute> {
    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .login, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let appRoute = route as? AppRoute else { return false }
        return appRoute == .login
    }

    deinit {
        Logger(subsystem: "com.swiftuiflow.example", category: "Lifecycle").info("🗑️ LoginCoordinator deallocated")
    }
}

// MARK: - Main Tab Coordinator

/// Main tab coordinator that manages the 5 tabs.
/// This coordinator is RECREATED each time the user logs in,
/// ensuring fresh state and allowing service calls to run.
class MainTabCoordinator: TabCoordinator<AppRoute> {
    var redCoordinator: RedCoordinator!
    var greenCoordinator: GreenCoordinator!
    var blueCoordinator: BlueCoordinator!
    var yellowCoordinator: YellowCoordinator!
    var purpleCoordinator: PurpleCoordinator!

    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .tabRoot, factory: factory))
        factory.coordinator = self

        // Create fresh child coordinators
        redCoordinator = RedCoordinator()
        greenCoordinator = GreenCoordinator()
        blueCoordinator = BlueCoordinator()
        yellowCoordinator = YellowCoordinator()
        purpleCoordinator = PurpleCoordinator()

        addChild(redCoordinator)
        addChild(greenCoordinator)
        addChild(blueCoordinator)
        addChild(yellowCoordinator)
        addChild(purpleCoordinator)
    }

    override func canHandle(_ route: any Route) -> Bool {
        // MainTabCoordinator only delegates to children, never handles directly
        return false
    }

    deinit {
        Logger(subsystem: "com.swiftuiflow.example", category: "Lifecycle").info("🗑️ MainTabCoordinator deallocated")
    }
}
