//
//  PushedChildRegressionTests.swift
//  SwiftUIFlowTests
//
//  Regression tests for bugs related to pushed child coordinators
//  These tests ensure bugs that were discovered during development stay fixed.
//

@testable import SwiftUIFlow
import XCTest

/// Regression tests for pushed child coordinator bugs
/// These tests catch specific scenarios that previously caused bugs
final class PushedChildRegressionTests: XCTestCase {
    // MARK: - Double-Push Bug (Regression Test)

    func test_DoublePush_ChildNotPushedTwiceAfterTabSwitch() {
        // Given: Tab coordinator with multiple tabs
        let router = Router<MainTabRoute>(initial: .tab2, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator at index 1")
            return
        }

        // Step 1: Navigate within tab2 to push UnlockCoordinator
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.enterCode))

        guard let unlock = tab2.router.state.pushedChildren.first as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator to be pushed in tab2")
            return
        }

        // Navigate deeper into the pushed child
        XCTAssertTrue(unlock.navigate(to: UnlockRoute.loading))
        XCTAssertEqual(unlock.router.state.stack.count, 1, "Unlock should have 1 route in stack")

        // Verify child is pushed only once
        XCTAssertEqual(tab2.router.state.pushedChildren.count, 1, "Tab2 should have 1 pushed child")
        XCTAssertTrue(tab2.router.state.pushedChildren.contains(where: { $0 === unlock }))

        // Step 2: Switch to a different tab (simulates user switching tabs)
        mainCoordinator.switchToTab(0) // Switch to tab1
        XCTAssertEqual(mainCoordinator.router.state.selectedTab, 0)

        // Step 3: Deep link to a DIFFERENT route (not already in stack)
        // This will switch back to tab2 and try to navigate to the already-pushed child
        // Using .failure which is NOT in the stack (stack only has .loading)
        XCTAssertTrue(mainCoordinator.navigate(to: UnlockRoute.failure))

        // Verify: Child should NOT be pushed twice
        XCTAssertEqual(tab2.router.state.pushedChildren.count, 1,
                       "Tab2 should STILL have only 1 pushed child (not 2!)")

        // Verify it's the same coordinator instance
        guard let unlockAfterNavigation = tab2.router.state.pushedChildren.first as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator to still be pushed")
            return
        }
        XCTAssertTrue(unlockAfterNavigation === unlock,
                      "Should be the same coordinator instance, not a duplicate")

        // Verify the child's stack grew (loading → failure), not replaced
        XCTAssertEqual(unlock.router.state.stack.count, 2,
                       "Child's navigation stack should have grown (loading + failure)")
    }

    // MARK: - Modal State Not Reset Bug (Regression Test)

    func test_ModalReset_ModalStateResetOnDismissal() {
        // Given: Tab2 with UnlockCoordinator that has a modal
        let router = Router<MainTabRoute>(initial: .tab2, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator")
            return
        }

        // Navigate to UnlockCoordinator (push it)
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.enterCode))

        guard let unlock = tab2.router.state.pushedChildren.first as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator to be pushed")
            return
        }

        // Step 1: Present modal (.success) and navigate within it
        XCTAssertTrue(unlock.navigate(to: UnlockRoute.success))
        XCTAssertNotNil(unlock.router.state.presented, "Modal should be presented")

        guard let modalCoordinator = unlock.currentModalCoordinator as? UnlockResultCoordinator else {
            XCTFail("Expected UnlockResultCoordinator as modal")
            return
        }

        // Navigate within modal
        XCTAssertTrue(modalCoordinator.navigate(to: UnlockRoute.details))
        XCTAssertEqual(modalCoordinator.router.state.stack.count, 1, "Modal should have 1 item in stack")

        // Step 2: Dismiss the modal
        unlock.dismissModal()

        // Verify modal is dismissed
        XCTAssertNil(unlock.router.state.presented, "Modal should be dismissed")
        XCTAssertNil(unlock.currentModalCoordinator, "Current modal coordinator should be nil")

        // Step 3: Present modal again
        XCTAssertTrue(unlock.navigate(to: UnlockRoute.success))

        guard let modalCoordinatorAgain = unlock.currentModalCoordinator as? UnlockResultCoordinator else {
            XCTFail("Expected UnlockResultCoordinator as modal")
            return
        }

        // Verify: Modal should be at clean state (no stale stack)
        XCTAssertTrue(modalCoordinatorAgain.router.state.stack.isEmpty,
                      "Modal should have clean stack after re-presentation")

        // Verify it's the same coordinator instance (recycled)
        XCTAssertTrue(modalCoordinator === modalCoordinatorAgain,
                      "Should reuse the same modal coordinator instance")
    }

    // MARK: - Tab Switch State Preservation

    func test_TabSwitch_PreservesPushedChildState() {
        // Given: Tab coordinator with pushed child in tab2
        let router = Router<MainTabRoute>(initial: .tab2, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2 coordinator")
            return
        }

        // Navigate to push a child
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.enterCode))

        guard let unlock = tab2.router.state.pushedChildren.first as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator to be pushed")
            return
        }

        // Navigate deeper
        XCTAssertTrue(unlock.navigate(to: UnlockRoute.loading))
        let stackCount = unlock.router.state.stack.count

        // When: Switch away from tab2 and back
        mainCoordinator.switchToTab(0) // Switch to tab1
        mainCoordinator.switchToTab(1) // Switch back to tab2

        // Then: State should be preserved
        XCTAssertEqual(tab2.router.state.pushedChildren.count, 1,
                       "Pushed children should be preserved after tab switch")
        XCTAssertTrue(tab2.router.state.pushedChildren.contains(where: { $0 === unlock }),
                      "Same coordinator instance should be preserved")
        XCTAssertEqual(unlock.router.state.stack.count, stackCount,
                       "Child's navigation stack should be preserved")
    }

    // MARK: - Cross-Tab Deep Link to Already-Pushed Child

    func test_CrossTabDeepLink_ToAlreadyPushedChild_DoesNotDuplicate() {
        // Given: Tab coordinator with child pushed in tab2
        let router = Router<MainTabRoute>(initial: .tab2, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2 coordinator")
            return
        }

        // Push child in tab2
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.enterCode))

        guard let unlock = tab2.router.state.pushedChildren.first as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator to be pushed")
            return
        }

        // Navigate deeper
        XCTAssertTrue(unlock.navigate(to: UnlockRoute.loading))
        XCTAssertEqual(unlock.router.state.stack.count, 1)

        // Switch to another tab
        mainCoordinator.switchToTab(0)

        // When: Deep link to a deeper route in the already-pushed child
        XCTAssertTrue(mainCoordinator.navigate(to: UnlockRoute.failure))

        // Then: Should navigate within the existing pushed child, not push it again
        XCTAssertEqual(tab2.router.state.pushedChildren.count, 1,
                       "Should still have only 1 pushed child")
        XCTAssertTrue(tab2.router.state.pushedChildren.first === unlock,
                      "Should be the same coordinator instance")

        // Verify navigation happened within the child
        XCTAssertEqual(unlock.router.state.stack.count, 2,
                       "Stack should have grown (loading + failure)")
    }

    // MARK: - resetToCleanState Clears Pushed Children

    func test_ResetToCleanState_ClearsPushedChildren() {
        // Given: Coordinator with pushed child
        let router = Router<MainTabRoute>(initial: .tab2, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2 coordinator")
            return
        }

        // Push child and navigate
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.enterCode))
        XCTAssertEqual(tab2.router.state.pushedChildren.count, 1)

        guard let unlock = tab2.router.state.pushedChildren.first as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator")
            return
        }

        XCTAssertTrue(unlock.navigate(to: UnlockRoute.loading))
        XCTAssertEqual(unlock.router.state.stack.count, 1)

        // When: Reset to clean state
        tab2.resetToCleanState()

        // Then: Everything should be cleared
        XCTAssertTrue(tab2.router.state.stack.isEmpty, "Stack should be empty")
        XCTAssertTrue(tab2.router.state.pushedChildren.isEmpty, "Pushed children should be empty")
        XCTAssertNil(tab2.router.state.presented, "No modal should be presented")
        XCTAssertNil(tab2.currentModalCoordinator, "Modal coordinator should be nil")
    }

    // MARK: - cleanStateForBubbling Pops Pushed Children

    func test_CleanStateForBubbling_PopsPushedChildren() {
        // Given: Tab2 with pushed child that will bubble navigation to main coordinator
        let router = Router<MainTabRoute>(initial: .tab2, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2 coordinator")
            return
        }

        // Push child and navigate within it
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.enterCode))

        guard let unlock = tab2.router.state.pushedChildren.first as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator")
            return
        }

        XCTAssertTrue(unlock.navigate(to: UnlockRoute.loading))
        XCTAssertEqual(tab2.router.state.pushedChildren.count, 1)

        // When: Navigate to a route that causes bubbling (e.g., to another tab)
        XCTAssertTrue(unlock.navigate(to: MainTabRoute.tab3))

        // Then: Tab2 should have cleaned state before bubbling
        XCTAssertTrue(tab2.router.state.pushedChildren.isEmpty,
                      "Pushed children should be cleared before bubbling")
        XCTAssertTrue(tab2.router.state.stack.isEmpty,
                      "Stack should be cleared before bubbling")

        // Verify we successfully switched to tab3
        XCTAssertEqual(mainCoordinator.router.state.selectedTab, 2)
    }
}
