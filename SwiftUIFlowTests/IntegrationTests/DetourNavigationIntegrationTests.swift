//
//  DetourNavigationIntegrationTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 2/8/25.
//

@testable import SwiftUIFlow
import XCTest

@MainActor
final class DetourNavigationIntegrationTests: XCTestCase {
    override func tearDown() {
        SwiftUIFlowErrorHandler.shared.reset()
        super.tearDown()
    }

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

        // Present detour: Battery Status notification (fresh temporary coordinator)
        let batteryDetour = makeBatteryDetour()
        unlock.presentDetour(batteryDetour, presenting: Tab5Route.batteryStatus)

        // Verify detour is presented
        XCTAssertTrue(unlock.detourCoordinator === batteryDetour, "Detour coordinator should be presented")
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

    func test_DetourCanBePresentedAgainAfterDismissal() {
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        XCTAssertTrue(mainCoordinator.navigate(to: MainTabRoute.tab2))
        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator")
            return
        }

        guard let unlock = tab2.children.first(where: { $0 is UnlockCoordinator }) as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator")
            return
        }

        let batteryDetour = makeBatteryDetour()

        unlock.presentDetour(batteryDetour, presenting: Tab5Route.batteryStatus)
        XCTAssertTrue(unlock.detourCoordinator === batteryDetour)
        XCTAssertTrue(batteryDetour.parent === unlock)

        unlock.dismissDetour()
        XCTAssertNil(unlock.detourCoordinator)
        XCTAssertNil(batteryDetour.parent)

        unlock.presentDetour(batteryDetour, presenting: Tab5Route.batteryStatus)

        XCTAssertTrue(unlock.detourCoordinator === batteryDetour)
        XCTAssertTrue(batteryDetour.parent === unlock)
        XCTAssertEqual(batteryDetour.presentationContext, .detour)
        XCTAssertEqual(unlock.router.state.detour?.identifier, Tab5Route.batteryStatus.identifier)
    }

    func test_DismissDetour_ResetsPresentationContext() {
        let host = NestedDetourCoordinator(root: .host)
        let detour = NestedDetourCoordinator(root: .first)

        host.presentDetour(detour, presenting: NestedDetourRoute.first)
        XCTAssertEqual(detour.presentationContext, .detour,
                       "Precondition: detour context should be set")

        host.dismissDetour()

        XCTAssertNil(detour.parent)
        XCTAssertEqual(detour.presentationContext, .root)
    }

    func test_PresentDetour_WhenActiveDetourExists_NestsNewDetourOnActiveDetour() {
        let host = NestedDetourCoordinator(root: .host)
        let first = NestedDetourCoordinator(root: .first)
        let second = NestedDetourCoordinator(root: .second)

        host.presentDetour(first, presenting: NestedDetourRoute.first)
        host.presentDetour(second, presenting: NestedDetourRoute.second)

        XCTAssertTrue(host.detourCoordinator === first)
        XCTAssertTrue(first.detourCoordinator === second)
        XCTAssertTrue(first.parent === host)
        XCTAssertTrue(second.parent === first)
        XCTAssertEqual(first.presentationContext, .detour)
        XCTAssertEqual(second.presentationContext, .detour)
        XCTAssertEqual(host.router.state.detour?.identifier, NestedDetourRoute.first.identifier)
        XCTAssertEqual(first.router.state.detour?.identifier, NestedDetourRoute.second.identifier)
    }

    func test_PresentDetour_WhenMultipleDetoursArrive_NestsToDeepestActiveDetour() {
        let host = NestedDetourCoordinator(root: .host)
        let first = NestedDetourCoordinator(root: .first)
        let second = NestedDetourCoordinator(root: .second)
        let third = NestedDetourCoordinator(root: .third)

        host.presentDetour(first, presenting: NestedDetourRoute.first)
        host.presentDetour(second, presenting: NestedDetourRoute.second)
        host.presentDetour(third, presenting: NestedDetourRoute.third)

        XCTAssertTrue(host.detourCoordinator === first)
        XCTAssertTrue(first.detourCoordinator === second)
        XCTAssertTrue(second.detourCoordinator === third)
        XCTAssertTrue(third.parent === second)
        XCTAssertEqual(second.router.state.detour?.identifier, NestedDetourRoute.third.identifier)
    }

    func test_Pop_FromNestedDetour_DismissesOnlyTopDetour() {
        let host = NestedDetourCoordinator(root: .host)
        let first = NestedDetourCoordinator(root: .first)
        let second = NestedDetourCoordinator(root: .second)

        host.presentDetour(first, presenting: NestedDetourRoute.first)
        host.presentDetour(second, presenting: NestedDetourRoute.second)

        second.pop()

        XCTAssertTrue(host.detourCoordinator === first)
        XCTAssertNil(first.detourCoordinator)
        XCTAssertNil(first.router.state.detour)
        XCTAssertNil(second.parent)
        XCTAssertTrue(first.parent === host)
    }

    func test_DismissDetour_FromHost_TearsDownNestedDetourSubtree() {
        let host = NestedDetourCoordinator(root: .host)
        let first = NestedDetourCoordinator(root: .first)
        let second = NestedDetourCoordinator(root: .second)
        let third = NestedDetourCoordinator(root: .third)
        trackForMemoryLeaks(host)
        trackForMemoryLeaks(first)
        trackForMemoryLeaks(second)
        trackForMemoryLeaks(third)

        host.presentDetour(first, presenting: NestedDetourRoute.first)
        host.presentDetour(second, presenting: NestedDetourRoute.second)
        host.presentDetour(third, presenting: NestedDetourRoute.third)

        host.dismissDetour()

        XCTAssertNil(host.detourCoordinator)
        XCTAssertNil(host.router.state.detour)
        XCTAssertNil(first.detourCoordinator)
        XCTAssertNil(first.router.state.detour)
        XCTAssertNil(second.detourCoordinator)
        XCTAssertNil(second.router.state.detour)
        XCTAssertNil(first.parent)
        XCTAssertNil(second.parent)
        XCTAssertNil(third.parent)
        XCTAssertEqual(first.presentationContext, .root)
        XCTAssertEqual(second.presentationContext, .root)
        XCTAssertEqual(third.presentationContext, .root)
    }

    func test_PresentDetourRejectsAlreadyOwnedCoordinatorWithoutMutatingState() {
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        XCTAssertTrue(mainCoordinator.navigate(to: MainTabRoute.tab2))
        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator")
            return
        }

        XCTAssertTrue(tab2.navigate(to: UnlockRoute.enterCode))
        guard let unlock = tab2.children.first(where: { $0 is UnlockCoordinator }) as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator")
            return
        }

        guard let tab5 = mainCoordinator.children[4] as? Tab5Coordinator else {
            XCTFail("Expected Tab5Coordinator at index 4")
            return
        }
        XCTAssertTrue(tab5.parent === mainCoordinator, "Precondition: Tab5 belongs to main tab coordinator")
        XCTAssertEqual(tab5.presentationContext, .tab, "Precondition: Tab5 is a tab child")

        var capturedError: SwiftUIFlowError?
        SwiftUIFlowErrorHandler.shared.setHandler { capturedError = $0 }

        unlock.presentDetour(tab5, presenting: Tab5Route.batteryStatus)

        XCTAssertNil(unlock.detourCoordinator, "Already-owned coordinator should not be presented as detour")
        XCTAssertNil(unlock.router.state.detour, "Router detour state should not be mutated")
        XCTAssertTrue(tab5.parent === mainCoordinator,
                      "Rejected detour must keep its original parent")
        XCTAssertEqual(tab5.presentationContext, .tab,
                       "Rejected detour must keep its original presentation context")
        guard case let .configurationError(message) = capturedError else {
            XCTFail("Expected configuration error")
            return
        }
        XCTAssertTrue(message.contains("already-owned coordinator"))
        XCTAssertTrue(message.contains("fresh detour coordinator"))
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

        // Present fresh detour
        let batteryDetour = makeBatteryDetour()
        unlock.presentDetour(batteryDetour, presenting: Tab5Route.batteryStatus)
        XCTAssertNotNil(unlock.detourCoordinator, "Detour should be presented")

        // Navigate to a different tab's route from within the detour
        // Battery detour can't handle MainTabRoute.tab3, so it bubbles up
        // Unlock can't handle it either, so it dismisses detour and bubbles up
        // Main coordinator switches to Tab3
        let success = batteryDetour.navigate(to: MainTabRoute.tab3)

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

        // Now present fresh detour while modal is active
        let batteryDetour = makeBatteryDetour()
        unlock.presentDetour(batteryDetour, presenting: Tab5Route.batteryStatus)

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

    private func makeBatteryDetour() -> Tab5Coordinator {
        Tab5Coordinator(router: Router(initial: .batteryStatus, factory: DummyFactory()))
    }
}

private enum NestedDetourRoute: String, Route {
    case host
    case first
    case second
    case third

    var identifier: String {
        rawValue
    }
}

private final class NestedDetourCoordinator: Coordinator<NestedDetourRoute> {
    init(root: NestedDetourRoute) {
        super.init(router: Router(initial: root, factory: DummyFactory()))
    }
}
