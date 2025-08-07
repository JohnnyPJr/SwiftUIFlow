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
        XCTAssertTrue((sut.coordinator as? TestCoordinator)?.didHandleRoute ?? false)
    }

    func test_NavigateDelegatesToHandleRouteOrChildren() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        class NonHandlingCoordinator: Coordinator<MockRoute> {}
        let sut = makeSUT(router: router,
                          coordinator: NonHandlingCoordinator(router: router),
                          addChild: true)

        guard let child = sut.childCoordinator as? TestCoordinator else {
            XCTFail("Expected child coordinator to be created")
            return
        }

        let handled = sut.coordinator.navigate(to: MockRoute.details)

        XCTAssertTrue(handled)
        XCTAssertTrue(child.didHandleRoute)
    }

    func test_NavigateHandlesRouteInCurrentCoordinator() {
        let sut = makeSUT()

        let handled = sut.coordinator.navigate(to: .details)

        XCTAssertTrue(handled)
        XCTAssertTrue((sut.coordinator as? TestCoordinator)?.didHandleRoute ?? false)
    }

    func test_ChildCoordinatorBubblesUpNavigationToParent() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let child = Coordinator(router: router)
        let sut = makeSUT(router: router,
                          addChild: true,
                          childCoordinator: child)

        guard let parent = sut.coordinator as? TestCoordinator else {
            XCTFail("Expected parent coordinator to be created")
            return
        }

        let handled = child.navigate(to: .details)

        XCTAssertTrue(handled)
        XCTAssertTrue(parent.didHandleRoute)
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
        guard let parent = sut.coordinator as? TestCoordinator else {
            XCTFail("Expected coordinator to be TestCoordinator")
            return
        }

        parent.handleDeeplink(.details)

        XCTAssertTrue(parent.didHandleRoute)
    }

    func test_CoordinatorDelegatesDeeplinkToChildren() {
        final class ParentCoordinator: Coordinator<MockRoute> {}
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())

        let sut = makeSUT(router: router,
                          coordinator: ParentCoordinator(router: router),
                          addChild: true)

        guard let child = sut.childCoordinator as? TestCoordinator else {
            XCTFail("Expected child coordinator to be created")
            return
        }

        sut.coordinator.handleDeeplink(.details)

        XCTAssertTrue(child.didHandleRoute)
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
                         coordinator: Coordinator<MockRoute>? = nil,
                         addChild: Bool = false,
                         childCoordinator: Coordinator<MockRoute>? = nil) -> (router: Router<MockRoute>,
                                                                              coordinator: Coordinator<MockRoute>,
                                                                              childCoordinator: Coordinator<MockRoute>?)
    {
        let resolvedRouter = router ?? Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let resolvedCoordinator = coordinator ?? TestCoordinator(router: resolvedRouter)

        var child = childCoordinator
        if addChild, child == nil {
            child = TestCoordinator(router: resolvedRouter)
        }

        if let child {
            resolvedCoordinator.addChild(child)
        }

        return (resolvedRouter, resolvedCoordinator, child)
    }
}
