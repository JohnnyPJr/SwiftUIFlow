//
//  CrossTabNavigationIntegrationTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 2/8/25.
//

@testable import SwiftUIFlow
import XCTest

final class CrossTabNavigationIntegrationTests: XCTestCase {
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
        XCTAssertNotNil(unlock.currentModalCoordinator, "Expected result modal to be presented")

        // Navigate to battery status from within the modal
        // This should dismiss modal, clean state, switch tab, and navigate
        let success = unlock.currentModalCoordinator!.navigate(to: Tab5Route.batteryStatus, from: nil)

        XCTAssertTrue(success, "Navigation to battery status should succeed")
        XCTAssertEqual(router.state.selectedTab, 4, "Should switch to tab 5 (index 4)")

        // Verify Tab5 handled the route
        guard let tab5 = mainCoordinator.children[4] as? Tab5Coordinator else {
            XCTFail("Expected Tab5Coordinator at index 4")
            return
        }

        XCTAssertTrue(tab5.didHandleBatteryStatus, "Tab5 should have handled battery status")

        // Modal should be auto-dismissed
        XCTAssertNil(unlock.currentModalCoordinator, "Modal should be dismissed")
    }

    func test_deeplinkToEnterCodeThenBatteryStatus() {
        // Step 1: Initialize main tab coordinator
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        // Step 2: Navigate to .enterCode (like a deeplink)
        mainCoordinator.navigate(to: UnlockRoute.enterCode)

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

        // Verify we're at enterCode root (stack is empty when at root)
        XCTAssertTrue(unlock.router.state.stack.isEmpty, "Stack should be empty - we're at the root (.enterCode)")

        // Step 3: Navigate to .batteryStatus from current position
        mainCoordinator.navigate(to: Tab5Route.batteryStatus)

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
        XCTAssertNotNil(unlock.currentModalCoordinator, "Modal should be presented")
        XCTAssertNotNil(unlock.router.state.presented, "Router should have modal presented")

        // Navigate from modal to battery status - should auto-dismiss and switch tabs
        let modal = unlock.currentModalCoordinator!
        let success = modal.navigate(to: Tab5Route.batteryStatus, from: nil)

        // Now these assertions should PASS with our new implementation
        XCTAssertTrue(success, "Should succeed")
        XCTAssertNil(unlock.currentModalCoordinator, "Modal should be auto-dismissed during traversal")
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
        XCTAssertNotNil(unlock.currentModalCoordinator, "Unlock should have modal")
        XCTAssertNotNil(unlock.router.state.presented, "Unlock router should have presented state")

        // Navigate to battery status from deep within modal
        // This should trigger full cleanup: dismiss modal, pop stacks, switch tab
        let success = unlock.currentModalCoordinator!.navigate(to: Tab5Route.batteryStatus, from: nil)

        XCTAssertTrue(success, "Navigation should succeed")

        // Verify cleanup happened
        XCTAssertNil(unlock.currentModalCoordinator, "Modal should be dismissed")
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

    // MARK: - Modal with Pushed Screen Tests

    func test_CrossTabNavigation_ToModalThatPushesScreen() {
        // Scenario: From tab1 -> navigate to tab2 -> present modal (.success) -> push screen (.details)
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        // Start at tab1
        XCTAssertEqual(router.state.selectedTab, 0, "Should start at tab1")

        // Navigate from tab1 to .details (which is in tab2's modal)
        let success = mainCoordinator.navigate(to: UnlockRoute.details)

        XCTAssertTrue(success, "Navigation should succeed")
        XCTAssertEqual(router.state.selectedTab, 1, "Should switch to tab2")

        // Get tab2 coordinator
        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator at index 1")
            return
        }

        // Get unlock coordinator
        guard let unlock = tab2.children.first(where: { $0 is UnlockCoordinator }) as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator")
            return
        }

        // Verify modal (.success) is presented
        XCTAssertNotNil(unlock.currentModalCoordinator, "Expected success modal to be presented")
        guard let resultModal = unlock.currentModalCoordinator as? UnlockResultCoordinator else {
            XCTFail("Expected UnlockResultCoordinator")
            return
        }

        // Verify .details is pushed within the modal
        XCTAssertEqual(resultModal.router.state.currentRoute.identifier, "details",
                       "Should be at .details route within modal")
        XCTAssertEqual(resultModal.router.state.stack.count, 1,
                       "Should have 1 item in modal's stack (.details)")
    }

    func test_CrossTabNavigation_ToModalThatPresentsNestedModal() {
        // Scenario: From tab1 -> navigate to tab2 -> present modal (.success) -> present nested modal (.settings)
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        // Start at tab1
        XCTAssertEqual(router.state.selectedTab, 0, "Should start at tab1")

        // Navigate from tab1 to .settings (which is nested modal in tab2's modal)
        let success = mainCoordinator.navigate(to: UnlockRoute.settings)

        XCTAssertTrue(success, "Navigation should succeed")
        XCTAssertEqual(router.state.selectedTab, 1, "Should switch to tab2")

        // Get tab2 coordinator
        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator at index 1")
            return
        }

        // Get unlock coordinator
        guard let unlock = tab2.children.first(where: { $0 is UnlockCoordinator }) as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator")
            return
        }

        // Verify first modal (.success) is presented
        XCTAssertNotNil(unlock.currentModalCoordinator, "Expected success modal to be presented")
        guard let resultModal = unlock.currentModalCoordinator as? UnlockResultCoordinator else {
            XCTFail("Expected UnlockResultCoordinator")
            return
        }

        // Verify nested modal (.settings) is presented within the first modal
        XCTAssertNotNil(resultModal.currentModalCoordinator, "Expected nested modal to be presented")
        guard resultModal.currentModalCoordinator is UnlockSettingsModalCoordinator else {
            XCTFail("Expected UnlockSettingsModalCoordinator")
            return
        }

        // Verify .settings is the presented route
        XCTAssertEqual(resultModal.router.state.presented?.identifier, "settings",
                       "Settings should be presented as nested modal")
    }
}
