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
        // Note: selectedTab might not reset - that's tab coordinator specific behavior
    }

    func test_deeplinkToEnterCodeThenBatteryStatus() {
        // Step 1: Initialize main tab coordinator and root router
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        // Step 2: Deeplink to .enterCode
        mainCoordinator.handleDeeplink(UnlockRoute.enterCode)

        // 🔎 Expect tab2 to be selected
        XCTAssertEqual(router.state.selectedTab, 1, "Expected tab2 to be selected")

        // 🔎 Expect tab2 coordinator to exist
        guard let tab2 = mainCoordinator.children.first(where: { $0 is Tab2Coordinator }) as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator to be built")
            return
        }

        // 🔎 Expect UnlockCoordinator to exist
        guard let unlock = tab2.children.first(where: { $0 is UnlockCoordinator }) as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator to be built")
            return
        }

        // 🔎 Expect UnlockCoordinator to have handled .enterCode
        XCTAssertTrue(unlock.canHandle(UnlockRoute.enterCode), "UnlockCoordinator should handle .enterCode")

        // Step 3: Deeplink to .batteryStatus from *deep in the flow* (e.g., unlock result modal or unlock itself)
        // We'll simulate this from unlock.result (modal) if it's there, or unlock directly
        let origin: AnyCoordinator = unlock.modalCoordinator ?? unlock

        origin.handleDeeplink(Tab5Route.batteryStatus)

        // 🔎 Expect tab5 to be selected
        XCTAssertEqual(router.state.selectedTab, 4, "Expected tab5 to be selected after deeplink")

        // 🔎 Expect Tab5Coordinator to have handled the route
        guard let tab5 = mainCoordinator.children.first(where: {
            ($0 as? Tab5Coordinator)?.didHandleBatteryStatus == true
        }) else {
            XCTFail("Tab5Coordinator did not handle battery status")
            return
        }

        XCTAssertTrue((tab5 as? Tab5Coordinator)?.didHandleBatteryStatus == true)
    }

    func test_navigateWithFlowDismissesModalsDuringTraversal() {
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        // Setup: Tab2 -> Unlock -> Modal
        XCTAssertTrue(mainCoordinator.navigate(to: MainTabRoute.tab2))
        guard let unlock = getUnlockCoordinator(from: mainCoordinator) else {
            XCTFail("Setup failed")
            return
        }

        XCTAssertTrue(unlock.navigate(to: UnlockRoute.success))
        XCTAssertNotNil(getModalCoordinator(from: unlock), "Modal should be presented")

        // Record initial state
        let initialTabIndex = router.state.selectedTab
        let modal = getModalCoordinator(from: unlock)!

        // CRITICAL: This should NOT switch tabs or dismiss modals with current implementation
        // We expect this to fail in the current system
        let success = modal.navigateWithFlow(to: Tab5Route.batteryStatus)

        // These assertions should FAIL with current implementation
        XCTAssertTrue(success, "Should succeed")
        XCTAssertNil(getModalCoordinator(from: unlock), "Modal should be dismissed during traversal")
        XCTAssertEqual(router.state.selectedTab, 4, "Should switch to tab 5 during traversal")
    }

    // Helper methods to avoid casting
    private func getUnlockCoordinator(from mainCoordinator: MainTabCoordinator) -> UnlockCoordinator? {
        guard let tab2 = mainCoordinator.children.first(where: { $0 is Tab2Coordinator }) as? Tab2Coordinator else { return nil }
        return tab2.children.first(where: { $0 is UnlockCoordinator }) as? UnlockCoordinator
    }

    private func getModalCoordinator(from unlock: UnlockCoordinator) -> AnyCoordinator? {
        return (unlock as Coordinator<UnlockRoute>).modalCoordinator
    }
}
