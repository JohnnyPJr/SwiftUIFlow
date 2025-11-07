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

    // MARK: - PresentationContext Integration Tests

    func test_CompleteFlowVerifiesPresentationContexts() {
        // Setup main coordinator (root)
        let mainRouter = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let mainCoordinator = TestCoordinator(router: mainRouter)

        XCTAssertEqual(mainCoordinator.presentationContext, .root,
                       "Main coordinator should have .root context")

        // Add child coordinator (pushed)
        let childRouter = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let childCoordinator = TestCoordinator(router: childRouter)
        mainCoordinator.addChild(childCoordinator)

        XCTAssertEqual(childCoordinator.presentationContext, .pushed,
                       "Child coordinator should have .pushed context")
        XCTAssertTrue(childCoordinator.parent === mainCoordinator,
                      "Child should have parent set")

        // Present modal coordinator
        let modalRouter = Router<MockRoute>(initial: .modal, factory: MockViewFactory())
        let modalCoordinator = TestCoordinator(router: modalRouter)
        mainCoordinator.presentModal(modalCoordinator, presenting: .modal)

        XCTAssertEqual(modalCoordinator.presentationContext, .modal,
                       "Modal coordinator should have .modal context")
        XCTAssertTrue(modalCoordinator.parent === mainCoordinator,
                      "Modal should have parent set")

        // Present detour coordinator
        let detourRouter = Router<MockRoute>(initial: .details, factory: MockViewFactory())
        let detourCoordinator = TestCoordinator(router: detourRouter)
        mainCoordinator.presentDetour(detourCoordinator, presenting: MockRoute.details)

        XCTAssertEqual(detourCoordinator.presentationContext, .detour,
                       "Detour coordinator should have .detour context")
        XCTAssertTrue(detourCoordinator.parent === mainCoordinator,
                      "Detour should have parent set")

        // Clean up - dismiss detour
        mainCoordinator.dismissDetour()
        XCTAssertNil(detourCoordinator.parent, "Detour parent should be cleared after dismissal")

        // Clean up - dismiss modal
        mainCoordinator.dismissModal()
        XCTAssertNil(modalCoordinator.parent, "Modal parent should be cleared after dismissal")
    }

    func test_TabCoordinatorChildrenHaveTabContext() {
        let tabRouter = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let tabCoordinator = TestTabCoordinator(router: tabRouter)

        // Add multiple tab children
        let tab1 = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))
        let tab2 = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))
        let tab3 = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))

        tabCoordinator.addChild(tab1)
        tabCoordinator.addChild(tab2)
        tabCoordinator.addChild(tab3)

        XCTAssertEqual(tab1.presentationContext, .tab, "First tab should have .tab context")
        XCTAssertEqual(tab2.presentationContext, .tab, "Second tab should have .tab context")
        XCTAssertEqual(tab3.presentationContext, .tab, "Third tab should have .tab context")

        // Verify parent relationships
        XCTAssertTrue(tab1.parent === tabCoordinator, "Tab1 parent should be tab coordinator")
        XCTAssertTrue(tab2.parent === tabCoordinator, "Tab2 parent should be tab coordinator")
        XCTAssertTrue(tab3.parent === tabCoordinator, "Tab3 parent should be tab coordinator")
    }

    func test_NestedCoordinatorContextPropagation() {
        // Root tab coordinator
        let tabRouter = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let tabCoordinator = TestTabCoordinator(router: tabRouter)

        // Tab child (should be .tab)
        let tab1Router = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let tab1Coordinator = TestCoordinator(router: tab1Router)
        tabCoordinator.addChild(tab1Coordinator)

        XCTAssertEqual(tab1Coordinator.presentationContext, .tab,
                       "Tab child should have .tab context")

        // Modal presented from tab (should be .modal)
        let modalRouter = Router<MockRoute>(initial: .modal, factory: MockViewFactory())
        let modalCoordinator = TestCoordinator(router: modalRouter)
        tab1Coordinator.presentModal(modalCoordinator, presenting: .modal)

        XCTAssertEqual(modalCoordinator.presentationContext, .modal,
                       "Modal from tab should have .modal context")

        // Detour presented from modal (should be .detour)
        let detourRouter = Router<MockRoute>(initial: .details, factory: MockViewFactory())
        let detourCoordinator = TestCoordinator(router: detourRouter)
        modalCoordinator.presentDetour(detourCoordinator, presenting: MockRoute.details)

        XCTAssertEqual(detourCoordinator.presentationContext, .detour,
                       "Detour from modal should have .detour context")

        // Verify the entire hierarchy
        XCTAssertTrue(tab1Coordinator.parent === tabCoordinator,
                      "Tab parent should be tab coordinator")
        XCTAssertTrue(modalCoordinator.parent === tab1Coordinator,
                      "Modal parent should be tab coordinator")
        XCTAssertTrue(detourCoordinator.parent === modalCoordinator,
                      "Detour parent should be modal coordinator")
    }
}
