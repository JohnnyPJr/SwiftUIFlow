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

        // Setup some state to reset
        sut.router.push(.details)
        sut.router.present(.modal)

        // Should not throw or crash
        sut.coordinator.resetToCleanState()

        // For now, just verify the method exists and can be called
        // We'll test the actual behavior in integration tests
        XCTAssertTrue(true, "resetToCleanState should exist and be callable")
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
