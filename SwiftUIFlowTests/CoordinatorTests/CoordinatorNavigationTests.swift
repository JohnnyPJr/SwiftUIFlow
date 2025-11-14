//
//  CoordinatorNavigationTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 5/11/25.
//

@testable import SwiftUIFlow
import XCTest

final class CoordinatorNavigationTests: XCTestCase {
    // MARK: - State Cleanup

    func test_CoordinatorCleansStateWhenBubblingUp() {
        let parentRouter = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let parent = TestCoordinator(router: parentRouter)

        let childRouter = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let child = TestCoordinatorThatCleansOnBubble(router: childRouter)

        parent.addChild(child)

        // Setup child state
        childRouter.push(.login)

        // Present modal properly using presentModal (not direct router access)
        let modalRouter = Router<MockRoute>(initial: .modal, factory: MockViewFactory())
        let modal = Coordinator(router: modalRouter)
        child.presentModal(modal, presenting: .modal, detentConfiguration: ModalDetentConfiguration(detents: [.large]))

        // Navigate to route child can't handle - should clean and bubble
        let handled = child.navigate(to: MockRoute.details)

        XCTAssertTrue(handled)
        XCTAssertTrue(childRouter.state.stack.isEmpty, "Child should clean stack when bubbling")
        XCTAssertNil(childRouter.state.presented, "Child should dismiss modal when bubbling")
        XCTAssertEqual(parentRouter.state.currentRoute, MockRoute.details, "Parent should be at details route")
    }

    // MARK: - NavigationType

    func test_CoordinatorHasNavigationType() {
        let sut = makeSUT()

        let navigationType = sut.coordinator.navigationType(for: MockRoute.details)

        XCTAssertEqual(navigationType, .push, "Default navigation type should be push")
    }

    func test_CoordinatorCanOverrideNavigationType() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let modalCoordinator = TestModalCoordinator(router: router)

        XCTAssertEqual(modalCoordinator.navigationType(for: MockRoute.details), .modal,
                       "Modal coordinator should have modal navigation type")
    }

    func test_NavigateExecutesBasedOnNavigationType() {
        let parentRouter = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let parent = TestModalCoordinator(router: parentRouter)

        // Create a modal navigator that handles .details
        let childRouter = Router<MockRoute>(initial: .details, factory: MockViewFactory())
        let child = TestCoordinator(router: childRouter)
        parent.addModalCoordinator(child)

        // Navigate to .details - should present modal and delegate to child
        _ = parent.navigate(to: MockRoute.details)

        XCTAssertEqual(parentRouter.state.presented, MockRoute.details, "Parent should present route as modal")
        XCTAssertTrue(parent.currentModalCoordinator === child, "Child should be set as modal coordinator")
        XCTAssertTrue(child.parent === parent, "Parent relationship should be set")
    }

    // MARK: - Replace Navigation Tests

    func test_RouterReplaceWhenStackIsEmpty() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())

        // Replace when stack is empty - should just push
        router.replace(.details)

        XCTAssertEqual(router.state.stack.count, 1, "Should have 1 item in stack")
        XCTAssertEqual(router.state.currentRoute, .details, "Should be at details")
    }

    func test_RouterReplaceWhenStackHasItems() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())

        // Build stack: home -> login -> details
        router.push(.login)
        router.push(.details)
        XCTAssertEqual(router.state.stack.count, 2, "Should have 2 items before replace")

        // Replace details with modal
        router.replace(.modal)

        XCTAssertEqual(router.state.stack.count, 2, "Should still have 2 items")
        XCTAssertEqual(router.state.stack.last, .modal, "Last item should be modal")
        XCTAssertEqual(router.state.currentRoute, .modal, "Should be at modal")
        XCTAssertFalse(router.state.stack.contains(.details), "Details should be gone")
    }

    func test_CoordinatorNavigateWithReplaceType() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let coordinator = TestReplaceCoordinator(router: router)

        // Push login first
        router.push(.login)
        XCTAssertEqual(router.state.currentRoute, .login)

        // Navigate to details with replace type - should replace login
        _ = coordinator.navigate(to: MockRoute.details)

        XCTAssertEqual(router.state.currentRoute, .details, "Should be at details")
        XCTAssertEqual(router.state.stack.last, .details, "Details should be top of stack")
        XCTAssertFalse(router.state.stack.contains(.login), "Login should be replaced")
    }

    func test_ReplaceNavigationInMultiStepFlow() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let coordinator = TestReplaceCoordinator(router: router)

        // Simulate multi-step flow: home -> step1 (push) -> step2 (replace) -> step3 (replace)
        router.push(.login) // Step 1
        XCTAssertEqual(router.state.stack, [.login])

        _ = coordinator.navigate(to: MockRoute.details) // Step 2 (replace)
        XCTAssertEqual(router.state.stack, [.details], "Should replace login with details")

        _ = coordinator.navigate(to: MockRoute.modal) // Step 3 (replace)
        XCTAssertEqual(router.state.stack, [.modal], "Should replace details with modal")
        XCTAssertEqual(router.state.currentRoute, .modal, "Should be at modal")
    }

    // MARK: - Flow Change Handling

    func test_HandleFlowChange_IsCalledWhenRouteCannotBeHandledAtRoot() {
        let rootCoordinator = TestCoordinatorWithFlowChange()

        // Navigate to a route that can't be handled
        let handled = rootCoordinator.navigate(to: MockRoute.login)

        XCTAssertTrue(handled, "Navigation should succeed via handleFlowChange")
        XCTAssertTrue(rootCoordinator.flowChangeWasCalled, "handleFlowChange should be called")
        XCTAssertEqual(rootCoordinator.flowChangeRoute?.identifier, MockRoute.login.identifier,
                       "Should receive the correct route")
    }

    func test_HandleFlowChange_IsNotCalledWhenRouteCanBeHandled() {
        let rootCoordinator = TestCoordinatorWithFlowChange()

        // Navigate to a route that CAN be handled
        let handled = rootCoordinator.navigate(to: MockRoute.details)

        XCTAssertTrue(handled, "Navigation should succeed via normal handling")
        XCTAssertFalse(rootCoordinator.flowChangeWasCalled, "handleFlowChange should NOT be called")
    }

    func test_HandleFlowChange_IsNotCalledWhenCoordinatorHasParent() {
        let rootCoordinator = TestCoordinatorWithFlowChange()
        let childCoordinator = TestCoordinatorWithFlowChange()
        rootCoordinator.addChild(childCoordinator)

        // Navigate on child to a route it can't handle - should bubble to parent
        let handled = childCoordinator.navigate(to: MockRoute.login)

        XCTAssertTrue(handled, "Navigation should succeed via parent's handleFlowChange")
        XCTAssertFalse(childCoordinator.flowChangeWasCalled,
                       "Child's handleFlowChange should NOT be called (it has a parent)")
        XCTAssertTrue(rootCoordinator.flowChangeWasCalled,
                      "Root's handleFlowChange should be called")
    }

    func test_UnhandledRoute_StillFailsWhenFlowChangeReturnsFalse() {
        let rootCoordinator = TestCoordinatorWithFlowChange()
        rootCoordinator.shouldHandleFlowChange = false // Return false from handleFlowChange

        // Navigate to a route that can't be handled
        let handled = rootCoordinator.navigate(to: MockRoute.login)

        XCTAssertFalse(handled, "Navigation should fail when handleFlowChange returns false")
        XCTAssertTrue(rootCoordinator.flowChangeWasCalled, "handleFlowChange should still be called")
    }
}
