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
        XCTAssertNotNil(appCoordinator.loginCoordinator,
                        "LoginCoordinator should exist")
        XCTAssertNil(appCoordinator.mainTabCoordinator,
                     "MainTabCoordinator should not exist yet")

        // Store reference to login coordinator to verify deallocation later
        weak var weakLoginCoordinator = appCoordinator.loginCoordinator

        // Navigate to main app (simulate login button tap)
        let success = appCoordinator.loginCoordinator!.navigate(to: TestAppRoute.mainApp)

        // Verify navigation succeeded
        XCTAssertTrue(success, "Flow change should succeed")

        // Verify we're now at main app
        XCTAssertEqual(appCoordinator.router.state.root.identifier, "mainApp",
                       "Should now be at main app")

        // Verify fresh MainTabCoordinator was created
        XCTAssertNotNil(appCoordinator.mainTabCoordinator,
                        "MainTabCoordinator should now exist")
        XCTAssertNil(appCoordinator.loginCoordinator,
                     "LoginCoordinator should be nil")

        // Verify LoginCoordinator was deallocated
        XCTAssertNil(weakLoginCoordinator,
                     "LoginCoordinator should be deallocated")
    }

    func test_LogoutFromMainAppCreatesFreshLoginCoordinator() {
        // Create app coordinator and navigate to main app
        let appCoordinator = TestAppCoordinator()
        _ = appCoordinator.loginCoordinator!.navigate(to: TestAppRoute.mainApp)

        // Verify we're at main app
        XCTAssertNotNil(appCoordinator.mainTabCoordinator,
                        "MainTabCoordinator should exist")

        // Store reference to main tab coordinator to verify deallocation
        weak var weakMainTabCoordinator = appCoordinator.mainTabCoordinator

        // Navigate to login (simulate logout from nested tab)
        let success = appCoordinator.mainTabCoordinator!.navigate(to: TestAppRoute.login)

        // Verify navigation succeeded
        XCTAssertTrue(success, "Flow change should succeed")

        // Verify we're back at login
        XCTAssertEqual(appCoordinator.router.state.root.identifier, "login",
                       "Should be back at login")

        // Verify fresh LoginCoordinator was created
        XCTAssertNotNil(appCoordinator.loginCoordinator,
                        "LoginCoordinator should exist again")
        XCTAssertNil(appCoordinator.mainTabCoordinator,
                     "MainTabCoordinator should be nil")

        // Verify MainTabCoordinator was deallocated
        XCTAssertNil(weakMainTabCoordinator,
                     "MainTabCoordinator should be deallocated")
    }

    func test_MultipleLoginLogoutCyclesCreateFreshCoordinators() {
        let appCoordinator = TestAppCoordinator()

        // Cycle 1: Login -> Logout
        weak var loginCoord1 = appCoordinator.loginCoordinator
        _ = appCoordinator.loginCoordinator!.navigate(to: TestAppRoute.mainApp)
        weak var mainTabCoord1 = appCoordinator.mainTabCoordinator
        _ = appCoordinator.mainTabCoordinator!.navigate(to: TestAppRoute.login)

        // Verify first cycle coordinators were deallocated
        XCTAssertNil(loginCoord1, "First LoginCoordinator should be deallocated")
        XCTAssertNil(mainTabCoord1, "First MainTabCoordinator should be deallocated")

        // Cycle 2: Login -> Logout
        weak var loginCoord2 = appCoordinator.loginCoordinator
        _ = appCoordinator.loginCoordinator!.navigate(to: TestAppRoute.mainApp)
        weak var mainTabCoord2 = appCoordinator.mainTabCoordinator
        _ = appCoordinator.mainTabCoordinator!.navigate(to: TestAppRoute.login)

        // Verify second cycle coordinators were deallocated
        XCTAssertNil(loginCoord2, "Second LoginCoordinator should be deallocated")
        XCTAssertNil(mainTabCoord2, "Second MainTabCoordinator should be deallocated")

        // Verify we're back at login with fresh coordinator
        XCTAssertNotNil(appCoordinator.loginCoordinator,
                        "Should have fresh LoginCoordinator")
        XCTAssertEqual(appCoordinator.router.state.root.identifier, "login",
                       "Should be at login")
    }

    func test_FlowChangeFromDeeplyNestedCoordinatorBubblesToRoot() {
        let appCoordinator = TestAppCoordinator()

        // Navigate to main app
        _ = appCoordinator.loginCoordinator!.navigate(to: TestAppRoute.mainApp)

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
        _ = appCoordinator.loginCoordinator!.navigate(to: TestAppRoute.mainApp)

        // Verify service calls were made
        XCTAssertTrue(appCoordinator.userProfileFetched, "User profile should be fetched after login")
        XCTAssertTrue(appCoordinator.dashboardDataLoaded, "Dashboard data should be loaded after login")
    }

    func test_ServiceCallsRunAgainOnEachLogin() {
        // This test verifies that service calls run fresh on each login
        let appCoordinator = TestAppCoordinatorWithServiceCalls()

        // First login
        _ = appCoordinator.loginCoordinator!.navigate(to: TestAppRoute.mainApp)
        XCTAssertEqual(appCoordinator.loginCount, 1, "Should have logged in once")

        // Logout
        _ = appCoordinator.mainTabCoordinator!.navigate(to: TestAppRoute.login)

        // Reset flags to simulate clean state
        appCoordinator.userProfileFetched = false
        appCoordinator.dashboardDataLoaded = false

        // Second login
        _ = appCoordinator.loginCoordinator!.navigate(to: TestAppRoute.mainApp)
        XCTAssertEqual(appCoordinator.loginCount, 2, "Should have logged in twice")
        XCTAssertTrue(appCoordinator.userProfileFetched, "User profile should be fetched again")
        XCTAssertTrue(appCoordinator.dashboardDataLoaded, "Dashboard data should be loaded again")
    }

    func test_AllChildCoordinatorsAreDeallocatedOnLogout() {
        let appCoordinator = TestAppCoordinator()

        // Navigate to main app
        _ = appCoordinator.loginCoordinator!.navigate(to: TestAppRoute.mainApp)

        weak var weakMainTab: TestMainTabCoordinator?
        weak var weakChild1: TestDeepChildCoordinator?
        weak var weakChild2: TestDeepChildCoordinator?

        // Scope the children so they don't hold strong references after this block
        do {
            // Add multiple nested child coordinators to simulate a complex flow
            let childRouter1 = Router<TestAppRoute>(initial: .mainApp, factory: DummyFlowFactory())
            let child1 = TestDeepChildCoordinator(router: childRouter1)
            appCoordinator.mainTabCoordinator!.addChild(child1)

            let childRouter2 = Router<TestAppRoute>(initial: .mainApp, factory: DummyFlowFactory())
            let child2 = TestDeepChildCoordinator(router: childRouter2)
            child1.addChild(child2)

            weakMainTab = appCoordinator.mainTabCoordinator
            weakChild1 = child1
            weakChild2 = child2
        }

        // Logout - should deallocate entire tree
        _ = appCoordinator.mainTabCoordinator!.navigate(to: TestAppRoute.login)

        // Verify entire coordinator tree was deallocated
        XCTAssertNil(weakMainTab, "MainTabCoordinator should be deallocated")
        XCTAssertNil(weakChild1, "First child should be deallocated")
        XCTAssertNil(weakChild2, "Second child should be deallocated")
    }
}
