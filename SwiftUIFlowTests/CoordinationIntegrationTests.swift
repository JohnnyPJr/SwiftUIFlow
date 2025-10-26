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
        let modalCoordinator = TestModalCoordinator(router: Router<MockRoute>(initial: .modal,
                                                                              factory: MockViewFactory()))

        // 1. Switch tab
        router.selectTab(1)
        XCTAssertEqual(router.state.selectedTab, 1, "Expected tab index to change")

        // 2. Present modal coordinator
        mainCoordinator.presentModal(modalCoordinator, presenting: .modal)
        XCTAssertTrue(mainCoordinator.modalCoordinator === modalCoordinator,
                      "Expected modal coordinator to be presented")

        // 3. Navigate via modal coordinator - should present as modal
        let handledModal = modalCoordinator.navigate(to: MockRoute.details)
        XCTAssertTrue(handledModal, "Expected modal coordinator to handle navigation")
        XCTAssertEqual(modalCoordinator.router.state.presented, .details, "Expected route to be presented as modal")

        // 4. Dismiss modal
        mainCoordinator.dismissModal()
        XCTAssertNil(mainCoordinator.modalCoordinator, "Expected modal to be dismissed")

        // 5. Navigate (like deeplink) handled by main coordinator - should push
        _ = mainCoordinator.navigate(to: MockRoute.details)
        XCTAssertEqual(router.state.stack.last, MockRoute.details, "Expected route to be pushed")
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

    func test_unlockFlowNavigatesToBatteryStatusAutomatically() {
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        // Navigate to tab2
        XCTAssertTrue(mainCoordinator.navigate(to: MainTabRoute.tab2))
        XCTAssertEqual(router.state.selectedTab, 1)

        // Get tab2 coordinator
        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator at index 1")
            return
        }

        // Navigate through unlock flow
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.enterCode))
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.loading))
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.success))

        // Get unlock coordinator
        guard let unlock = tab2.children.first(where: { $0 is UnlockCoordinator }) as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator")
            return
        }

        // Verify modal is presented
        XCTAssertNotNil(unlock.modalCoordinator, "Expected result modal to be presented")

        // Navigate to battery status from within the modal
        // This should dismiss modal, clean state, switch tab, and navigate
        let success = unlock.modalCoordinator!.navigate(to: Tab5Route.batteryStatus, from: nil)

        XCTAssertTrue(success, "Navigation to battery status should succeed")
        XCTAssertEqual(router.state.selectedTab, 4, "Should switch to tab 5 (index 4)")

        // Verify Tab5 handled the route
        guard let tab5 = mainCoordinator.children[4] as? Tab5Coordinator else {
            XCTFail("Expected Tab5Coordinator at index 4")
            return
        }

        XCTAssertTrue(tab5.didHandleBatteryStatus, "Tab5 should have handled battery status")

        // Modal should be auto-dismissed
        XCTAssertNil(unlock.modalCoordinator, "Modal should be dismissed")
    }

    func test_deeplinkToEnterCodeThenBatteryStatus() {
        // Step 1: Initialize main tab coordinator
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        // Step 2: Navigate to .enterCode (like a deeplink)
        _ = mainCoordinator.navigate(to: UnlockRoute.enterCode)

        // Expect tab2 to be selected
        XCTAssertEqual(router.state.selectedTab, 1, "Expected tab2 to be selected")

        // Expect tab2 coordinator to exist
        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator")
            return
        }

        // Expect UnlockCoordinator to exist as child of tab2
        guard let unlock = tab2.children.first(where: { $0 is UnlockCoordinator }) as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator to be created")
            return
        }

        // Verify enterCode was pushed to unlock's router
        XCTAssertEqual(unlock.router.state.stack.last, .enterCode, "Expected .enterCode to be pushed")

        // Step 3: Navigate to .batteryStatus from current position
        _ = mainCoordinator.navigate(to: Tab5Route.batteryStatus)

        // Expect tab5 to be selected
        XCTAssertEqual(router.state.selectedTab, 4, "Expected tab5 to be selected")

        // Expect Tab5Coordinator to have handled the route
        guard let tab5 = mainCoordinator.children[4] as? Tab5Coordinator else {
            XCTFail("Expected Tab5Coordinator")
            return
        }

        XCTAssertTrue(tab5.didHandleBatteryStatus, "Tab5 should have handled battery status")
    }

    func test_navigateAutomaticallyDismissesModalsDuringTraversal() {
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        // Setup: Navigate to Tab2 -> Unlock -> Modal
        XCTAssertTrue(mainCoordinator.navigate(to: MainTabRoute.tab2))

        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator")
            return
        }

        // Navigate through unlock flow
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.enterCode))
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.success))

        guard let unlock = tab2.children.first(where: { $0 is UnlockCoordinator }) as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator")
            return
        }

        // Verify modal is presented
        XCTAssertNotNil(unlock.modalCoordinator, "Modal should be presented")
        XCTAssertNotNil(unlock.router.state.presented, "Router should have modal presented")

        // Navigate from modal to battery status - should auto-dismiss and switch tabs
        let modal = unlock.modalCoordinator!
        let success = modal.navigate(to: Tab5Route.batteryStatus, from: nil)

        // Now these assertions should PASS with our new implementation
        XCTAssertTrue(success, "Should succeed")
        XCTAssertNil(unlock.modalCoordinator, "Modal should be auto-dismissed during traversal")
        XCTAssertNil(unlock.router.state.presented, "Router modal state should be cleared")
        XCTAssertEqual(router.state.selectedTab, 4, "Should switch to tab 5 during traversal")

        // Verify Tab5 handled it
        guard let tab5 = mainCoordinator.children[4] as? Tab5Coordinator else {
            XCTFail("Expected Tab5Coordinator")
            return
        }

        XCTAssertTrue(tab5.didHandleBatteryStatus, "Tab5 should have handled battery status")
    }

    func test_complexCrossTabNavigationWithCleanup() {
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        // Setup complex state: Tab2 with deep navigation and modal
        XCTAssertTrue(mainCoordinator.navigate(to: MainTabRoute.tab2))

        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator")
            return
        }

        // Build up complex state
        tab2.router.push(.startUnlock) // Push to tab2 stack
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.enterCode))
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.loading))
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.success)) // This presents a modal

        guard let unlock = tab2.children.first(where: { $0 is UnlockCoordinator }) as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator")
            return
        }

        // Verify complex state exists
        XCTAssertFalse(tab2.router.state.stack.isEmpty, "Tab2 should have items in stack")
        XCTAssertNotNil(unlock.modalCoordinator, "Unlock should have modal")
        XCTAssertNotNil(unlock.router.state.presented, "Unlock router should have presented state")

        // Navigate to battery status from deep within modal
        // This should trigger full cleanup: dismiss modal, pop stacks, switch tab
        let success = unlock.modalCoordinator!.navigate(to: Tab5Route.batteryStatus, from: nil)

        XCTAssertTrue(success, "Navigation should succeed")

        // Verify cleanup happened
        XCTAssertNil(unlock.modalCoordinator, "Modal should be dismissed")
        XCTAssertNil(unlock.router.state.presented, "Modal state should be cleared")
        XCTAssertTrue(unlock.router.state.stack.isEmpty, "Unlock stack should be cleared")

        // Verify tab switch
        XCTAssertEqual(router.state.selectedTab, 4, "Should be on tab 5")

        // Verify target was reached
        guard let tab5 = mainCoordinator.children[4] as? Tab5Coordinator else {
            XCTFail("Expected Tab5Coordinator")
            return
        }

        XCTAssertTrue(tab5.didHandleBatteryStatus, "Tab5 should have handled battery status")
    }
}
