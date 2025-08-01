//
//  CoordinatorTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 1/8/25.
//

import XCTest
@testable import SwiftUIFlow

final class CoordinatorTests: XCTestCase {
    
    func testCoordinatorStartsWithRouter() {
        let router = Router<MockRoute>(initial: .home)
        let coordinator = Coordinator(router: router)

        XCTAssertTrue(coordinator.router === router)
        XCTAssertTrue(coordinator.children.isEmpty)
    }

    func testCanAddAndRemoveChildCoordinator() {
        let parent = Coordinator(router: Router<MockRoute>(initial: .home))
        let child = Coordinator(router: Router<MockRoute>(initial: .home))

        parent.addChild(child)
        XCTAssertTrue(parent.children.contains(where: { $0 === child }))

        parent.removeChild(child)
        XCTAssertFalse(parent.children.contains(where: { $0 === child }))
    }

    func testSubclassCanOverrideHandleRoute() {
        let router = Router<MockRoute>(initial: .home)
        let coordinator = TestCoordinator(router: router)

        let handled = coordinator.handle(route: .details)

        XCTAssertTrue(handled)
        XCTAssertTrue(coordinator.didHandleRoute)
    }
    
    func testNavigateDelegatesToHandleRouteOrChildren() {
        let router = Router<MockRoute>(initial: .home)
        
        // Parent coordinator that doesn't handle the route
        class NonHandlingCoordinator: Coordinator<MockRoute> {}
        let parent = NonHandlingCoordinator(router: router)

        // Child that will handle the route
        let child = TestCoordinator(router: router)
        parent.addChild(child)

        let handled = parent.navigate(to: MockRoute.details)

        XCTAssertTrue(handled, "Expected navigate to delegate handling to child coordinator")
        XCTAssertTrue(child.didHandleRoute, "Expected child coordinator to handle the route")
    }
    
    func testNavigateHandlesRouteInCurrentCoordinator() {
        let router = Router<MockRoute>(initial: .home)
        let coordinator = TestCoordinator(router: router)

        let handled = coordinator.navigate(to: MockRoute.details)

        XCTAssertTrue(handled, "Expected navigate to handle route in current coordinator")
        XCTAssertTrue(coordinator.didHandleRoute, "Expected current coordinator to handle the route")
    }
    
    func testCanPresentAndDismissModalCoordinator() {
        let router = Router<MockRoute>(initial: .home)
        let parent = Coordinator(router: router)
        let modal = Coordinator(router: router)

        // Present modal
        parent.presentModal(modal)
        XCTAssertTrue(parent.modalCoordinator === modal, "Expected modal coordinator to be stored")

        // Dismiss modal
        parent.dismissModal()
        XCTAssertNil(parent.modalCoordinator, "Expected modal coordinator to be nil after dismiss")
    }
    
    func testChildCoordinatorBubblesUpNavigationToParent() {
        let router = Router<MockRoute>(initial: .home)

        let parent = TestCoordinator(router: router)
        let child = Coordinator(router: router)
        parent.addChild(child)

        // Child attempts to navigate
        let handled = child.navigate(to: MockRoute.details)

        XCTAssertTrue(handled, "Expected navigation to bubble up to parent")
        XCTAssertTrue(parent.didHandleRoute, "Expected parent coordinator to handle the route")
    }
}
