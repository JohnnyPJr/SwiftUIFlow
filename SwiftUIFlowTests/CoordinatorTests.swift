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
        XCTAssertEqual(sut.router.state.stack.last, MockRoute.details, "Expected route to be pushed to stack")
    }

    func test_NavigateDelegatesToChildren() {
        let coordinator = TestCoordinatorWithChild()

        let handled = coordinator.navigate(to: MockRoute.details)

        XCTAssertTrue(handled)
        XCTAssertEqual(coordinator.child.router.state.stack.last, MockRoute.details)
    }

    func test_ChildCoordinatorBubblesUpNavigationToParent() {
        let coordinator = TestCoordinatorWithChildThatCantHandleNavigation()

        let handled = coordinator.child.navigate(to: MockRoute.details)

        XCTAssertTrue(handled)
        XCTAssertEqual(coordinator.router.state.stack.last, MockRoute.details)
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
        XCTAssertEqual(sut.router.state.stack.last, MockRoute.details, "Route should be pushed after dismissing modal")
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
        XCTAssertEqual(parentRouter.state.stack.last, MockRoute.details, "Parent should handle route")
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
