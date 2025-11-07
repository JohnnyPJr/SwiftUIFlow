//
//  CoordinatorBasicsTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 5/11/25.
//

@testable import SwiftUIFlow
import XCTest

final class CoordinatorBasicsTests: XCTestCase {
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

        trackForMemoryLeaks(child)

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

    // MARK: - Reset State

    func test_ResetToCleanStateExists() {
        let sut = makeSUT()

        sut.router.push(.details)
        sut.router.present(.modal)

        sut.coordinator.resetToCleanState()

        XCTAssertTrue(sut.router.state.stack.isEmpty, "Stack should be empty after reset")
        XCTAssertNil(sut.router.state.presented, "Modal should be dismissed after reset")
    }
}
