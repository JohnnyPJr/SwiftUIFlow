//
//  CoordinatorTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 1/8/25.
//

@testable import SwiftUIFlow
import XCTest

struct SUT {
    let router: Router<MockRoute>
    let coordinator: TestCoordinator
    let childCoordinator: TestCoordinator?
}

final class CoordinatorTests: XCTestCase {
    // MARK: - Initialization

    func test_CoordinatorStartsWithRouter() {
        let sut = makeSUT()

        XCTAssertTrue(sut.coordinator.router === sut.router)
        XCTAssertTrue(sut.coordinator.children.isEmpty)
    }

    // MARK: - Child Management

    func test_CanAddAndRemoveChildCoordinator() {
        let sut = makeSUT(addChild: true)

        guard let child = sut.childCoordinator else {
            XCTFail("Expected child coordinator to be created")
            return
        }

        XCTAssertTrue(sut.coordinator.children.contains(where: { $0 === child }))
        XCTAssertTrue(child.parent === sut.coordinator)

        sut.coordinator.removeChild(child)
        XCTAssertFalse(sut.coordinator.children.contains(where: { $0 === child }))
        XCTAssertNil((child as Coordinator<MockRoute>).parent, "Expected parent to be nil after removal")
    }

    // MARK: - Route Handling

    func test_CanHandleOnlyReturnsTrueForDirectHandling() {
        let sut = makeSUT()

        // TestCoordinator handles .details directly
        XCTAssertTrue(sut.coordinator.canHandle(MockRoute.details))

        // Should NOT handle routes it doesn't directly handle
        XCTAssertFalse(sut.coordinator.canHandle(MockRoute.home))
        XCTAssertFalse(sut.coordinator.canHandle(MockRoute.login))
    }

    func test_NavigateExecutesRouterActionsWhenHandled() {
        let sut = makeSUT()

        // Navigate should trigger router.push when canHandle returns true
        let handled = sut.coordinator.navigate(to: MockRoute.details)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.router.state.currentRoute, MockRoute.details, "Expected to be at details route")
    }

    func test_NavigateDelegatesToChildren() {
        let coordinator = TestCoordinatorWithChild()

        let handled = coordinator.navigate(to: MockRoute.details)

        XCTAssertTrue(handled)
        XCTAssertEqual(coordinator.child.router.state.currentRoute,
                       MockRoute.details, "Child should be at details route")
    }

    func test_ChildCoordinatorBubblesUpNavigationToParent() {
        let coordinator = TestCoordinatorWithChildThatCantHandleNavigation()

        let handled = coordinator.child.navigate(to: MockRoute.details)

        XCTAssertTrue(handled)
        XCTAssertEqual(coordinator.router.state.currentRoute, MockRoute.details, "Parent should be at details route")
    }

    // MARK: - Modal Handling

    func test_CanPresentAndDismissModalCoordinator() {
        let sut = makeSUT()
        let modal = Coordinator(router: sut.router)

        sut.coordinator.presentModal(modal, presenting: .home)
        XCTAssertTrue(sut.coordinator.modalCoordinator === modal)

        sut.coordinator.dismissModal()
        XCTAssertNil(sut.coordinator.modalCoordinator)
    }

    func test_NavigateDismissesModalWhenModalCantHandle() {
        let sut = makeSUT()
        let modalRouter = Router<MockRoute>(initial: .modal, factory: MockViewFactory())
        let modal = TestModalThatCantHandle(router: modalRouter)

        // Present modal (handles both coordinator and router state)
        sut.coordinator.presentModal(modal, presenting: .modal)
        XCTAssertNotNil(sut.coordinator.modalCoordinator)
        XCTAssertNotNil(sut.router.state.presented)

        // Navigate to route that modal can't handle
        let handled = sut.coordinator.navigate(to: MockRoute.details)

        XCTAssertTrue(handled)
        XCTAssertNil(sut.coordinator.modalCoordinator, "Modal should be dismissed")
        XCTAssertNil(sut.router.state.presented, "Router should have dismissed modal")
        XCTAssertEqual(sut.router.state.currentRoute,
                       MockRoute.details, "Expected to be at details route after dismissing modal")
    }

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
        child.presentModal(modal, presenting: .modal)

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
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let modalCoordinator = TestModalCoordinator(router: router)

        _ = modalCoordinator.navigate(to: MockRoute.details)

        XCTAssertEqual(router.state.presented, MockRoute.details, "Modal coordinator should present route")
        XCTAssertTrue(router.state.stack.isEmpty, "Modal coordinator should not push to stack")
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

    // MARK: - Tab Coordinator Tests

    func test_TabCoordinatorCanIdentifyTabForChild() {
        let tabRouter = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let tabCoordinator = TestTabCoordinator(router: tabRouter)

        let tab1Child = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))
        let tab2Child = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))

        tabCoordinator.addChild(tab1Child)
        tabCoordinator.addChild(tab2Child)

        XCTAssertEqual(tabCoordinator.getTabIndex(for: tab1Child), 0, "First child should be tab index 0")
        XCTAssertEqual(tabCoordinator.getTabIndex(for: tab2Child), 1, "Second child should be tab index 1")
    }

    func test_TabCoordinatorCanSwitchTabs() {
        let tabRouter = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let tabCoordinator = TestTabCoordinator(router: tabRouter)

        tabCoordinator.switchToTab(2)

        XCTAssertEqual(tabRouter.state.selectedTab, 2, "Tab coordinator should switch tabs using router")
    }

    // MARK: - Reset State

    func test_ResetToCleanStateExists() {
        let sut = makeSUT()

        sut.router.push(.details)
        sut.router.present(.modal)

        sut.coordinator.resetToCleanState()

        XCTAssertTrue(sut.router.state.stack.isEmpty, "Stack should be empty after reset")
        XCTAssertNil(sut.router.state.presented, "Modal should be dismissed after reset")
    }

    // MARK: - Detour Tests

    func test_PresentAndDismissDetour() {
        let sut = makeSUT()
        let detourRouter = Router<MockRoute>(initial: .details, factory: MockViewFactory())
        let detourCoordinator = TestCoordinator(router: detourRouter)

        sut.coordinator.presentDetour(detourCoordinator, presenting: MockRoute.details)

        XCTAssertTrue(sut.coordinator.detourCoordinator === detourCoordinator, "Detour coordinator should be presented")
        XCTAssertTrue(detourCoordinator.parent === sut.coordinator, "Parent should be set")
        XCTAssertEqual(sut.router.state.detour?.identifier, MockRoute.details.identifier,
                       "Detour route should be in state")

        sut.coordinator.dismissDetour()

        XCTAssertNil(sut.coordinator.detourCoordinator, "Detour coordinator should be dismissed")
        XCTAssertNil(detourCoordinator.parent, "Parent should be cleared")
        XCTAssertNil(sut.router.state.detour, "Detour route should be cleared from state")
    }

    func test_ResetToCleanStateDismissesDetour() {
        let sut = makeSUT()
        let detourRouter = Router<MockRoute>(initial: .details, factory: MockViewFactory())
        let detourCoordinator = TestCoordinator(router: detourRouter)

        sut.router.push(.details)
        sut.router.present(.modal)
        sut.coordinator.presentDetour(detourCoordinator, presenting: MockRoute.login)

        sut.coordinator.resetToCleanState()

        XCTAssertTrue(sut.router.state.stack.isEmpty, "Stack should be empty after reset")
        XCTAssertNil(sut.router.state.presented, "Modal should be dismissed after reset")
        XCTAssertNil(sut.router.state.detour, "Detour should be dismissed after reset")
        XCTAssertNil(sut.coordinator.detourCoordinator, "Detour coordinator should be dismissed after reset")
    }

    // MARK: Helpers

    private func makeSUT(router: Router<MockRoute>? = nil, addChild: Bool = false) -> SUT {
        let resolvedRouter = router ?? Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let coordinator = TestCoordinator(router: resolvedRouter)

        var child: TestCoordinator?
        if addChild {
            child = TestCoordinator(router: resolvedRouter)
            coordinator.addChild(child!)
        }

        return SUT(router: resolvedRouter,
                   coordinator: coordinator,
                   childCoordinator: child)
    }
}

// MARK: - Test Helpers

class TestModalThatCantHandle: Coordinator<MockRoute> {
    override func navigationType(for route: any Route) -> NavigationType {
        return .modal
    }

    override func canHandle(_ route: any Route) -> Bool {
        // This modal can't handle any routes
        return false
    }
}

class TestCoordinatorThatCleansOnBubble: TestCoordinator {
    override func canHandle(_ route: any Route) -> Bool {
        // This coordinator can't handle any routes - will always bubble to parent
        return false
    }

    override func shouldCleanStateForBubbling(route: any Route) -> Bool {
        return true // Always clean when bubbling
    }
}
