//
//  AdvancedNavigationIntegrationTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 28/11/25.
//

@testable import SwiftUIFlow
import XCTest

final class AdvancedNavigationIntegrationTests: XCTestCase {
    // MARK: - Pushed Child Coordinator Full Lifecycle

    // swiftlint:disable:next function_body_length
    func test_PushedChildCoordinatorCompleteLifecycle() {
        // Comprehensive test covering: add → push → navigate → pop → remove → cleanup
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        // Switch to Tab2
        XCTAssertTrue(mainCoordinator.navigate(to: MainTabRoute.tab2))

        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator")
            return
        }

        // 1. Child exists as regular child (added during Tab2 init)
        XCTAssertTrue(tab2.children.contains(where: { $0 is UnlockCoordinator }),
                      "UnlockCoordinator should be a child of Tab2")
        XCTAssertTrue(tab2.router.state.pushedChildren.isEmpty,
                      "No children should be pushed yet")

        // 2. Navigate to route that pushes child onto stack
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.enterCode))

        guard let unlock = tab2.children.first(where: { $0 is UnlockCoordinator }) as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator")
            return
        }

        // Verify child was pushed
        XCTAssertEqual(tab2.router.state.pushedChildren.count, 1,
                       "Tab2 should have 1 pushed child")
        XCTAssertTrue(tab2.router.state.pushedChildren.contains(where: { $0 === unlock }),
                      "UnlockCoordinator should be in pushedChildren")
        XCTAssertTrue(unlock.router.state.stack.isEmpty,
                      "Unlock should be at root (enterCode)")

        // 3. Navigate within pushed child (build up state)
        XCTAssertTrue(unlock.navigate(to: UnlockRoute.loading))
        XCTAssertEqual(unlock.router.state.stack.count, 1,
                       "Unlock should have 1 item in stack")
        XCTAssertEqual(unlock.router.state.stack[0], .loading)

        XCTAssertTrue(unlock.navigate(to: UnlockRoute.failure))
        XCTAssertEqual(unlock.router.state.stack.count, 2,
                       "Unlock should have 2 items in stack")
        XCTAssertEqual(unlock.router.state.currentRoute, .failure)

        // 4. Pop back within child
        unlock.pop()
        XCTAssertEqual(unlock.router.state.stack.count, 1,
                       "Should have popped back to loading")
        XCTAssertEqual(unlock.router.state.currentRoute, .loading)

        unlock.pop()
        XCTAssertTrue(unlock.router.state.stack.isEmpty,
                      "Should be back at child's root")
        XCTAssertEqual(unlock.router.state.currentRoute, .enterCode)

        // Child should still be pushed
        XCTAssertEqual(tab2.router.state.pushedChildren.count, 1,
                       "Child should still be pushed")

        // 5. Remove from pushedChildren (simulate back button which calls parent.pop())
        tab2.pop()
        XCTAssertTrue(tab2.router.state.pushedChildren.isEmpty,
                      "Tab2 pushedChildren should be empty after pop")

        // 6. Verify child is still a regular child (not removed from children array)
        XCTAssertTrue(tab2.children.contains(where: { $0 is UnlockCoordinator }),
                      "UnlockCoordinator should still be a child of Tab2")

        // 7. Verify cleanup - child's state should be cleaned
        XCTAssertTrue(unlock.router.state.stack.isEmpty,
                      "Unlock stack should still be clean")
        XCTAssertEqual(unlock.router.state.currentRoute, .enterCode,
                       "Unlock should be at its root")

        // 8. Navigate back to unlock to verify it can be pushed again
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.loading))
        XCTAssertEqual(tab2.router.state.pushedChildren.count, 1,
                       "Should be able to push child again")
        XCTAssertEqual(unlock.router.state.stack.count, 1,
                       "Should have navigated to loading")

        // Clean up for final verification - pop child's route, then pop the child
        tab2.pop() // Pops unlock's .loading route
        XCTAssertTrue(unlock.router.state.stack.isEmpty,
                      "Unlock should be back at root")
        tab2.pop() // Pops the child itself from pushedChildren
        XCTAssertTrue(tab2.router.state.pushedChildren.isEmpty,
                      "Should have cleaned up pushed child")

        // 9. Remove child completely from coordinator
        tab2.removeChild(unlock)
        XCTAssertFalse(tab2.children.contains(where: { $0 is UnlockCoordinator }),
                       "UnlockCoordinator should be removed from children")

        // 10. Verify parent state after complete removal
        XCTAssertTrue(tab2.router.state.pushedChildren.isEmpty,
                      "No pushed children after removal")
        XCTAssertTrue(tab2.router.state.stack.isEmpty,
                      "Tab2 should be at root")
        XCTAssertEqual(tab2.router.state.currentRoute, .startUnlock,
                       "Tab2 should be at its root route")
    }

    // MARK: - Pop From Pushed Child at Root

    func test_PopFromPushedChildAtRootRemovesChild() {
        // When pushed child is at root and pop() is called, should remove child from pushedChildren
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        XCTAssertTrue(mainCoordinator.navigate(to: MainTabRoute.tab2))

        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator")
            return
        }

        // Navigate to unlock flow - pushes child
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.enterCode))

        guard let unlock = tab2.router.state.pushedChildren.first as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator to be pushed")
            return
        }

        // Verify child is pushed and at root
        XCTAssertTrue(unlock.router.state.stack.isEmpty, "Unlock should be at root")
        XCTAssertEqual(tab2.router.state.pushedChildren.count, 1)

        // Navigate within child
        XCTAssertTrue(unlock.navigate(to: UnlockRoute.loading))
        XCTAssertEqual(unlock.router.state.stack.count, 1)

        // Pop back to child's root
        unlock.pop()
        XCTAssertTrue(unlock.router.state.stack.isEmpty, "Should be back at child's root")
        XCTAssertEqual(tab2.router.state.pushedChildren.count, 1, "Child should still be pushed")

        // Pop on parent (this is what back button does for pushed children via CoordinatorRouteView)
        // Should remove pushed child since it's at root (allRoutes.count == 1)
        tab2.pop()
        XCTAssertTrue(tab2.router.state.pushedChildren.isEmpty,
                      "Popping parent when child is at root should remove child from pushedChildren")

        // Child should still be a regular child
        XCTAssertTrue(tab2.children.contains(where: { $0 is UnlockCoordinator }),
                      "UnlockCoordinator should still be a child")
    }

    // MARK: - Multiple Modal Layers

    func test_NestedModals() {
        // Test modal presenting another modal (modal-from-modal)
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        XCTAssertTrue(mainCoordinator.navigate(to: MainTabRoute.tab2))

        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator")
            return
        }

        // Navigate to unlock flow
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.enterCode))

        guard let unlock = tab2.router.state.pushedChildren.first as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator to be pushed")
            return
        }

        // Navigate to success modal (first modal layer)
        XCTAssertTrue(unlock.navigate(to: UnlockRoute.success))
        XCTAssertNotNil(unlock.currentModalCoordinator, "Unlock should have modal coordinator")
        XCTAssertEqual(unlock.router.state.presented, .success)

        guard let resultModal = unlock.currentModalCoordinator as? UnlockResultCoordinator else {
            XCTFail("Expected UnlockResultCoordinator")
            return
        }

        // Create a second modal coordinator
        let secondModalRouter = Router<UnlockRoute>(initial: .failure, factory: DummyFactory())
        let secondModal = UnlockResultCoordinator(router: secondModalRouter)

        // Present second modal FROM first modal
        resultModal.presentModal(secondModal,
                                 presenting: .failure,
                                 detentConfiguration: ModalDetentConfiguration(detents: [.medium]))

        // Verify two-layer modal structure
        XCTAssertNotNil(unlock.currentModalCoordinator, "Unlock should still have first modal")
        XCTAssertTrue(unlock.currentModalCoordinator === resultModal, "First modal should be result modal")
        XCTAssertNotNil(resultModal.currentModalCoordinator, "First modal should have second modal")
        XCTAssertTrue(resultModal.currentModalCoordinator === secondModal, "Second modal should be present")
        XCTAssertEqual(resultModal.router.state.presented, .failure)

        // Dismiss second modal
        resultModal.dismissModal()
        XCTAssertNil(resultModal.currentModalCoordinator, "First modal should have no modal")
        XCTAssertNotNil(unlock.currentModalCoordinator, "Unlock should still have first modal")

        // Dismiss first modal
        unlock.dismissModal()
        XCTAssertNil(unlock.currentModalCoordinator, "Unlock should have no modal")
    }
}
