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

    // MARK: - Tab Selection

    func test_SelectTabUpdatesState() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        router.selectTab(2)
        XCTAssertEqual(router.state.selectedTab, 2)
    }

    func test_viewFactoryBuildsCorrectView() {
        let factory = MockViewFactory()
        let router = Router<MockRoute>(initial: .home, factory: factory)
        let view = router.view(for: .details)

        XCTAssertNotNil(view, "Expected view to be built for route")
    }

    func test_viewFactoryBuildsIncorrectView() {
        let factory = ViewFactory<MockRoute>()
        let router = Router<MockRoute>(initial: .home, factory: factory)
        let view = router.view(for: .details)

        XCTAssertNil(view, "Expected view to be nil")
    }
}
