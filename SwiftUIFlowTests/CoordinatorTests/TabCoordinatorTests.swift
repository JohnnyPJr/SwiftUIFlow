//
//  TabCoordinatorTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 5/11/25.
//

@testable import SwiftUIFlow
import XCTest

final class TabCoordinatorTests: XCTestCase {
    // MARK: - Tab Context

    func test_TabCoordinatorAutomaticallySetsTabContext() {
        let tabRouter = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let tabCoordinator = TestTabCoordinator(router: tabRouter)

        let tab1Child = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))

        tabCoordinator.addChild(tab1Child)

        XCTAssertEqual(tab1Child.presentationContext, .tab,
                       "TabCoordinator should automatically set .tab context for children")
    }

    func test_TabCoordinatorCanOverrideContextExplicitly() {
        let tabRouter = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let tabCoordinator = TestTabCoordinator(router: tabRouter)

        let child = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))

        // Explicitly override with .pushed (unusual but should work)
        tabCoordinator.addChild(child, context: .pushed)

        XCTAssertEqual(child.presentationContext, .pushed,
                       "TabCoordinator should respect explicit context override")
    }

    // MARK: - Tab Management

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
}
