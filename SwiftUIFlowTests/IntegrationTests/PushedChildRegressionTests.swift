//
//  PushedChildRegressionTests.swift
//  SwiftUIFlowTests
//
//  Regression tests for bugs related to pushed child coordinators
//  These tests ensure bugs that were discovered during development stay fixed.
//

import SwiftUI
@testable import SwiftUIFlow
import XCTest

/// Regression tests for pushed child coordinator bugs
/// These tests catch specific scenarios that previously caused bugs
@MainActor
final class PushedChildRegressionTests: XCTestCase {
    // MARK: - Recursive Pushed Child Flattening

    func test_Flattening_EmptyPushedChildren_ReturnsEmptyRoutes() {
        XCTAssertTrue(PushedChildRouteFlattener.routes(from: []).isEmpty)
        XCTAssertTrue(PushedChildRouteFlattener.coordinators(from: []).isEmpty)
    }

    func test_Flattening_IncludesGrandchildRoutesInVisibleNavigationOrder() {
        let grandchild = RegressionGrandchildCoordinator()
        let child = RegressionChildCoordinator(grandchild: grandchild)
        let parent = RegressionParentCoordinator(child: child)

        XCTAssertTrue(parent.navigate(to: RegressionGrandchildRoute.destination))

        let flattenedRoutes = PushedChildRouteFlattener.routes(from: parent.router.state.pushedChildren)

        XCTAssertEqual(flattenedRoutes.map(\.route.identifier),
                       [RegressionChildRoute.root.identifier,
                        RegressionGrandchildRoute.root.identifier,
                        RegressionGrandchildRoute.destination.identifier])
        XCTAssertTrue(flattenedRoutes[0].coordinator === child)
        XCTAssertTrue(flattenedRoutes[1].coordinator === grandchild)
        XCTAssertTrue(flattenedRoutes[2].coordinator === grandchild)
    }

    func test_Flattening_PreservesSiblingOrderWithNestedChildren() {
        let grandchild = RegressionGrandchildCoordinator()
        let firstChild = RegressionChildCoordinator(grandchild: grandchild)
        let secondChild = RegressionSecondChildCoordinator()
        let parent = RegressionParentCoordinator(firstChild: firstChild, secondChild: secondChild)

        XCTAssertTrue(parent.navigate(to: RegressionGrandchildRoute.destination))
        XCTAssertTrue(parent.navigate(to: RegressionSecondChildRoute.root))

        let flattenedRoutes = PushedChildRouteFlattener.routes(from: parent.router.state.pushedChildren)

        XCTAssertEqual(flattenedRoutes.map(\.route.identifier),
                       [RegressionChildRoute.root.identifier,
                        RegressionGrandchildRoute.root.identifier,
                        RegressionGrandchildRoute.destination.identifier,
                        RegressionSecondChildRoute.root.identifier])
        XCTAssertTrue(flattenedRoutes[0].coordinator === firstChild)
        XCTAssertTrue(flattenedRoutes[1].coordinator === grandchild)
        XCTAssertTrue(flattenedRoutes[2].coordinator === grandchild)
        XCTAssertTrue(flattenedRoutes[3].coordinator === secondChild)
    }

    func test_RouteChange_UpdatesFlattenedRoutesWithoutChangingCoordinatorMembership() {
        let grandchild = RegressionGrandchildCoordinator()
        let child = RegressionChildCoordinator(grandchild: grandchild)
        let parent = RegressionParentCoordinator(child: child)

        XCTAssertTrue(parent.navigate(to: RegressionGrandchildRoute.root))

        let initialCoordinatorIDs = PushedChildRouteFlattener
            .coordinators(from: parent.router.state.pushedChildren)
            .map(ObjectIdentifier.init)

        XCTAssertTrue(grandchild.navigate(to: RegressionGrandchildRoute.destination))

        let updatedCoordinatorIDs = PushedChildRouteFlattener
            .coordinators(from: parent.router.state.pushedChildren)
            .map(ObjectIdentifier.init)
        let flattenedRoutes = PushedChildRouteFlattener.routes(from: parent.router.state.pushedChildren)

        XCTAssertEqual(updatedCoordinatorIDs, initialCoordinatorIDs)
        XCTAssertEqual(flattenedRoutes.map(\.route.identifier),
                       [RegressionChildRoute.root.identifier,
                        RegressionGrandchildRoute.root.identifier,
                        RegressionGrandchildRoute.destination.identifier])
    }

    func test_PushChild_EmitsRoutesDidChangeWithPushedChildPayload() {
        let grandchild = RegressionGrandchildCoordinator()
        let child = RegressionChildCoordinator(grandchild: grandchild)
        var emittedRoutes: [[String]] = []

        let cancellable = child.routesDidChange.sink { routes in
            emittedRoutes.append(routes.map(\.identifier))
        }

        XCTAssertTrue(child.navigate(to: RegressionGrandchildRoute.destination))

        XCTAssertEqual(emittedRoutes, [[RegressionChildRoute.root.identifier]])

        cancellable.cancel()
    }

    func test_PopChild_EmitsRoutesDidChangeAndShrinksFlattenedRoutes() {
        let grandchild = RegressionGrandchildCoordinator()
        let child = RegressionChildCoordinator(grandchild: grandchild)
        let parent = RegressionParentCoordinator(child: child)

        XCTAssertTrue(parent.navigate(to: RegressionChildRoute.root))

        var emittedRoutes: [[String]] = []
        let cancellable = parent.routesDidChange.sink { routes in
            emittedRoutes.append(routes.map(\.identifier))
        }

        parent.pop()

        XCTAssertEqual(emittedRoutes, [[RegressionParentRoute.root.identifier]])
        XCTAssertTrue(parent.router.state.pushedChildren.isEmpty)
        XCTAssertTrue(PushedChildRouteFlattener.routes(from: parent.router.state.pushedChildren).isEmpty)

        cancellable.cancel()
    }

    func test_Pop_FromPushedGrandchildAtRoot_RemovesOnlyGrandchild() {
        let grandchild = RegressionGrandchildCoordinator()
        let child = RegressionChildCoordinator(grandchild: grandchild)
        let parent = RegressionParentCoordinator(child: child)

        XCTAssertTrue(parent.navigate(to: RegressionGrandchildRoute.root))
        XCTAssertTrue(parent.router.state.pushedChildren.contains(where: { $0 === child }))
        XCTAssertTrue(child.router.state.pushedChildren.contains(where: { $0 === grandchild }))

        parent.pop()

        XCTAssertTrue(parent.router.state.pushedChildren.contains(where: { $0 === child }))
        XCTAssertTrue(child.router.state.pushedChildren.isEmpty)

        let flattenedRoutes = PushedChildRouteFlattener.routes(from: parent.router.state.pushedChildren)
        XCTAssertEqual(flattenedRoutes.map(\.route.identifier), [RegressionChildRoute.root.identifier])
    }

    func test_Pop_PushedChildWithOwnStackAndGrandchild_PopsGrandchildBeforeOwnStack() {
        let grandchild = RegressionGrandchildCoordinator()
        let child = RegressionChildCoordinator(grandchild: grandchild)
        let parent = RegressionParentCoordinator(child: child)

        XCTAssertTrue(parent.navigate(to: RegressionChildRoute.root))
        XCTAssertTrue(child.navigate(to: RegressionChildRoute.detail))
        XCTAssertTrue(child.navigate(to: RegressionGrandchildRoute.root))

        parent.pop()

        XCTAssertTrue(parent.router.state.pushedChildren.contains(where: { $0 === child }))
        XCTAssertTrue(child.router.state.pushedChildren.isEmpty)
        XCTAssertEqual(child.router.state.stack, [.detail])

        parent.pop()

        XCTAssertTrue(parent.router.state.pushedChildren.contains(where: { $0 === child }))
        XCTAssertTrue(child.router.state.stack.isEmpty)

        let flattenedRoutes = PushedChildRouteFlattener.routes(from: parent.router.state.pushedChildren)
        XCTAssertEqual(flattenedRoutes.map(\.route.identifier), [RegressionChildRoute.root.identifier])
    }

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
        XCTAssertNil(unlock.parent, "Removed pushed child should not retain parent")
        XCTAssertEqual(unlock.presentationContext, .root,
                       "Removed pushed child should reset to root context")
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

        // Bubbling cleanup is render-state only. The parent chain must remain intact until
        // the in-flight bubble reaches the coordinator that can handle the route.
        XCTAssertTrue(unlock.parent === tab2,
                      "Bubbling cleanup should preserve the in-flight parent chain")
        XCTAssertEqual(unlock.presentationContext, .pushed,
                       "Bubbling cleanup should preserve the in-flight presentation context")

        // Verify we successfully switched to tab3
        XCTAssertEqual(mainCoordinator.router.state.selectedTab, 2)
    }
}

private enum RegressionParentRoute: Route {
    case root

    var identifier: String {
        "regression.parent.root"
    }
}

private enum RegressionChildRoute: Route {
    case root
    case detail

    var identifier: String {
        switch self {
        case .root: return "regression.child.root"
        case .detail: return "regression.child.detail"
        }
    }
}

private enum RegressionSecondChildRoute: Route {
    case root

    var identifier: String {
        "regression.secondChild.root"
    }
}

private enum RegressionGrandchildRoute: Route {
    case root
    case destination

    var identifier: String {
        switch self {
        case .root: return "regression.grandchild.root"
        case .destination: return "regression.grandchild.destination"
        }
    }
}

private final class RegressionParentCoordinator: Coordinator<RegressionParentRoute> {
    init(child: RegressionChildCoordinator) {
        let factory = RegressionFactory<RegressionParentRoute>()
        super.init(router: Router(initial: .root, factory: factory))
        factory.coordinator = self
        addChild(child)
    }

    init(firstChild: RegressionChildCoordinator, secondChild: RegressionSecondChildCoordinator) {
        let factory = RegressionFactory<RegressionParentRoute>()
        super.init(router: Router(initial: .root, factory: factory))
        factory.coordinator = self
        addChild(firstChild)
        addChild(secondChild)
    }

    override func canHandle(_ route: any Route) -> Bool {
        route is RegressionParentRoute
    }
}

private final class RegressionChildCoordinator: Coordinator<RegressionChildRoute> {
    init(grandchild: RegressionGrandchildCoordinator) {
        let factory = RegressionFactory<RegressionChildRoute>()
        super.init(router: Router(initial: .root, factory: factory))
        factory.coordinator = self
        addChild(grandchild)
    }

    override func canHandle(_ route: any Route) -> Bool {
        route is RegressionChildRoute
    }
}

private final class RegressionSecondChildCoordinator: Coordinator<RegressionSecondChildRoute> {
    init() {
        let factory = RegressionFactory<RegressionSecondChildRoute>()
        super.init(router: Router(initial: .root, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        route is RegressionSecondChildRoute
    }
}

private final class RegressionGrandchildCoordinator: Coordinator<RegressionGrandchildRoute> {
    init() {
        let factory = RegressionFactory<RegressionGrandchildRoute>()
        super.init(router: Router(initial: .root, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        route is RegressionGrandchildRoute
    }
}

private final class RegressionFactory<R: Route>: ViewFactory<R> {
    override func buildView(for route: R) -> AnyView? {
        AnyView(Text(route.identifier))
    }
}
