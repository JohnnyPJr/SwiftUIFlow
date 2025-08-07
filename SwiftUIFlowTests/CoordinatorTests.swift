//
//  CoordinatorTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 1/8/25.
//

@testable import SwiftUIFlow
import XCTest

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

        sut.coordinator.removeChild(child)
        XCTAssertFalse(sut.coordinator.children.contains(where: { $0 === child }))
    }

    // MARK: - Route Handling

    func test_SubclassCanOverrideHandleRoute() {
        let sut = makeSUT()

        let handled = sut.coordinator.handle(route: .details)

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

        let handled = sut.coordinator.navigate(to: .details)

        XCTAssertTrue(handled)
        XCTAssertTrue(sut.coordinator.didHandleRoute)
    }

    func test_ChildCoordinatorBubblesUpNavigationToParent() {
        let coordinator = TestCoordinatorWithChildThatCantHandleNavigation()

        let handled = coordinator.child.navigate(to: .details)

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

        sut.coordinator.handleDeeplink(.details)

        XCTAssertTrue(sut.coordinator.didHandleRoute)
    }

    func test_ParentDelegatesRouteHandlingToChild() {
        let parentWithChild = TestCoordinatorWithChild()

        let handled = parentWithChild.navigate(to: .details)

        XCTAssertTrue(handled)
        XCTAssertTrue(parentWithChild.child.didHandleRoute)
        XCTAssertEqual(parentWithChild.child.lastHandledRoute, .details)
    }

    func test_ParentDelegatesDeeplinkHandlingToChild() {
        let parentWithChild = TestCoordinatorWithChild()

        parentWithChild.handleDeeplink(.details)

        XCTAssertTrue(parentWithChild.child.didHandleRoute)
        XCTAssertEqual(parentWithChild.child.lastHandledRoute, .details)
    }

    // MARK: Helpers

    private func makeSUT(router: Router<MockRoute>? = nil,
                         addChild: Bool = false) -> (router: Router<MockRoute>, coordinator: TestCoordinator, childCoordinator: TestCoordinator?)
    {
        let resolvedRouter = router ?? Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let coordinator = TestCoordinator(router: resolvedRouter)

        var child: TestCoordinator?
        if addChild {
            child = TestCoordinator(router: resolvedRouter)
            coordinator.addChild(child!)
        }

        return (resolvedRouter, coordinator, child)
    }
}
