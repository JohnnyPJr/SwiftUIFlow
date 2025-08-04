//
//  CoordinatorTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 1/8/25.
//

import XCTest
@testable import SwifUIFlowJP

final class CoordinatorTests: XCTestCase {

    // MARK: - Initialization
    
    func test_CoordinatorStartsWithRouter() {
        let router = Router<MockRoute>(initial: .home)
        let coordinator = Coordinator(router: router)

        XCTAssertTrue(coordinator.router === router)
        XCTAssertTrue(coordinator.children.isEmpty)
    }

    // MARK: - Child Management
    
    func test_CanAddAndRemoveChildCoordinator() {
        let parent = Coordinator(router: Router<MockRoute>(initial: .home))
        let child = Coordinator(router: Router<MockRoute>(initial: .home))

        parent.addChild(child)
        XCTAssertTrue(parent.children.contains(where: { $0 === child }))

        parent.removeChild(child)
        XCTAssertFalse(parent.children.contains(where: { $0 === child }))
    }

    // MARK: - Route Handling
    
    func test_SubclassCanOverrideHandleRoute() {
        let router = Router<MockRoute>(initial: .home)
        let coordinator = TestCoordinator(router: router)

        let handled = coordinator.handle(route: .details)

        XCTAssertTrue(handled)
        XCTAssertTrue(coordinator.didHandleRoute)
    }
    
    func test_NavigateDelegatesToHandleRouteOrChildren() {
        let router = Router<MockRoute>(initial: .home)
        class NonHandlingCoordinator: Coordinator<MockRoute> {}
        let parent = NonHandlingCoordinator(router: router)
        let child = TestCoordinator(router: router)
        parent.addChild(child)

        let handled = parent.navigate(to: MockRoute.details)

        XCTAssertTrue(handled)
        XCTAssertTrue(child.didHandleRoute)
    }
    
    func test_NavigateHandlesRouteInCurrentCoordinator() {
        let router = Router<MockRoute>(initial: .home)
        let coordinator = TestCoordinator(router: router)

        let handled = coordinator.navigate(to: .details)

        XCTAssertTrue(handled)
        XCTAssertTrue(coordinator.didHandleRoute)
    }

    func test_ChildCoordinatorBubblesUpNavigationToParent() {
        let router = Router<MockRoute>(initial: .home)
        let parent = TestCoordinator(router: router)
        let child = Coordinator(router: router)
        parent.addChild(child)

        let handled = child.navigate(to: .details)

        XCTAssertTrue(handled)
        XCTAssertTrue(parent.didHandleRoute)
    }
    
    // MARK: - Modal Handling
    
    func test_CanPresentAndDismissModalCoordinator() {
        let router = Router<MockRoute>(initial: .home)
        let parent = Coordinator(router: router)
        let modal = Coordinator(router: router)

        parent.presentModal(modal)
        XCTAssertTrue(parent.modalCoordinator === modal)

        parent.dismissModal()
        XCTAssertNil(parent.modalCoordinator)
    }
    
    // MARK: - Deeplink Handling
    
    func test_CoordinatorCanHandleDeeplinkDirectly() {
        let coordinator = TestCoordinator(router: Router<MockRoute>(initial: .home))

        coordinator.handleDeeplink(.details)

        XCTAssertTrue(coordinator.didHandleRoute)
    }

    func test_CoordinatorDelegatesDeeplinkToChildren() {
        final class ParentCoordinator: Coordinator<MockRoute> {}
        let parent = ParentCoordinator(router: Router<MockRoute>(initial: .home))
        let child = TestCoordinator(router: Router<MockRoute>(initial: .home))
        parent.addChild(child)

        parent.handleDeeplink(.details)

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
}
