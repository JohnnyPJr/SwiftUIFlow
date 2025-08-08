//
//  CoordinationIntegrationTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 2/8/25.
//

@testable import SwiftUIFlow
import XCTest

final class CoordinationIntegrationTests: XCTestCase {
    // MARK: - Full Navigation Flow

    func test_FullNavigationFlowWithTabsModalsAndDeeplinks() {
        let router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let mainCoordinator = TestCoordinator(router: router)
        let modalCoordinator = TestCoordinator(router: Router<MockRoute>(initial: .modal, factory: MockViewFactory()))

        // 1. Switch tab
        router.selectTab(1)
        XCTAssertEqual(router.state.selectedTab, 1, "Expected tab index to change")

        // 2. Present modal coordinator
        mainCoordinator.presentModal(modalCoordinator)
        XCTAssertTrue(mainCoordinator.modalCoordinator === modalCoordinator,
                      "Expected modal coordinator to be presented")

        // 3. Navigate via modal coordinator
        let handledModal = modalCoordinator.navigate(to: MockRoute.details)
        XCTAssertTrue(handledModal, "Expected modal coordinator to handle navigation")
        XCTAssertEqual(modalCoordinator.lastHandledRoute, .details)

        // 4. Dismiss modal
        mainCoordinator.dismissModal()
        XCTAssertNil(mainCoordinator.modalCoordinator, "Expected modal to be dismissed")

        // 5. Deeplink handled by main coordinator
        mainCoordinator.handleDeeplink(MockRoute.details)
        XCTAssertTrue(mainCoordinator.didHandleRoute, "Expected deeplink to be handled by main coordinator")
        XCTAssertEqual(mainCoordinator.lastHandledRoute, MockRoute.details)
    }

    func test_unlockFlowRoutesBatteryStatusThroughModal() {
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        XCTAssertTrue(mainCoordinator.navigate(to: MainTabRoute.tab2))
        XCTAssertEqual(router.state.selectedTab, 1)

        guard let tab2 = mainCoordinator.children.first(where: { $0 is Tab2Coordinator }),
              tab2.navigate(to: Tab2Route.startUnlock),
              let unlock = (tab2 as? Tab2Coordinator)?.children.first(where: { $0 is UnlockCoordinator }),
              unlock.navigate(to: UnlockRoute.enterCode),
              unlock.navigate(to: UnlockRoute.loading),
              unlock.navigate(to: UnlockRoute.success)
        else {
            XCTFail("Unlock flow setup failed")
            return
        }

        guard let result = (unlock as? UnlockCoordinator)?.result else {
            XCTFail("Missing UnlockResultCoordinator")
            return
        }

        // Simulate navigation to unrelated route from modal
        XCTAssertTrue(result.navigate(to: Tab5Route.batteryStatus))

        XCTAssertEqual(router.state.selectedTab, 4)

        guard let tab5 = mainCoordinator.children.first(where: {
            ($0 as? Tab5Coordinator)?.didHandleBatteryStatus == true
        }) else {
            XCTFail("Tab5Coordinator did not handle battery status")
            return
        }

        XCTAssertTrue((tab5 as? Tab5Coordinator)?.didHandleBatteryStatus == true)
    }
}
