//
//  ErrorHandlingIntegrationTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 7/11/25.
//

@testable import SwiftUIFlow
import XCTest

final class ErrorHandlingIntegrationTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        // Reset global error handler after each test
        SwiftUIFlowErrorHandler.shared.reset()
    }

    // MARK: - Navigation Error Tests

    func test_NavigationFailed_CallsErrorHandler() {
        // Given: A coordinator that can't handle a specific route
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let coordinator = Coordinator(router: router)

        var capturedError: SwiftUIFlowError?
        SwiftUIFlowErrorHandler.shared.setHandler { error in
            capturedError = error
        }

        // When: Navigating to a route no one can handle
        let unknownRoute = MockRoute.details // Coordinator can't handle this
        let result = coordinator.navigate(to: unknownRoute)

        // Then: Navigation should fail and error handler should be called
        XCTAssertFalse(result, "Navigation should fail")
        XCTAssertNotNil(capturedError, "Error handler should be called")

        if case let .navigationFailed(coordinator: coordName,
                                      route: routeId,
                                      routeType: _,
                                      context: _) = capturedError
        {
            XCTAssertEqual(coordName, "Coordinator<MockRoute>")
            XCTAssertEqual(routeId, "details")
        } else {
            XCTFail("Expected navigationFailed error")
        }
    }

    func test_NavigationFailed_DefaultBehavior_WithoutErrorHandler() {
        // Given: A coordinator without custom error handler
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let coordinator = Coordinator(router: router)

        // When: Navigating to a route no one can handle
        let unknownRoute = MockRoute.details
        let result = coordinator.navigate(to: unknownRoute)

        // Then: Navigation should fail (default behavior logs and asserts in DEBUG)
        XCTAssertFalse(result, "Navigation should fail")
        // Note: In DEBUG, this would trigger assertionFailure
    }

    // MARK: - Modal Coordinator Configuration Error Tests

    func test_ModalCoordinatorNotConfigured_CallsErrorHandler() {
        // Given: A coordinator with modal NavigationType but no modal coordinator configured
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let coordinator = TestModalNavigationCoordinator(router: router)

        var capturedError: SwiftUIFlowError?
        SwiftUIFlowErrorHandler.shared.setHandler { error in
            capturedError = error
        }

        // When: Trying to navigate to a modal route without modal coordinator
        let result = coordinator.navigate(to: MockRoute.modal)

        // Then: Should fail and call error handler
        XCTAssertFalse(result, "Navigation should fail without modal coordinator")
        XCTAssertNotNil(capturedError, "Error handler should be called")

        if case .modalCoordinatorNotConfigured = capturedError {
            // Success - validation now reports specific error
        } else {
            XCTFail("Expected modalCoordinatorNotConfigured error")
        }
    }

    func test_ModalNavigation_SucceedsWithConfiguredCoordinator() {
        // Given: A coordinator with properly configured modal coordinator
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let coordinator = TestModalNavigationCoordinator(router: router)

        let modalRouter = Router<MockRoute>(initial: .modal, factory: MockViewFactory())
        let modalCoordinator = TestModalChildCoordinator(router: modalRouter)
        coordinator.addModalCoordinator(modalCoordinator)

        var errorCalled = false
        SwiftUIFlowErrorHandler.shared.setHandler { _ in
            errorCalled = true
        }

        // When: Navigating to modal route with proper setup
        let result = coordinator.navigate(to: MockRoute.modal)

        // Then: Should succeed without error
        XCTAssertTrue(result, "Navigation should succeed")
        XCTAssertFalse(errorCalled, "Error handler should not be called")
        XCTAssertEqual(router.state.presented, MockRoute.modal)
    }

    // MARK: - Invalid Detour Navigation Tests

    // MARK: - Configuration Error Tests

    func test_InvalidTabIndex_CallsErrorHandler() {
        // Given: A TabCoordinator with 3 children
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let tabCoordinator = TestErrorTabCoordinator(router: router)

        let child1 = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))
        let child2 = TestCoordinator(router: Router<MockRoute>(initial: .login, factory: MockViewFactory()))
        let child3 = TestCoordinator(router: Router<MockRoute>(initial: .details, factory: MockViewFactory()))

        tabCoordinator.addChild(child1)
        tabCoordinator.addChild(child2)
        tabCoordinator.addChild(child3)

        var capturedError: SwiftUIFlowError?
        SwiftUIFlowErrorHandler.shared.setHandler { error in
            capturedError = error
        }

        // When: Trying to switch to invalid tab index
        tabCoordinator.switchToTab(99)

        // Then: Should call error handler
        XCTAssertNotNil(capturedError, "Error handler should be called")

        if case let .invalidTabIndex(index: index, validRange: range) = capturedError {
            XCTAssertEqual(index, 99)
            XCTAssertEqual(range.lowerBound, 0)
            XCTAssertEqual(range.upperBound, 3)
        } else {
            XCTFail("Expected invalidTabIndex error")
        }

        // Verify tab didn't change
        XCTAssertEqual(router.state.selectedTab, 0, "Tab should not change on invalid index")
    }

    func test_ValidTabIndex_Succeeds() {
        // Given: A TabCoordinator with 3 children
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let tabCoordinator = TestErrorTabCoordinator(router: router)

        let child1 = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))
        let child2 = TestCoordinator(router: Router<MockRoute>(initial: .login, factory: MockViewFactory()))
        let child3 = TestCoordinator(router: Router<MockRoute>(initial: .details, factory: MockViewFactory()))

        tabCoordinator.addChild(child1)
        tabCoordinator.addChild(child2)
        tabCoordinator.addChild(child3)

        var errorCalled = false
        SwiftUIFlowErrorHandler.shared.setHandler { _ in
            errorCalled = true
        }

        // When: Switching to valid tab index
        tabCoordinator.switchToTab(2)

        // Then: Should succeed without error
        XCTAssertFalse(errorCalled, "Error handler should not be called")
        XCTAssertEqual(router.state.selectedTab, 2)
    }

    func test_DuplicateChild_CallsErrorHandler() {
        // Given: A coordinator with a child already added
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let coordinator = TestCoordinator(router: router)

        let child = TestCoordinator(router: Router<MockRoute>(initial: .login, factory: MockViewFactory()))
        coordinator.addChild(child)

        var capturedError: SwiftUIFlowError?
        SwiftUIFlowErrorHandler.shared.setHandler { error in
            capturedError = error
        }

        // When: Trying to add the same child again
        coordinator.addChild(child)

        // Then: Should call error handler
        XCTAssertNotNil(capturedError, "Error handler should be called")

        if case .duplicateChild = capturedError {
            // Success
        } else {
            XCTFail("Expected duplicateChild error")
        }

        // Verify child wasn't added twice
        XCTAssertEqual(coordinator.children.count, 1, "Child should only be added once")
    }

    func test_CircularReference_CallsErrorHandler() {
        // Given: A coordinator
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let coordinator = TestCoordinator(router: router)

        var capturedError: SwiftUIFlowError?
        SwiftUIFlowErrorHandler.shared.setHandler { error in
            capturedError = error
        }

        // When: Trying to add itself as a child
        coordinator.addChild(coordinator)

        // Then: Should call error handler
        XCTAssertNotNil(capturedError, "Error handler should be called")

        if case .circularReference = capturedError {
            // Success
        } else {
            XCTFail("Expected circularReference error")
        }

        // Verify it wasn't added
        XCTAssertEqual(coordinator.children.count, 0, "Coordinator should not be its own child")
    }

    // MARK: - Error Properties Tests

    func test_ErrorProperties_AreAccessible() {
        // Given: Various error types
        let navError = SwiftUIFlowError.navigationFailed(coordinator: "TestCoord",
                                                         route: "testRoute",
                                                         routeType: "MockRoute",
                                                         context: "test context")

        let modalError = SwiftUIFlowError.modalCoordinatorNotConfigured(coordinator: "TestCoord",
                                                                        route: "testRoute",
                                                                        routeType: "MockRoute")

        let tabError = SwiftUIFlowError.invalidTabIndex(index: 5, validRange: 0 ..< 3)

        // Then: Should have proper descriptions and recovery actions
        XCTAssertNotNil(navError.errorDescription)
        XCTAssertFalse(navError.debugDescription.isEmpty)
        XCTAssertFalse(navError.recommendedRecoveryAction.isEmpty)

        XCTAssertNotNil(modalError.errorDescription)
        XCTAssertTrue(modalError.recommendedRecoveryAction.contains("addModalCoordinator"))

        XCTAssertNotNil(tabError.errorDescription)
        XCTAssertTrue(tabError.errorDescription!.contains("5"))
    }

    func test_ErrorEquality() {
        // Given: Same errors
        let error1 = SwiftUIFlowError.navigationFailed(coordinator: "TestCoord",
                                                       route: "testRoute",
                                                       routeType: "MockRoute",
                                                       context: "test")

        let error2 = SwiftUIFlowError.navigationFailed(coordinator: "TestCoord",
                                                       route: "testRoute",
                                                       routeType: "MockRoute",
                                                       context: "test")

        let error3 = SwiftUIFlowError.navigationFailed(coordinator: "OtherCoord",
                                                       route: "testRoute",
                                                       routeType: "MockRoute",
                                                       context: "test")

        // Then: Should be equatable
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }
}

// MARK: - Test Helpers

private class TestModalNavigationCoordinator: Coordinator<MockRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        guard let mockRoute = route as? MockRoute else { return false }
        return mockRoute == .home || mockRoute == .modal
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let mockRoute = route as? MockRoute else { return .push }
        return mockRoute == .modal ? .modal : .push
    }
}

private class TestDetourNavigationCoordinator: Coordinator<MockRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        guard let mockRoute = route as? MockRoute else { return false }
        return mockRoute == .home || mockRoute == .details
    }

    override func navigationType(for route: any Route) -> NavigationType {
        return .push
    }
}

private class TestModalChildCoordinator: Coordinator<MockRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        guard let mockRoute = route as? MockRoute else { return false }
        return mockRoute == .modal
    }
}

private class TestErrorTabCoordinator: TabCoordinator<MockRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        return false // Tabs delegate to children
    }
}
