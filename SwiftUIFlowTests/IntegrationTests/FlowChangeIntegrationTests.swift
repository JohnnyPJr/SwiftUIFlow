//
//  FlowChangeIntegrationTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 5/11/25.
//

import SwiftUI
@testable import SwiftUIFlow
import XCTest

final class FlowChangeIntegrationTests: XCTestCase {
    // MARK: - Login/Logout Flow Tests

    func test_LoginToMainAppCreatesFreshCoordinators() {
        // Create app coordinator (starts at login)
        let appCoordinator = TestAppCoordinator()

        // Verify we start at login
        XCTAssertEqual(appCoordinator.router.state.root.identifier, "login",
                       "Should start at login")
        XCTAssertTrue(appCoordinator.currentFlow is TestLoginCoordinator,
                      "Current flow should be LoginCoordinator")

        // Track login coordinator for memory leaks
        let loginCoordinator = appCoordinator.loginCoordinator!
        trackForMemoryLeaks(loginCoordinator)

        // Navigate to main app (simulate login button tap)
        let success = loginCoordinator.navigate(to: TestAppRoute.mainApp)

        // Verify navigation succeeded
        XCTAssertTrue(success, "Flow change should succeed")

        // Verify we're now at main app
        XCTAssertEqual(appCoordinator.router.state.root.identifier, "mainApp",
                       "Should now be at main app")

        // Verify fresh MainTabCoordinator was created
        XCTAssertTrue(appCoordinator.currentFlow is TestMainTabCoordinator,
                      "Current flow should be MainTabCoordinator")
    }

    func test_LogoutFromMainAppCreatesFreshLoginCoordinator() {
        // Create app coordinator and navigate to main app
        let appCoordinator = TestAppCoordinator()
        appCoordinator.loginCoordinator!.navigate(to: TestAppRoute.mainApp)

        // Verify we're at main app
        XCTAssertNotNil(appCoordinator.currentFlow,
                        "MainTabCoordinator should exist")

        // Track main tab coordinator for memory leaks
        let mainTabCoordinator = appCoordinator.mainTabCoordinator!
        trackForMemoryLeaks(mainTabCoordinator)

        // Navigate to login (simulate logout from nested tab)
        let success = mainTabCoordinator.navigate(to: TestAppRoute.login)

        // Verify navigation succeeded
        XCTAssertTrue(success, "Flow change should succeed")

        // Verify we're back at login
        XCTAssertEqual(appCoordinator.router.state.root.identifier, "login",
                       "Should be back at login")

        // Verify fresh LoginCoordinator was created
        XCTAssertTrue(appCoordinator.currentFlow is TestLoginCoordinator,
                      "Current flow should be LoginCoordinator")
    }

    func test_MultipleLoginLogoutCyclesCreateFreshCoordinators() {
        let appCoordinator = TestAppCoordinator()

        // Cycle 1: Login -> Logout
        let loginCoord1 = appCoordinator.loginCoordinator!
        trackForMemoryLeaks(loginCoord1)
        loginCoord1.navigate(to: TestAppRoute.mainApp)

        let mainTabCoord1 = appCoordinator.mainTabCoordinator!
        trackForMemoryLeaks(mainTabCoord1)
        mainTabCoord1.navigate(to: TestAppRoute.login)

        // Cycle 2: Login -> Logout
        let loginCoord2 = appCoordinator.loginCoordinator!
        trackForMemoryLeaks(loginCoord2)
        loginCoord2.navigate(to: TestAppRoute.mainApp)

        let mainTabCoord2 = appCoordinator.mainTabCoordinator!
        trackForMemoryLeaks(mainTabCoord2)
        mainTabCoord2.navigate(to: TestAppRoute.login)

        // Verify we're back at login with fresh coordinator
        XCTAssertNotNil(appCoordinator.currentFlow,
                        "Should have fresh LoginCoordinator")
        XCTAssertEqual(appCoordinator.router.state.root.identifier, "login",
                       "Should be at login")
    }

    func test_FlowChangeFromDeeplyNestedCoordinatorBubblesToRoot() {
        let appCoordinator = TestAppCoordinator()

        // Navigate to main app
        appCoordinator.loginCoordinator!.navigate(to: TestAppRoute.mainApp)

        // Create a deeply nested child coordinator
        let childRouter = Router<TestAppRoute>(initial: .mainApp, factory: DummyFlowFactory())
        let childCoordinator = TestDeepChildCoordinator(router: childRouter)
        appCoordinator.mainTabCoordinator!.addChild(childCoordinator)

        // Navigate to login from deep child - should bubble all the way to AppCoordinator
        let success = childCoordinator.navigate(to: TestAppRoute.login)

        XCTAssertTrue(success, "Should bubble to root and handle flow change")
        XCTAssertEqual(appCoordinator.router.state.root.identifier, "login",
                       "Should be back at login via bubbling")
    }

    func test_ServiceCallIntegrationPointAfterLogin() {
        // This test verifies that service calls can be made when transitioning to main app
        let appCoordinator = TestAppCoordinatorWithServiceCalls()

        // Initially service call should not have been made
        XCTAssertFalse(appCoordinator.userProfileFetched, "User profile should not be fetched yet")
        XCTAssertFalse(appCoordinator.dashboardDataLoaded, "Dashboard data should not be loaded yet")

        // Navigate to main app (simulate login)
        appCoordinator.loginCoordinator!.navigate(to: TestAppRoute.mainApp)

        // Verify service calls were made
        XCTAssertTrue(appCoordinator.userProfileFetched, "User profile should be fetched after login")
        XCTAssertTrue(appCoordinator.dashboardDataLoaded, "Dashboard data should be loaded after login")
    }

    func test_ServiceCallsRunAgainOnEachLogin() {
        // This test verifies that service calls run fresh on each login
        let appCoordinator = TestAppCoordinatorWithServiceCalls()

        // First login
        appCoordinator.loginCoordinator!.navigate(to: TestAppRoute.mainApp)
        XCTAssertEqual(appCoordinator.loginCount, 1, "Should have logged in once")

        // Logout
        appCoordinator.mainTabCoordinator!.navigate(to: TestAppRoute.login)

        // Reset flags to simulate clean state
        appCoordinator.userProfileFetched = false
        appCoordinator.dashboardDataLoaded = false

        // Second login
        appCoordinator.loginCoordinator!.navigate(to: TestAppRoute.mainApp)
        XCTAssertEqual(appCoordinator.loginCount, 2, "Should have logged in twice")
        XCTAssertTrue(appCoordinator.userProfileFetched, "User profile should be fetched again")
        XCTAssertTrue(appCoordinator.dashboardDataLoaded, "Dashboard data should be loaded again")
    }

    func test_AllChildCoordinatorsAreDeallocatedOnLogout() {
        let appCoordinator = TestAppCoordinator()

        // Navigate to main app
        appCoordinator.loginCoordinator!.navigate(to: TestAppRoute.mainApp)

        let mainTab = appCoordinator.mainTabCoordinator!
        trackForMemoryLeaks(mainTab)

        // Add multiple nested child coordinators to simulate a complex flow
        let childRouter1 = Router<TestAppRoute>(initial: .mainApp, factory: DummyFlowFactory())
        let child1 = TestDeepChildCoordinator(router: childRouter1)
        trackForMemoryLeaks(child1)
        mainTab.addChild(child1)

        let childRouter2 = Router<TestAppRoute>(initial: .mainApp, factory: DummyFlowFactory())
        let child2 = TestDeepChildCoordinator(router: childRouter2)
        trackForMemoryLeaks(child2)
        child1.addChild(child2)

        // Logout - should deallocate entire tree
        mainTab.navigate(to: TestAppRoute.login)
    }
}
