//
//  IntegrationTestHelpers.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 7/8/25.
//

import Foundation
import SwiftUI
@testable import SwiftUIFlow

// MARK: - Routes
enum MainTabRoute: Route {
    case tab1, tab2, tab3, tab4, tab5
    var identifier: String { "\(self)" }
}

enum Tab2Route: Route {
    case startUnlock
    var identifier: String { "\(self)" }
}

enum UnlockRoute: Route {
    case enterCode, loading, success, failure
    var identifier: String { "\(self)" }
}

enum UnlockResultRoute: Route {
    case showResult
    var identifier: String { "\(self)" }
}

enum Tab5Route: Route {
    case batteryStatus
    var identifier: String { "\(self)" }
}

enum AppFlowRoute: Route {
    case onboarding, login, home
    var identifier: String { "\(self)" }
}

enum LoginRoute: Route {
    case enterEmail, enterPassword, twoFactor
    var identifier: String { "\(self)" }
}

enum OnboardingRoute: Route {
    case welcome, step1, step2
    var identifier: String { "\(self)" }
}

enum HomeRoute: Route {
    case dashboard
    var identifier: String { "\(self)" }
}

enum PasswordResetRoute: Route {
    case enterCode, verifying, newPassword, success
    var identifier: String { "\(self)" }
}

// MARK: - Factories

final class DummyFactory<R: Route>: ViewFactory<R> {
    override func buildView(for route: R) -> AnyView? {
        AnyView(EmptyView())
    }
}

// MARK: - Coordinators

// MARK: - MainTabCoordinator

final class MainTabCoordinator: TabCoordinator<MainTabRoute> {
    private let tab2: Tab2Coordinator
    private let tab5: Tab5Coordinator

    override init(router: Router<MainTabRoute>) {
        // Initialize tab coordinators
        tab2 = Tab2Coordinator(router: Router(initial: .startUnlock, factory: DummyFactory()))
        tab5 = Tab5Coordinator(router: Router(initial: .batteryStatus, factory: DummyFactory()))

        super.init(router: router)

        // Add them as children (now parent will be set correctly)
        // Adding placeholder coordinators for tabs 1, 3, 4
        addChild(Coordinator(router: Router(initial: MainTabRoute.tab1, factory: DummyFactory())))
        addChild(tab2)
        addChild(Coordinator(router: Router(initial: MainTabRoute.tab3, factory: DummyFactory())))
        addChild(Coordinator(router: Router(initial: MainTabRoute.tab4, factory: DummyFactory())))
        addChild(tab5)
    }

    override func canHandle(_ route: any Route) -> Bool {
        // Tab coordinator handles tab routes to switch tabs
        return route is MainTabRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        // Map MainTabRoute to tab indices
        guard let tabRoute = route as? MainTabRoute else {
            return .push // Not a tab route, use default
        }

        let tabIndex = switch tabRoute {
        case .tab1: 0
        case .tab2: 1
        case .tab3: 2
        case .tab4: 3
        case .tab5: 4
        }

        return .tabSwitch(index: tabIndex)
    }

    func switchTab(to index: Int) {
        switchToTab(index)
    }

    override func resetToCleanState() {
        super.resetToCleanState()
        // Reset all child tabs when main coordinator resets
        for child in children {
            child.resetToCleanState()
        }
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}

// MARK: - Tab2Coordinator

final class Tab2Coordinator: Coordinator<Tab2Route> {
    private let unlock: UnlockCoordinator

    override init(router: Router<Tab2Route>) {
        // Create child coordinators eagerly - app knows its flow upfront
        unlock = UnlockCoordinator(router: Router(initial: .enterCode, factory: DummyFactory()))

        super.init(router: router)

        // Add children to hierarchy
        addChild(unlock)
    }

    override func canHandle(_ route: any Route) -> Bool {
        // Tab2 can handle Tab2Routes directly
        guard let route = route as? Tab2Route else { return false }
        return route == .startUnlock
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}

// MARK: - UnlockCoordinator

final class UnlockCoordinator: Coordinator<UnlockRoute> {
    var result: UnlockResultCoordinator?

    override func canHandle(_ route: any Route) -> Bool {
        guard let route = route as? UnlockRoute else { return false }

        // Pure query - no side effects
        switch route {
        case .enterCode, .loading, .failure, .success:
            return true
        }
    }

    override func navigate(to route: any Route, from caller: AnyCoordinator? = nil) -> Bool {
        // Special handling for .success route - present modal and return early
        if let unlockRoute = route as? UnlockRoute, unlockRoute == .success {
            // Create and present result modal if needed
            if result == nil {
                result = UnlockResultCoordinator(router: Router(initial: .showResult, factory: DummyFactory()))
                presentModal(result!, presenting: .success)
            }
            return true // We handled it - don't call super
        }

        // For all other routes, use base class logic
        return super.navigate(to: route, from: caller)
    }

    override func shouldDismissModalFor(route: any Route) -> Bool {
        // Dismiss modal for non-unlock related routes
        return !(route is UnlockRoute || route is UnlockResultRoute)
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}

final class UnlockResultCoordinator: Coordinator<UnlockResultRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        guard let route = route as? UnlockResultRoute else { return false }
        return route == .showResult
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}

// MARK: - Tab5Coordinator

final class Tab5Coordinator: Coordinator<Tab5Route> {
    private(set) var didHandleBatteryStatus = false

    override func canHandle(_ route: any Route) -> Bool {
        guard let route = route as? Tab5Route else { return false }

        if route == .batteryStatus {
            didHandleBatteryStatus = true
            return true
        }
        return false
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}

// MARK: - Replace Navigation Test Coordinators

final class PasswordResetCoordinator: Coordinator<PasswordResetRoute> {
    override func navigationType(for route: any Route) -> NavigationType {
        guard let route = route as? PasswordResetRoute else { return .push }

        // Use replace for verifying, newPassword, and success (can't go back to previous steps)
        switch route {
        case .verifying, .newPassword, .success:
            return .replace
        case .enterCode:
            return .push
        }
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is PasswordResetRoute
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}

// MARK: - SetRoot Test Coordinators

final class AppFlowCoordinator: Coordinator<AppFlowRoute> {
    private var onboardingCoordinator: OnboardingFlowCoordinator?
    private var loginCoordinator: LoginFlowCoordinator?
    private var homeCoordinator: HomeFlowCoordinator?

    override init(router: Router<AppFlowRoute>) {
        super.init(router: router)

        // Create initial coordinator based on root
        switch router.state.root {
        case .onboarding:
            onboardingCoordinator = OnboardingFlowCoordinator(router: Router(initial: .welcome,
                                                                             factory: DummyFactory()))
            addChild(onboardingCoordinator!)
        case .login:
            loginCoordinator = LoginFlowCoordinator(router: Router(initial: .enterEmail, factory: DummyFactory()))
            addChild(loginCoordinator!)
        case .home:
            homeCoordinator = HomeFlowCoordinator(router: Router(initial: .dashboard, factory: DummyFactory()))
            addChild(homeCoordinator!)
        }
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is AppFlowRoute
    }

    // Helper: Remove all flow coordinators
    private func removeAllFlows() {
        if let onboarding = onboardingCoordinator {
            removeChild(onboarding)
            onboardingCoordinator = nil
        }
        if let login = loginCoordinator {
            removeChild(login)
            loginCoordinator = nil
        }
        if let home = homeCoordinator {
            removeChild(home)
            homeCoordinator = nil
        }
    }

    override func navigate(to route: any Route, from caller: AnyCoordinator? = nil) -> Bool {
        guard let appRoute = route as? AppFlowRoute else {
            return super.navigate(to: route, from: caller)
        }

        // Handle major flow transitions with setRoot
        switch appRoute {
        case .onboarding:
            if onboardingCoordinator == nil {
                removeAllFlows()
                onboardingCoordinator = OnboardingFlowCoordinator(router: Router(initial: .welcome,
                                                                                 factory: DummyFactory()))
                addChild(onboardingCoordinator!)
                router.setRoot(.onboarding)
            }
            return true

        case .login:
            if loginCoordinator == nil {
                removeAllFlows()
                loginCoordinator = LoginFlowCoordinator(router: Router(initial: .enterEmail, factory: DummyFactory()))
                addChild(loginCoordinator!)
                router.setRoot(.login)
            }
            return true

        case .home:
            if homeCoordinator == nil {
                removeAllFlows()
                homeCoordinator = HomeFlowCoordinator(router: Router(initial: .dashboard, factory: DummyFactory()))
                addChild(homeCoordinator!)
                router.setRoot(.home)
            }
            return true
        }
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}

final class LoginFlowCoordinator: Coordinator<LoginRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        return route is LoginRoute
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}

final class OnboardingFlowCoordinator: Coordinator<OnboardingRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        return route is OnboardingRoute
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}

final class HomeFlowCoordinator: Coordinator<HomeRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        return route is HomeRoute
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}
