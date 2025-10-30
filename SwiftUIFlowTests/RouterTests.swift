//
//  RouterTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 1/8/25.
//

import SwiftUI
@testable import SwiftUIFlow
import XCTest

final class RouterTests: XCTestCase {
    // MARK: - Initialization

    func test_InitializesWithRootState() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        XCTAssertEqual(router.state.root, .home)
        XCTAssertTrue(router.state.stack.isEmpty)
    }

    // MARK: - Navigation Stack Management

    func test_PushAddsRouteToStack() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        router.push(.details)
        XCTAssertEqual(router.state.stack, [.details])
    }

    func test_PopRemovesLastRoute() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        router.push(.details)
        router.pop()
        XCTAssertTrue(router.state.stack.isEmpty)
    }

    func test_SetRootChangesRootAndClearsStack() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        router.push(.details)
        router.setRoot(.login)
        XCTAssertEqual(router.state.root, .login)
        XCTAssertTrue(router.state.stack.isEmpty)
    }

    // MARK: - Modal Handling

    func test_PresentAndDismissModal() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        router.present(.modal)
        XCTAssertEqual(router.state.presented, .modal)

        router.dismissModal()
        XCTAssertNil(router.state.presented)
    }

    // MARK: - Detour Handling

    func test_PresentAndDismissDetour() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        router.presentDetour(MockRoute.details)
        XCTAssertEqual(router.state.detour?.identifier, MockRoute.details.identifier)

        router.dismissDetour()
        XCTAssertNil(router.state.detour)
    }

    func test_DetourDoesNotAffectModalState() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())

        // Present a modal
        router.present(.modal)
        XCTAssertEqual(router.state.presented, .modal)

        // Present a detour - should not affect modal
        router.presentDetour(MockRoute.details)
        XCTAssertEqual(router.state.presented, .modal, "Modal should still be presented")
        XCTAssertEqual(router.state.detour?.identifier, MockRoute.details.identifier)

        // Dismiss detour - modal should remain
        router.dismissDetour()
        XCTAssertEqual(router.state.presented, .modal, "Modal should still be presented")
        XCTAssertNil(router.state.detour)
    }

    // MARK: - Tab Selection

    func test_SelectTabUpdatesState() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        router.selectTab(2)
        XCTAssertEqual(router.state.selectedTab, 2)
    }

    func test_viewFactoryBuildsCorrectView() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let view = router.view(for: .details)

        XCTAssertNotNil(view, "Expected view to be built for route")
    }

    func test_viewFactoryBuildsIncorrectView() {
        let router = Router<MockRoute>(initial: .home, factory: ViewFactory<MockRoute>())
        let view = router.view(for: .details)

        XCTAssertNil(view, "Expected view to be nil")
    }

    func test_PopToRootClearsEntireStack() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        router.push(.details)
        router.push(.login)

        router.popToRoot()

        XCTAssertTrue(router.state.stack.isEmpty, "Expected stack to be empty after popToRoot")
    }

    func test_DismissAllModalsClearsPresented() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        router.present(.modal)
        router.presentDetour(MockRoute.details)

        router.dismissAllModals()

        XCTAssertNil(router.state.presented, "Expected presented to be nil after dismissAllModals")
        XCTAssertNil(router.state.detour, "Expected detour to be nil after dismissAllModals")
    }

    func test_ResetToRootClearsStackAndModals() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        router.push(.details)
        router.push(.login)
        router.present(.modal)
        router.presentDetour(MockRoute.details)

        router.resetToRoot()

        XCTAssertTrue(router.state.stack.isEmpty, "Expected stack to be empty after resetToRoot")
        XCTAssertNil(router.state.presented, "Expected presented to be nil after resetToRoot")
        XCTAssertNil(router.state.detour, "Expected detour to be nil after resetToRoot")
    }
}
