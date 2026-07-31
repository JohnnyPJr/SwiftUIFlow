//
//  TabCoordinatorTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 5/11/25.
//

@testable import SwiftUIFlow
import XCTest

@MainActor
final class TabCoordinatorTests: XCTestCase {
    // MARK: - Tab Context

    func test_TabCoordinatorAutomaticallySetsTabContext() {
        let tabRouter = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let tabCoordinator = TestTabCoordinator(router: tabRouter)

        let tab1Child = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))

        tabCoordinator.addChild(tab1Child)

        XCTAssertEqual(tab1Child.presentationContext, .tab,
                       "TabCoordinator should automatically set .tab context for children")
    }

    func test_TabCoordinatorCanOverrideContextExplicitly() {
        let tabRouter = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let tabCoordinator = TestTabCoordinator(router: tabRouter)

        let child = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))

        // Explicitly override with .pushed (unusual but should work)
        tabCoordinator.addChild(child, context: .pushed)

        XCTAssertEqual(child.presentationContext, .pushed,
                       "TabCoordinator should respect explicit context override")
    }

    func test_RemoveChild_FromTabCoordinator_ResetsPresentationContext() {
        let tabRouter = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let tabCoordinator = TestTabCoordinator(router: tabRouter)
        let child = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))

        tabCoordinator.addChild(child)
        XCTAssertTrue(child.parent === tabCoordinator)
        XCTAssertEqual(child.presentationContext, .tab)

        tabCoordinator.removeChild(child)

        XCTAssertNil(child.parent)
        XCTAssertEqual(child.presentationContext, .root,
                       "Removed tab child should reset to root presentation context")
    }

    // MARK: - Tab Management

    func test_TabCoordinatorCanIdentifyTabForChild() {
        let tabRouter = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let tabCoordinator = TestTabCoordinator(router: tabRouter)

        let tab1Child = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))
        let tab2Child = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))

        tabCoordinator.addChild(tab1Child)
        tabCoordinator.addChild(tab2Child)

        XCTAssertEqual(tabCoordinator.getTabIndex(for: tab1Child), 0, "First child should be tab index 0")
        XCTAssertEqual(tabCoordinator.getTabIndex(for: tab2Child), 1, "Second child should be tab index 1")
    }

    func test_TabCoordinatorCanSwitchTabs() {
        let tabRouter = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let tabCoordinator = TestTabCoordinator(router: tabRouter)

        // Add children so we have valid tabs to switch to
        let tab1Child = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))
        let tab2Child = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))
        let tab3Child = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))

        tabCoordinator.addChild(tab1Child)
        tabCoordinator.addChild(tab2Child)
        tabCoordinator.addChild(tab3Child)

        tabCoordinator.switchToTab(2)

        XCTAssertEqual(tabRouter.state.selectedTab, 2, "Tab coordinator should switch tabs using router")
    }

    // MARK: - Tab-Owned Modal/Detour Interception (Issue 2)
    //
    // When a TabCoordinator directly owns an active modal/detour and navigation
    // targets a route handled by a tab child, the base navigation cascade requires
    // the modal/detour to receive the route FIRST:
    //   - If it can handle the route, it handles it (no tab switch).
    //   - If it cannot, it is dismissed BEFORE navigation continues to the tabs.
    // TabCoordinator overrode navigate()/validation and dropped these stages, so the
    // tab switched underneath a still-presented modal/detour.

    /// Builds a tab coordinator whose current tab (index 0) can't handle the target
    /// route, while another tab (index 1) can — forcing a cross-tab switch.
    private func makeCrossTabSUT() -> (tab: TestTabCoordinator, router: Router<MainTabRoute>) {
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let tab = TestTabCoordinator(router: router)

        // Tab 0: handles nothing → route must move past it.
        let tab0 = TabChildThatCantHandle(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))
        // Tab 1: handles .details → forces the switch to index 1.
        let tab1 = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))

        tab.addChild(tab0)
        tab.addChild(tab1)
        return (tab, router)
    }

    // MARK: Modal — cannot handle → dismiss before tab switch

    func test_Navigate_TabOwnedModal_CannotHandleChildRoute_DismissesModalBeforeTabSwitch() {
        let (tab, router) = makeCrossTabSUT()

        // Tab-owned modal (tab's own route type) that cannot handle .details.
        let modal = TabPresentationThatCantHandle(router: Router<MainTabRoute>(initial: .tab1, factory: DummyFactory()))
        tab.addModalCoordinator(modal)
        tab.presentModal(modal,
                         presenting: .tab1,
                         detentConfiguration: ModalDetentConfiguration(detents: [.large]))
        XCTAssertNotNil(tab.currentModalCoordinator, "Precondition: tab owns an active modal")

        let handled = tab.navigate(to: MockRoute.details)

        XCTAssertTrue(handled, "Navigation should ultimately succeed via the destination tab")
        XCTAssertNil(tab.currentModalCoordinator,
                     "Modal that can't handle the route must be dismissed before tab navigation")
        XCTAssertNil(router.state.presented,
                     "Router presented state must be cleared when the modal is dismissed")
        XCTAssertEqual(router.state.selectedTab, 1, "Navigation should switch to the tab that handles .details")
    }

    // MARK: Detour — cannot handle → dismiss before tab switch

    func test_Navigate_TabOwnedDetour_CannotHandleChildRoute_DismissesDetourBeforeTabSwitch() {
        let (tab, router) = makeCrossTabSUT()

        // Tab-owned detour (tab's own route type) that cannot handle .details.
        let detourRouter = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let detour = TabPresentationThatCantHandle(router: detourRouter)
        tab.presentDetour(detour, presenting: MainTabRoute.tab1)
        XCTAssertNotNil(tab.detourCoordinator, "Precondition: tab owns an active detour")

        let handled = tab.navigate(to: MockRoute.details)

        XCTAssertTrue(handled, "Navigation should ultimately succeed via the destination tab")
        XCTAssertNil(tab.detourCoordinator,
                     "Detour that can't handle the route must be dismissed before tab navigation")
        XCTAssertNil(router.state.detour,
                     "Router detour state must be cleared when the detour is dismissed")
        XCTAssertEqual(router.state.selectedTab, 1, "Navigation should switch to the tab that handles .details")
    }

    // MARK: Modal — can handle → handle before tabs (no switch)

    func test_Navigate_TabOwnedModal_CanHandleRoute_HandlesBeforeTabs() {
        let (tab, router) = makeCrossTabSUT()

        // Tab-owned modal (tab's own route type) that CAN handle .details.
        let modalRouter = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let modal = TabPresentationThatHandlesDetails(router: modalRouter)
        tab.addModalCoordinator(modal)
        tab.presentModal(modal,
                         presenting: .tab1,
                         detentConfiguration: ModalDetentConfiguration(detents: [.large]))
        XCTAssertNotNil(tab.currentModalCoordinator, "Precondition: tab owns an active modal")

        let handled = tab.navigate(to: MockRoute.details)

        XCTAssertTrue(handled, "Navigation should be handled by the modal")
        XCTAssertTrue(tab.currentModalCoordinator === modal,
                      "Modal that can handle the route must keep it — not be dismissed")
        XCTAssertEqual(router.state.selectedTab, 0,
                       "No tab switch should occur when the modal handles the route")
        XCTAssertEqual(modal.detailsChild.router.state.currentRoute, .details,
                       "Modal should route to its child instead of only staying presented")
    }

    // MARK: Detour — can handle → handle before tabs (no switch)

    func test_Navigate_TabOwnedDetour_CanHandleRoute_HandlesBeforeTabs() {
        let (tab, router) = makeCrossTabSUT()

        // Tab-owned detour (tab's own route type) that CAN handle .details.
        let detourRouter = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let detour = TabPresentationThatHandlesDetails(router: detourRouter)
        tab.presentDetour(detour, presenting: MainTabRoute.tab1)
        XCTAssertNotNil(tab.detourCoordinator, "Precondition: tab owns an active detour")

        let handled = tab.navigate(to: MockRoute.details)

        XCTAssertTrue(handled, "Navigation should be handled by the detour")
        XCTAssertTrue(tab.detourCoordinator === detour,
                      "Detour that can handle the route must keep it — not be dismissed")
        XCTAssertEqual(router.state.selectedTab, 0,
                       "No tab switch should occur when the detour handles the route")
        XCTAssertEqual(detour.detailsChild.router.state.currentRoute, .details,
                       "Detour should route to its child instead of only staying presented")
    }
}

// MARK: - Test Doubles (Issue 2)

/// A tab child that handles no routes, forcing navigation to move past its tab.
private final class TabChildThatCantHandle: Coordinator<MockRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        return false
    }
}

/// A tab-owned modal/detour (typed to the tab's own route) that handles no routes,
/// so it must be dismissed when navigation targets a route it can't handle.
private final class TabPresentationThatCantHandle: Coordinator<MainTabRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        return false
    }
}

/// A tab-owned modal/detour (typed to the tab's own route) that CAN reach the
/// cross-type destination `MockRoute.details` by delegating to a child coordinator
/// — mirroring how a real modal handles a descendant's route. It should therefore
/// keep the route (handled in-place) instead of being dismissed for a tab switch.
private final class TabPresentationThatHandlesDetails: Coordinator<MainTabRoute> {
    let detailsChild = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))

    override init(router: Router<MainTabRoute>) {
        super.init(router: router)
        // A child that actually handles/executes MockRoute.details.
        addChild(detailsChild)
    }

    override func canHandle(_ route: any Route) -> Bool {
        // Doesn't handle directly — delegates to the child (which handles .details).
        return false
    }
}
