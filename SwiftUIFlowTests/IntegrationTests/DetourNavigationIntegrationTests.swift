//
//  DetourNavigationIntegrationTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 2/8/25.
//

@testable import SwiftUIFlow
import XCTest

final class DetourNavigationIntegrationTests: XCTestCase {
    func test_DetourPresentationPreservesContext() {
        // Scenario: Instagram-style notification deep link
        // User is deep in unlock flow, taps notification, detours to battery status
        // Back button should return to original location with context preserved

        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        // Navigate to Tab2
        XCTAssertTrue(mainCoordinator.navigate(to: MainTabRoute.tab2))
        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator")
            return
        }

        // Build deep navigation state in unlock flow
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.enterCode))
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.loading))
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.failure))

        guard let unlock = tab2.children.first(where: { $0 is UnlockCoordinator }) as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator")
            return
        }

        // Verify deep state exists before detour
        XCTAssertEqual(unlock.router.state.stack.count, 2, "Should have loading and failure in stack")
        XCTAssertEqual(unlock.router.state.currentRoute, .failure, "Should be at failure")

        // Present detour: Battery Status notification (different coordinator)
        guard let tab5 = mainCoordinator.children[4] as? Tab5Coordinator else {
            XCTFail("Expected Tab5Coordinator at index 4")
            return
        }
        unlock.presentDetour(tab5, presenting: Tab5Route.batteryStatus)

        // Verify detour is presented
        XCTAssertTrue(unlock.detourCoordinator === tab5, "Detour coordinator should be presented")
        XCTAssertEqual(unlock.router.state.detour?.identifier, Tab5Route.batteryStatus.identifier)

        // Verify context is PRESERVED underneath
        XCTAssertEqual(unlock.router.state.stack.count, 2, "Stack should be preserved")
        XCTAssertEqual(unlock.router.state.currentRoute, .failure, "Should still be at failure underneath")

        // Verify we're still on Tab2 (didn't switch tabs)
        XCTAssertEqual(router.state.selectedTab, 1, "Should still be on Tab2")

        // Dismiss detour
        unlock.dismissDetour()

        // Verify we're back to original context
        XCTAssertNil(unlock.detourCoordinator, "Detour should be dismissed")
        XCTAssertNil(unlock.router.state.detour, "Detour state should be cleared")
        XCTAssertEqual(unlock.router.state.stack.count, 2, "Stack should still be preserved")
        XCTAssertEqual(unlock.router.state.currentRoute, .failure, "Should be back at failure")
    }

    func test_DetourAutoDismissesWhenNavigatingToIncompatibleRoute() {
        // Scenario: User in detour, navigates to route detour can't handle
        // Expected: Detour dismisses, parent handles navigation properly

        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        // Navigate to Tab2 and build state
        XCTAssertTrue(mainCoordinator.navigate(to: MainTabRoute.tab2))
        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator")
            return
        }

        XCTAssertTrue(tab2.navigate(to: UnlockRoute.enterCode))
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.loading))
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.success))

        guard let unlock = tab2.children.first(where: { $0 is UnlockCoordinator }) as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator")
            return
        }

        // Present detour
        guard let tab5 = mainCoordinator.children[4] as? Tab5Coordinator else {
            XCTFail("Expected Tab5Coordinator at index 4")
            return
        }
        unlock.presentDetour(tab5, presenting: Tab5Route.batteryStatus)
        XCTAssertNotNil(unlock.detourCoordinator, "Detour should be presented")

        // Navigate to a different tab's route from within the detour
        // Tab5 can't handle Tab3Route, so it bubbles up
        // Unlock can't handle it either, so it dismisses detour and bubbles up
        // Main coordinator switches to Tab3
        let success = tab5.navigate(to: MainTabRoute.tab3)

        XCTAssertTrue(success, "Navigation should succeed")
        XCTAssertNil(unlock.detourCoordinator, "Detour should be auto-dismissed")
        XCTAssertNil(unlock.router.state.detour, "Detour state should be cleared")
        XCTAssertEqual(router.state.selectedTab, 2, "Should switch to Tab3")
    }

    func test_ModalPresentedThenDetourCalled() {
        // Edge case: Modal is presented, then detour navigation is called
        // Expected: Modal remains, detour is presented on top (both can coexist)
        // When detour dismisses, modal should still be there

        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        // Navigate to Tab2
        XCTAssertTrue(mainCoordinator.navigate(to: MainTabRoute.tab2))
        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator")
            return
        }

        XCTAssertTrue(tab2.navigate(to: UnlockRoute.enterCode))
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.success)) // Presents modal

        guard let unlock = tab2.children.first(where: { $0 is UnlockCoordinator }) as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator")
            return
        }

        // Verify modal is presented
        XCTAssertNotNil(unlock.currentModalCoordinator, "Modal should be presented")
        XCTAssertNotNil(unlock.router.state.presented, "Router should have modal state")

        // Now present detour while modal is active
        guard let tab5 = mainCoordinator.children[4] as? Tab5Coordinator else {
            XCTFail("Expected Tab5Coordinator at index 4")
            return
        }
        unlock.presentDetour(tab5, presenting: Tab5Route.batteryStatus)

        // Verify both modal and detour exist
        XCTAssertNotNil(unlock.currentModalCoordinator, "Modal should still exist")
        XCTAssertNotNil(unlock.router.state.presented, "Modal state should still exist")
        XCTAssertNotNil(unlock.detourCoordinator, "Detour should be presented")
        XCTAssertNotNil(unlock.router.state.detour, "Detour state should exist")

        // Dismiss detour
        unlock.dismissDetour()

        // Verify modal remains after detour dismissal
        XCTAssertNil(unlock.detourCoordinator, "Detour should be dismissed")
        XCTAssertNil(unlock.router.state.detour, "Detour state should be cleared")
        XCTAssertNotNil(unlock.currentModalCoordinator, "Modal should still be present")
        XCTAssertNotNil(unlock.router.state.presented, "Modal state should still exist")
    }
}
