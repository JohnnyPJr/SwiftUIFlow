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

class TestAppCoordinator: FlowOrchestrator<TestAppRoute> {
    // Typed convenience properties for tests
    var loginCoordinator: TestLoginCoordinator? {
        currentFlow as? TestLoginCoordinator
    }

    var mainTabCoordinator: TestMainTabCoordinator? {
        currentFlow as? TestMainTabCoordinator
    }

    init() {
        let router = Router<TestAppRoute>(initial: .login, factory: DummyFlowFactory())
        super.init(router: router)

        // Start with login flow
        transitionToFlow(TestLoginCoordinator(), root: .login)
    }

    override func handleFlowChange(to route: any Route) -> Bool {
        guard let appRoute = route as? TestAppRoute else { return false }

        switch appRoute {
        case .login:
            transitionToFlow(TestLoginCoordinator(), root: .login)
            return true
        case .mainApp:
            transitionToFlow(TestMainTabCoordinator(), root: .mainApp)
            return true
        }
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
            transitionToFlow(TestLoginCoordinator(), root: .login)
            return true
        case .mainApp:
            transitionToFlow(TestMainTabCoordinator(), root: .mainApp)
            // Simulate service calls after flow transition
            fetchUserProfile()
            loadDashboardData()
            loginCount += 1
            return true
        }
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
