//
//  Coordinators.swift
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

// MARK: - Red Tab Coordinator

class RedCoordinator: Coordinator<RedRoute> {
    init() {
        let factory = RedViewFactory()
        super.init(router: Router(initial: .red, factory: factory))
        factory.coordinator = self
        let modalCoord = RedModalCoordinator()
        addModalCoordinator(modalCoord)
    }

    override var tabItem: (text: String, image: String)? {
        return ("Red", "paintpalette.fill")
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is RedRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let redRoute = route as? RedRoute else { return .push }

        switch redRoute {
        case .red, .lightRed:
            return .push
        case .darkRed:
            return .modal
        }
    }
}

class RedModalCoordinator: Coordinator<RedRoute> {
    init() {
        let factory = RedViewFactory()
        super.init(router: Router(initial: .darkRed, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let redRoute = route as? RedRoute else { return false }
        return redRoute == .darkRed
    }
}

// MARK: - Green Tab Coordinator

class GreenCoordinator: Coordinator<GreenRoute> {
    init() {
        let factory = GreenViewFactory()
        super.init(router: Router(initial: .green, factory: factory))
        factory.coordinator = self
        let modalCoord = GreenModalCoordinator()
        addModalCoordinator(modalCoord)
    }

    override var tabItem: (text: String, image: String)? {
        return ("Green", "leaf.fill")
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is GreenRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let greenRoute = route as? GreenRoute else { return .push }

        switch greenRoute {
        case .green, .lightGreen:
            return .push
        case .darkGreen:
            return .modal
        }
    }
}

class GreenModalCoordinator: Coordinator<GreenRoute> {
    init() {
        let factory = GreenViewFactory()
        super.init(router: Router(initial: .darkGreen, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let greenRoute = route as? GreenRoute else { return false }
        return greenRoute == .darkGreen
    }
}

// MARK: - Blue Tab Coordinator

class BlueCoordinator: Coordinator<BlueRoute> {
    init() {
        let factory = BlueViewFactory()
        super.init(router: Router(initial: .blue, factory: factory))
        factory.coordinator = self
        let modalCoord = BlueModalCoordinator()
        addModalCoordinator(modalCoord)
    }

    override var tabItem: (text: String, image: String)? {
        return ("Blue", "water.waves")
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is BlueRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let blueRoute = route as? BlueRoute else { return .push }

        switch blueRoute {
        case .blue, .lightBlue:
            return .push
        case .darkBlue:
            return .modal
        }
    }
}

class BlueModalCoordinator: Coordinator<BlueRoute> {
    init() {
        let factory = BlueViewFactory()
        super.init(router: Router(initial: .darkBlue, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let blueRoute = route as? BlueRoute else { return false }
        return blueRoute == .darkBlue
    }
}

// MARK: - Yellow Tab Coordinator

class YellowCoordinator: Coordinator<YellowRoute> {
    init() {
        let factory = YellowViewFactory()
        super.init(router: Router(initial: .yellow, factory: factory))
        factory.coordinator = self
        let modalCoord = YellowModalCoordinator()
        addModalCoordinator(modalCoord)
    }

    override var tabItem: (text: String, image: String)? {
        return ("Yellow", "sun.max.fill")
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is YellowRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let yellowRoute = route as? YellowRoute else { return .push }

        switch yellowRoute {
        case .yellow, .lightYellow:
            return .push
        case .darkYellow:
            return .modal
        }
    }
}

class YellowModalCoordinator: Coordinator<YellowRoute> {
    init() {
        let factory = YellowViewFactory()
        super.init(router: Router(initial: .darkYellow, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let yellowRoute = route as? YellowRoute else { return false }
        return yellowRoute == .darkYellow
    }
}

// MARK: - Purple Tab Coordinator

class PurpleCoordinator: Coordinator<PurpleRoute> {
    init() {
        let factory = PurpleViewFactory()
        super.init(router: Router(initial: .purple, factory: factory))
        factory.coordinator = self
        let modalCoord = PurpleModalCoordinator()
        addModalCoordinator(modalCoord)
    }

    override var tabItem: (text: String, image: String)? {
        return ("Purple", "sparkles")
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is PurpleRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let purpleRoute = route as? PurpleRoute else { return .push }

        switch purpleRoute {
        case .purple, .lightPurple:
            return .push
        case .darkPurple:
            return .modal
        case .result:
            return .replace
        }
    }
}

class PurpleModalCoordinator: Coordinator<PurpleRoute> {
    init() {
        let factory = PurpleViewFactory()
        super.init(router: Router(initial: .darkPurple, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let purpleRoute = route as? PurpleRoute else { return false }
        return purpleRoute == .darkPurple
    }
}
