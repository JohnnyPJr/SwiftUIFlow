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
@MainActor
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

        guard let childCoordinator = mainCoordinator.children
            .first(where: { $0 is PathTestCoordinator }) as? PathTestCoordinator
        else {
            XCTFail("Expected PathTestCoordinator as child")
            return
        }

        // Verify child coordinator built the path
        XCTAssertEqual(childCoordinator.router.state.stack.count, 3, "Child should have built 3-step path")
        XCTAssertEqual(childCoordinator.router.state.currentRoute.identifier, "finalDestination")
    }

    func test_navigationPath_BuildsParentPathBeforeDelegatingToPushedChild() {
        let grandchild = DescendantPathGrandchildCoordinator()
        let parent = DescendantPathParentCoordinator(grandchild: grandchild)

        let success = parent.navigate(to: DescendantPathGrandchildRoute.destination)

        XCTAssertTrue(success)
        XCTAssertEqual(parent.router.state.stack, [.context])
        XCTAssertTrue(parent.router.state.pushedChildren.first === grandchild)
        XCTAssertEqual(grandchild.router.state.currentRoute, .destination)
    }

    func test_navigationPath_ModalParentPathToPushedChild_FailsWithoutPushingChild() {
        let grandchild = DescendantPathGrandchildCoordinator()
        let parent = MalformedDescendantPathParentCoordinator(grandchild: grandchild,
                                                              pathKind: .modalRoute)
        let before = parent.router.state

        let success = parent.navigate(to: DescendantPathGrandchildRoute.destination)

        XCTAssertFalse(success)
        XCTAssertEqual(parent.router.state, before)
        XCTAssertTrue(parent.router.state.pushedChildren.isEmpty)
        XCTAssertEqual(grandchild.router.state.currentRoute, .root)
    }

    func test_navigationPath_ForeignParentPathToPushedChild_FailsWithoutPushingChild() {
        let grandchild = DescendantPathGrandchildCoordinator()
        let parent = MalformedDescendantPathParentCoordinator(grandchild: grandchild,
                                                              pathKind: .foreignRoute)
        let before = parent.router.state

        let success = parent.navigate(to: DescendantPathGrandchildRoute.destination)

        XCTAssertFalse(success)
        XCTAssertEqual(parent.router.state, before)
        XCTAssertTrue(parent.router.state.pushedChildren.isEmpty)
        XCTAssertEqual(grandchild.router.state.currentRoute, .root)
    }

    func test_navigationPath_ForeignChildPathDuringDelegation_FailsWithoutPushingChild() {
        let child = MalformedPathCoordinator(pathKind: .foreignRoute)
        let parent = DelegatingPathParentCoordinator(child: child)
        let before = parent.router.state

        let success = parent.navigate(to: MalformedPathRoute.destination)

        XCTAssertFalse(success)
        XCTAssertEqual(parent.router.state, before)
        XCTAssertTrue(parent.router.state.pushedChildren.isEmpty)
        XCTAssertEqual(child.router.state.currentRoute, .root)
    }

    func test_navigationPath_ModalChildPathDuringDelegation_FailsWithoutPushingChild() {
        let child = MalformedPathCoordinator(pathKind: .modalRoute)
        let parent = DelegatingPathParentCoordinator(child: child)
        let before = parent.router.state

        let success = parent.navigate(to: MalformedPathRoute.destination)

        XCTAssertFalse(success)
        XCTAssertEqual(parent.router.state, before)
        XCTAssertTrue(parent.router.state.pushedChildren.isEmpty)
        XCTAssertEqual(child.router.state.currentRoute, .root)
    }

    func test_navigationPath_DelegatedChildFailure_ReturnsFalseAndRollsBackPushedChild() {
        let child = FailingDelegatedNavigationCoordinator()
        let parent = DelegatingPathParentCoordinator(child: child)
        let before = parent.router.state

        let success = parent.navigate(to: MalformedPathRoute.destination)

        XCTAssertFalse(success)
        XCTAssertEqual(parent.router.state, before)
        XCTAssertTrue(parent.router.state.pushedChildren.isEmpty)
        XCTAssertTrue(child.parent === parent)
        XCTAssertEqual(child.presentationContext, .pushed)
    }

    func test_navigationPath_ForeignModalChildPathDuringDelegation_FailsWithoutPresentingModal() {
        let modal = MalformedPathCoordinator(pathKind: .foreignRoute)
        let parent = ModalDelegatingPathParentCoordinator(modal: modal)
        let before = parent.router.state

        let success = parent.navigate(to: MalformedPathRoute.destination)

        XCTAssertFalse(success)
        XCTAssertEqual(parent.router.state, before)
        XCTAssertNil(parent.currentModalCoordinator)
        XCTAssertNil(parent.router.state.presented)
        XCTAssertEqual(modal.router.state.currentRoute, .root)
    }

    func test_navigationPath_ModalModalChildPathDuringDelegation_FailsWithoutPresentingModal() {
        let modal = MalformedPathCoordinator(pathKind: .modalRoute)
        let parent = ModalDelegatingPathParentCoordinator(modal: modal)
        let before = parent.router.state

        let success = parent.navigate(to: MalformedPathRoute.destination)

        XCTAssertFalse(success)
        XCTAssertEqual(parent.router.state, before)
        XCTAssertNil(parent.currentModalCoordinator)
        XCTAssertNil(parent.router.state.presented)
        XCTAssertEqual(modal.router.state.currentRoute, .root)
    }

    func test_navigationPath_DelegatedModalFailure_ReturnsFalseAndDismissesPresentedModal() {
        let modal = FailingDelegatedNavigationCoordinator()
        let parent = ModalDelegatingPathParentCoordinator(modal: modal)
        let before = parent.router.state

        let success = parent.navigate(to: MalformedPathRoute.destination)

        XCTAssertFalse(success)
        XCTAssertEqual(parent.router.state, before)
        XCTAssertNil(parent.currentModalCoordinator)
        XCTAssertNil(parent.router.state.presented)
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

    // MARK: - Test: Malformed Path Atomicity

    func test_navigationPath_ForeignRouteInPath_FailsWithoutMutatingState() {
        let coordinator = MalformedPathCoordinator(pathKind: .foreignRoute)
        let before = coordinator.router.state

        let success = coordinator.navigate(to: MalformedPathRoute.destination)

        XCTAssertFalse(success, "A path containing a foreign route type must fail")
        XCTAssertEqual(coordinator.router.state, before, "Failed navigation must be atomic")
    }

    func test_navigationPath_ModalRouteInPath_FailsWithoutMutatingState() {
        let coordinator = MalformedPathCoordinator(pathKind: .modalRoute)
        let before = coordinator.router.state

        let success = coordinator.navigate(to: MalformedPathRoute.destination)

        XCTAssertFalse(success, "A navigation path cannot contain a modal route")
        XCTAssertEqual(coordinator.router.state, before, "Failed navigation must be atomic")
        XCTAssertNil(coordinator.currentModalCoordinator)
    }

    // MARK: - Test: Valid Path Execution Branches

    func test_navigationPath_ValidPathIncludingDestination_BuildsPathWithoutDuplicatePush() {
        let coordinator = MalformedPathCoordinator(pathKind: .validPathIncludingDestination)

        let success = coordinator.navigate(to: MalformedPathRoute.destination)

        XCTAssertTrue(success)
        XCTAssertEqual(coordinator.router.state.stack, [.prerequisite, .destination])
        XCTAssertEqual(coordinator.router.state.currentRoute, .destination)
    }

    func test_navigationPath_ValidPathExcludingDestination_BuildsPathThenExecutesDestination() {
        let coordinator = MalformedPathCoordinator(pathKind: .validPathExcludingDestination)

        let success = coordinator.navigate(to: MalformedPathRoute.destination)

        XCTAssertTrue(success)
        XCTAssertEqual(coordinator.router.state.stack, [.prerequisite, .destination])
        XCTAssertEqual(coordinator.router.state.currentRoute, .destination)
    }

    func test_navigationPath_RootInPath_IsSkippedWithoutRejectingThePath() {
        let coordinator = MalformedPathCoordinator(pathKind: .validPathStartingWithRoot)

        let success = coordinator.navigate(to: MalformedPathRoute.destination)

        XCTAssertTrue(success)
        XCTAssertEqual(coordinator.router.state.stack, [.prerequisite, .destination])
        XCTAssertEqual(coordinator.router.state.currentRoute, .destination)
    }

    func test_navigationPath_SameTypeIdentifierCollision_DoesNotCountAsDestinationInPath() {
        let coordinator = MalformedPathCoordinator(pathKind: .sameIdentifierAsDestination)

        let success = coordinator.navigate(to: MalformedPathRoute.destination)

        XCTAssertTrue(success)
        XCTAssertEqual(coordinator.router.state.stack, [.alias, .destination])
        XCTAssertEqual(coordinator.router.state.currentRoute, .destination)
    }
}
