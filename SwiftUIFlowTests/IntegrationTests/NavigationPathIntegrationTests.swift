//
//  NavigationPathIntegrationTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 1/12/25.
//

@testable import SwiftUIFlow
import XCTest

/// Integration tests for navigationPath(for:) functionality
/// Tests path building during deeplink scenarios
final class NavigationPathIntegrationTests: XCTestCase {
    // MARK: - Test: Basic Path Building

    func test_navigationPath_BuildsSequentialStack() {
        // Given: Coordinator with path definition
        let coordinator = PathTestCoordinator()

        // When: Navigate to final destination (deeplink scenario - stack is empty)
        let success = coordinator.navigate(to: PathRoute.finalDestination)

        // Then: Path should be built sequentially
        XCTAssertTrue(success, "Navigation should succeed")
        XCTAssertEqual(coordinator.router.state.stack.count, 3, "Should have 3 routes in stack")
        XCTAssertEqual(coordinator.router.state.stack[0].identifier, "step1")
        XCTAssertEqual(coordinator.router.state.stack[1].identifier, "step2")
        XCTAssertEqual(coordinator.router.state.stack[2].identifier, "finalDestination")
        XCTAssertEqual(coordinator.router.state.currentRoute.identifier, "finalDestination")
    }

    // MARK: - Test: Path Building Only When Stack Empty

    func test_navigationPath_OnlyBuildsWhenStackEmpty() {
        // Given: Coordinator with existing navigation
        let coordinator = PathTestCoordinator()
        coordinator.navigate(to: PathRoute.step1)

        XCTAssertEqual(coordinator.router.state.stack.count, 1, "Should have 1 route in stack")

        // When: Navigate to final destination (stack NOT empty - manual navigation)
        let success = coordinator.navigate(to: PathRoute.finalDestination)

        // Then: Should navigate directly WITHOUT building path
        XCTAssertTrue(success, "Navigation should succeed")
        XCTAssertEqual(coordinator.router.state.stack.count, 2, "Should have 2 routes (step1 + finalDestination)")
        XCTAssertEqual(coordinator.router.state.stack[0].identifier, "step1")
        XCTAssertEqual(coordinator.router.state.stack[1].identifier, "finalDestination")
    }

    // MARK: - Test: Path with Single Intermediate Step

    func test_navigationPath_WithSingleIntermediateStep() {
        // Given: Coordinator that defines path for step2
        let coordinator = PathTestCoordinator()

        // When: Navigate to step2 (requires step1 first)
        let success = coordinator.navigate(to: PathRoute.step2)

        // Then: Should build path: step1 → step2
        XCTAssertTrue(success, "Navigation should succeed")
        XCTAssertEqual(coordinator.router.state.stack.count, 2, "Should have 2 routes in stack")
        XCTAssertEqual(coordinator.router.state.stack[0].identifier, "step1")
        XCTAssertEqual(coordinator.router.state.stack[1].identifier, "step2")
    }

    // MARK: - Test: Route Without Path

    func test_navigationPath_RouteWithoutPath_NavigatesDirectly() {
        // Given: Coordinator with route that has no path defined
        let coordinator = PathTestCoordinator()

        // When: Navigate to step1 (no path defined)
        let success = coordinator.navigate(to: PathRoute.step1)

        // Then: Should navigate directly (no path building)
        XCTAssertTrue(success, "Navigation should succeed")
        XCTAssertEqual(coordinator.router.state.stack.count, 1, "Should have 1 route in stack")
        XCTAssertEqual(coordinator.router.state.currentRoute.identifier, "step1")
    }

    // MARK: - Test: Cross-Coordinator Path Building

    func test_navigationPath_CrossCoordinatorDeeplink() {
        // Given: Main coordinator with child that has path definition
        let mainRouter = Router<MainPathRoute>(initial: .home, factory: DummyPathFactory())
        let mainCoordinator = MainPathCoordinator(router: mainRouter)

        // When: Deeplink to child's final destination
        let success = mainCoordinator.navigate(to: PathRoute.finalDestination)

        // Then: Should switch to child coordinator and build path
        XCTAssertTrue(success, "Navigation should succeed")

        guard let childCoordinator = mainCoordinator.children.first(where: { $0 is PathTestCoordinator }) as? PathTestCoordinator else {
            XCTFail("Expected PathTestCoordinator as child")
            return
        }

        // Verify child coordinator built the path
        XCTAssertEqual(childCoordinator.router.state.stack.count, 3, "Child should have built 3-step path")
        XCTAssertEqual(childCoordinator.router.state.currentRoute.identifier, "finalDestination")
    }

    // MARK: - Test: Path Building After Pop

    func test_navigationPath_AfterPopToRoot_RebuildsPath() {
        // Given: Coordinator with built path
        let coordinator = PathTestCoordinator()
        coordinator.navigate(to: PathRoute.finalDestination)

        XCTAssertEqual(coordinator.router.state.stack.count, 3, "Should have 3-step path")

        // When: Pop to root, then navigate again
        coordinator.popToRoot()
        XCTAssertTrue(coordinator.router.state.stack.isEmpty, "Stack should be empty after pop to root")

        let success = coordinator.navigate(to: PathRoute.finalDestination)

        // Then: Should rebuild path again (stack was empty)
        XCTAssertTrue(success, "Navigation should succeed")
        XCTAssertEqual(coordinator.router.state.stack.count, 3, "Should rebuild 3-step path")
    }

    // MARK: - Test: Empty Path Array

    func test_navigationPath_EmptyPathArray_NavigatesDirectly() {
        // Given: Coordinator that returns empty array for a route
        let coordinator = EmptyPathCoordinator()

        // When: Navigate to route with empty path
        let success = coordinator.navigate(to: EmptyPathRoute.destination)

        // Then: Should navigate directly (empty path = no path building)
        XCTAssertTrue(success, "Navigation should succeed")
        XCTAssertEqual(coordinator.router.state.stack.count, 1, "Should have 1 route")
        XCTAssertEqual(coordinator.router.state.currentRoute.identifier, "destination")
    }

    // MARK: - Test: Nil Path

    func test_navigationPath_NilPath_NavigatesDirectly() {
        // Given: Coordinator that returns nil for a route
        let coordinator = PathTestCoordinator()

        // When: Navigate to route with nil path
        let success = coordinator.navigate(to: PathRoute.noPath)

        // Then: Should navigate directly
        XCTAssertTrue(success, "Navigation should succeed")
        XCTAssertEqual(coordinator.router.state.stack.count, 1, "Should have 1 route")
        XCTAssertEqual(coordinator.router.state.currentRoute.identifier, "noPath")
    }

    // MARK: - Test: Path Building Performance

    func test_navigationPath_LongPath_BuildsEfficiently() {
        // Given: Coordinator with long path (10 steps)
        let coordinator = LongPathCoordinator()

        // When: Navigate to final destination
        let start = Date()
        let success = coordinator.navigate(to: LongPathRoute.final)
        let duration = Date().timeIntervalSince(start)

        // Then: Should build entire path efficiently
        XCTAssertTrue(success, "Navigation should succeed")
        XCTAssertEqual(coordinator.router.state.stack.count, 10, "Should have 10-step path")
        XCTAssertLessThan(duration, 0.1, "Path building should be fast (< 100ms)")
    }
}
