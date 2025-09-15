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

    func test_SubclassCanOverrideHandleRoute() {
        let sut = makeSUT()

        let handled = sut.coordinator.canHandle(MockRoute.details)

        XCTAssertTrue(handled)
        XCTAssertTrue(sut.coordinator.didHandleRoute)
    }

    func test_NavigateDelegatesToHandleRouteOrChildren() {
        let coordinator = TestCoordinatorWithChild()

        let handled = coordinator.navigate(to: MockRoute.details)

        XCTAssertTrue(handled)
        XCTAssertTrue(coordinator.child.didHandleRoute)
    }

    func test_NavigateHandlesRouteInCurrentCoordinator() {
        let sut = makeSUT()

        let handled = sut.coordinator.navigate(to: MockRoute.details)

        XCTAssertTrue(handled)
        XCTAssertTrue(sut.coordinator.didHandleRoute)
    }

    func test_ChildCoordinatorBubblesUpNavigationToParent() {
        let coordinator = TestCoordinatorWithChildThatCantHandleNavigation()

        let handled = coordinator.child.navigate(to: MockRoute.details)

        XCTAssertTrue(handled)
        XCTAssertTrue(coordinator.didHandleRoute)
    }

    // MARK: - Modal Handling

    func test_CanPresentAndDismissModalCoordinator() {
        let sut = makeSUT()
        let modal = Coordinator(router: sut.router)

        sut.coordinator.presentModal(modal)
        XCTAssertTrue(sut.coordinator.modalCoordinator === modal)

        sut.coordinator.dismissModal()
        XCTAssertNil(sut.coordinator.modalCoordinator)
    }

    // MARK: - Deeplink Handling

    func test_CoordinatorCanHandleDeeplinkDirectly() {
        let sut = makeSUT()

        sut.coordinator.handleDeeplink(MockRoute.details)

        XCTAssertTrue(sut.coordinator.didHandleRoute)
    }

    func test_ParentDelegatesRouteHandlingToChild() {
        let parentWithChild = TestCoordinatorWithChild()

        let handled = parentWithChild.navigate(to: MockRoute.details)

        XCTAssertTrue(handled)
        XCTAssertTrue(parentWithChild.child.didHandleRoute)
        XCTAssertEqual(parentWithChild.child.lastHandledRoute, MockRoute.details)
    }

    func test_ParentDelegatesDeeplinkHandlingToChild() {
        let parentWithChild = TestCoordinatorWithChild()

        parentWithChild.handleDeeplink(MockRoute.details)

        XCTAssertTrue(parentWithChild.child.didHandleRoute)
        XCTAssertEqual(parentWithChild.child.lastHandledRoute, MockRoute.details)
    }

    func test_NavigateWithFlowExistsAndDelegates() {
        let sut = makeSUT()

        let handled = sut.coordinator.navigateWithFlow(to: MockRoute.details)

        XCTAssertTrue(handled, "Expected navigateWithFlow to handle the route")
        XCTAssertTrue(sut.coordinator.didHandleRoute, "Expected coordinator to have handled the route")
        XCTAssertEqual(sut.coordinator.lastHandledRoute, MockRoute.details, "Expected correct route to be handled")
    }

    func test_ResetToCleanStateExists() {
        let sut = makeSUT()

        sut.router.push(.details)
        sut.router.present(.modal)

        sut.coordinator.resetToCleanState()

        XCTAssertTrue(true, "resetToCleanState should exist and be callable")
    }

    func test_CoordinatorHasNavigationType() {
        let sut = makeSUT()

        let navigationType = sut.coordinator.navigationType

        XCTAssertEqual(navigationType, .push, "Default navigation type should be push")
    }

    func test_CoordinatorCanOverrideNavigationType() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let modalCoordinator = TestModalCoordinator(router: router)

        XCTAssertEqual(modalCoordinator.navigationType, .modal, "Modal coordinator should have modal navigation type")
    }

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
