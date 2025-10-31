//
//  BasicCoordinationIntegrationTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 2/8/25.
//

@testable import SwiftUIFlow
import XCTest

final class BasicCoordinationIntegrationTests: XCTestCase {
    // MARK: - Full Navigation Flow

    func test_FullNavigationFlowWithTabsModalsAndDeeplinks() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let mainCoordinator = TestCoordinator(router: router)
        let modalCoordinator = TestModalCoordinator(router: Router<MockRoute>(initial: .modal,
                                                                              factory: MockViewFactory()))

        // Add a modal navigator to modal coordinator to handle .details
        let childRouter = Router<MockRoute>(initial: .details, factory: MockViewFactory())
        let childCoordinator = TestCoordinator(router: childRouter)
        modalCoordinator.addModalCoordinator(childCoordinator)

        // 1. Switch tab
        router.selectTab(1)
        XCTAssertEqual(router.state.selectedTab, 1, "Expected tab index to change")

        // 2. Present modal coordinator
        mainCoordinator.presentModal(modalCoordinator, presenting: .modal)
        XCTAssertTrue(mainCoordinator.currentModalCoordinator === modalCoordinator,
                      "Expected modal coordinator to be presented")

        // 3. Navigate via modal coordinator - should present as modal with child handling it
        let handledModal = modalCoordinator.navigate(to: MockRoute.details)
        XCTAssertTrue(handledModal,
                      "Expected modal coordinator to handle navigation")
        XCTAssertEqual(modalCoordinator.router.state.presented, .details,
                       "Expected route to be presented as modal")
        XCTAssertTrue(modalCoordinator.currentModalCoordinator === childCoordinator,
                      "Child should be modal coordinator")

        // 4. Dismiss modal
        mainCoordinator.dismissModal()
        XCTAssertNil(mainCoordinator.currentModalCoordinator, "Expected modal to be dismissed")

        // 5. Navigate (like deeplink) handled by main coordinator - should push
        _ = mainCoordinator.navigate(to: MockRoute.details)
        XCTAssertEqual(router.state.currentRoute, MockRoute.details, "Expected to be at details route")
    }

    func test_MainTabCoordinatorCanSwitchTabs() {
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        // Should be able to switch tabs directly
        mainCoordinator.switchTab(to: 2)
        XCTAssertEqual(router.state.selectedTab, 2, "Expected tab to switch to index 2")

        mainCoordinator.switchTab(to: 4)
        XCTAssertEqual(router.state.selectedTab, 4, "Expected tab to switch to index 4")
    }

    func test_CoordinatorsCanResetToCleanState() {
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        // Setup some state
        router.push(.tab2)
        router.present(.tab3)
        router.selectTab(2)

        // Reset should clean everything
        mainCoordinator.resetToCleanState()

        XCTAssertTrue(router.state.stack.isEmpty, "Expected stack to be empty after reset")
        XCTAssertNil(router.state.presented, "Expected no modal after reset")
    }
}
