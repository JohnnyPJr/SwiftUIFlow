//
//  FlowChangeTestHelpers.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 5/11/25.
//

import SwiftUI
@testable import SwiftUIFlow

// MARK: - Test Routes

enum TestAppRoute: Route {
    case login
    case mainApp

    var identifier: String {
        switch self {
        case .login: return "login"
        case .mainApp: return "mainApp"
        }
    }
}

// MARK: - Test View Factory

class DummyFlowFactory: ViewFactory<TestAppRoute> {
    override func buildView(for route: TestAppRoute) -> AnyView? {
        return nil
    }
}

// MARK: - Test Coordinators

class TestAppCoordinator: Coordinator<TestAppRoute> {
    var loginCoordinator: TestLoginCoordinator?
    var mainTabCoordinator: TestMainTabCoordinator?

    init() {
        let router = Router<TestAppRoute>(initial: .login, factory: DummyFlowFactory())
        super.init(router: router)
        showLogin()
    }

    override func handleFlowChange(to route: any Route) -> Bool {
        guard let appRoute = route as? TestAppRoute else { return false }

        switch appRoute {
        case .login:
            showLogin()
            return true
        case .mainApp:
            showMainApp()
            return true
        }
    }

    func showLogin() {
        if let current = loginCoordinator ?? mainTabCoordinator {
            removeChild(current)
        }

        let newLoginCoordinator = TestLoginCoordinator()
        addChild(newLoginCoordinator)
        loginCoordinator = newLoginCoordinator
        mainTabCoordinator = nil

        transitionToNewFlow(root: .login)
    }

    func showMainApp() {
        if let current = loginCoordinator ?? mainTabCoordinator {
            removeChild(current)
        }

        let newMainTabCoordinator = TestMainTabCoordinator()
        addChild(newMainTabCoordinator)
        mainTabCoordinator = newMainTabCoordinator
        loginCoordinator = nil

        transitionToNewFlow(root: .mainApp)
    }
}

class TestLoginCoordinator: Coordinator<TestAppRoute> {
    init() {
        let router = Router<TestAppRoute>(initial: .login, factory: DummyFlowFactory())
        super.init(router: router)
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let appRoute = route as? TestAppRoute else { return false }
        return appRoute == .login
    }

    deinit {
        print("🗑️ TestLoginCoordinator deallocated")
    }
}

class TestMainTabCoordinator: Coordinator<TestAppRoute> {
    init() {
        let router = Router<TestAppRoute>(initial: .mainApp, factory: DummyFlowFactory())
        super.init(router: router)
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let appRoute = route as? TestAppRoute else { return false }
        return appRoute == .mainApp
    }

    deinit {
        print("🗑️ TestMainTabCoordinator deallocated")
    }
}

class TestDeepChildCoordinator: Coordinator<TestAppRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        // Can't handle any routes - will bubble to parent
        return false
    }
}

class TestAppCoordinatorWithServiceCalls: TestAppCoordinator {
    var userProfileFetched = false
    var dashboardDataLoaded = false
    var loginCount = 0

    override func handleFlowChange(to route: any Route) -> Bool {
        guard let appRoute = route as? TestAppRoute else { return false }

        switch appRoute {
        case .login:
            showLogin()
            return true
        case .mainApp:
            showMainAppWithServiceCalls()
            return true
        }
    }

    private func showMainAppWithServiceCalls() {
        if let current = loginCoordinator ?? mainTabCoordinator {
            removeChild(current)
        }

        let newMainTabCoordinator = TestMainTabCoordinator()
        addChild(newMainTabCoordinator)
        mainTabCoordinator = newMainTabCoordinator
        loginCoordinator = nil

        // Simulate service calls
        fetchUserProfile()
        loadDashboardData()
        loginCount += 1

        transitionToNewFlow(root: .mainApp)
    }

    private func fetchUserProfile() {
        // Simulate fetching user profile from API
        userProfileFetched = true
    }

    private func loadDashboardData() {
        // Simulate loading dashboard data from API
        dashboardDataLoaded = true
    }
}
