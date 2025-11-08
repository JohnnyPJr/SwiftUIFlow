//
//  CoordinatorPresentationTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 5/11/25.
//

@testable import SwiftUIFlow
import XCTest

final class CoordinatorPresentationTests: XCTestCase {
    // MARK: - Modal Handling

    func test_CanPresentAndDismissModalCoordinator() {
        let sut = makeSUT()
        let modal = Coordinator(router: sut.router)
        trackForMemoryLeaks(modal)

        sut.coordinator.presentModal(modal, presenting: .home)
        XCTAssertTrue(sut.coordinator.currentModalCoordinator === modal)

        sut.coordinator.dismissModal()
        XCTAssertNil(sut.coordinator.currentModalCoordinator)
    }

    func test_NavigateDismissesModalWhenModalCantHandle() {
        let sut = makeSUT()
        let modalRouter = Router<MockRoute>(initial: .modal, factory: MockViewFactory())
        let modal = TestModalThatCantHandle(router: modalRouter)
        trackForMemoryLeaks(modal)

        // Present modal (handles both coordinator and router state)
        sut.coordinator.presentModal(modal, presenting: .modal)
        XCTAssertNotNil(sut.coordinator.currentModalCoordinator)
        XCTAssertNotNil(sut.router.state.presented)

        // Navigate to route that modal can't handle
        let handled = sut.coordinator.navigate(to: MockRoute.details)

        XCTAssertTrue(handled)
        XCTAssertNil(sut.coordinator.currentModalCoordinator, "Modal should be dismissed")
        XCTAssertNil(sut.router.state.presented, "Router should have dismissed modal")
        XCTAssertEqual(sut.router.state.currentRoute,
                       MockRoute.details, "Expected to be at details route after dismissing modal")
    }

    // MARK: - CoordinatorPresentationContext Tests

    func test_PresentationContext_RootAndTabDoNotShowBackButton() {
        XCTAssertFalse(CoordinatorPresentationContext.root.shouldShowBackButton,
                       "Root context should not show back button")
        XCTAssertFalse(CoordinatorPresentationContext.tab.shouldShowBackButton,
                       "Tab context should not show back button")
    }

    func test_PresentationContext_PushedModalAndDetourShowBackButton() {
        XCTAssertTrue(CoordinatorPresentationContext.pushed.shouldShowBackButton,
                      "Pushed context should show back button")
        XCTAssertTrue(CoordinatorPresentationContext.modal.shouldShowBackButton,
                      "Modal context should show back button")
        XCTAssertTrue(CoordinatorPresentationContext.detour.shouldShowBackButton,
                      "Detour context should show back button")
    }

    func test_CoordinatorDefaultsToRootContext() {
        let sut = makeSUT()

        XCTAssertEqual(sut.coordinator.presentationContext, .root,
                       "New coordinator should default to root context")
    }

    func test_AddChildSetsContextToPushedByDefault() {
        let sut = makeSUT()
        let childRouter = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let child = TestCoordinator(router: childRouter)

        sut.coordinator.addChild(child)

        XCTAssertEqual(child.presentationContext, .pushed,
                       "Child added without explicit context should be .pushed")
    }

    func test_AddChildCanExplicitlySetContext() {
        let sut = makeSUT()
        let childRouter = Router<MockRoute>(initial: .home, factory: MockViewFactory())
        let child = TestCoordinator(router: childRouter)

        sut.coordinator.addChild(child, context: .tab)

        XCTAssertEqual(child.presentationContext, .tab,
                       "Child should have explicitly set context")
    }

    func test_PresentModalSetsModalContext() {
        let sut = makeSUT()
        let modalRouter = Router<MockRoute>(initial: .modal, factory: MockViewFactory())
        let modal = TestCoordinator(router: modalRouter)

        sut.coordinator.presentModal(modal, presenting: .modal)

        XCTAssertEqual(modal.presentationContext, .modal,
                       "Presented modal should have .modal context")
        XCTAssertTrue(modal.parent === sut.coordinator,
                      "Modal parent should be set")
    }

    func test_PresentDetourSetsDetourContext() {
        let sut = makeSUT()
        let detourRouter = Router<MockRoute>(initial: .details, factory: MockViewFactory())
        let detour = TestCoordinator(router: detourRouter)

        sut.coordinator.presentDetour(detour, presenting: MockRoute.details)

        XCTAssertEqual(detour.presentationContext, .detour,
                       "Presented detour should have .detour context")
        XCTAssertTrue(detour.parent === sut.coordinator,
                      "Detour parent should be set")
    }

    // MARK: - Detour Tests

    func test_PresentAndDismissDetour() {
        let sut = makeSUT()
        let detourRouter = Router<MockRoute>(initial: .details, factory: MockViewFactory())
        let detourCoordinator = TestCoordinator(router: detourRouter)

        sut.coordinator.presentDetour(detourCoordinator, presenting: MockRoute.details)

        XCTAssertTrue(sut.coordinator.detourCoordinator === detourCoordinator, "Detour coordinator should be presented")
        XCTAssertTrue(detourCoordinator.parent === sut.coordinator, "Parent should be set")
        XCTAssertEqual(sut.router.state.detour?.identifier, MockRoute.details.identifier,
                       "Detour route should be in state")

        sut.coordinator.dismissDetour()

        XCTAssertNil(sut.coordinator.detourCoordinator, "Detour coordinator should be dismissed")
        XCTAssertNil(detourCoordinator.parent, "Parent should be cleared")
        XCTAssertNil(sut.router.state.detour, "Detour route should be cleared from state")
    }

    func test_ResetToCleanStateDismissesDetour() {
        let sut = makeSUT()
        let detourRouter = Router<MockRoute>(initial: .details, factory: MockViewFactory())
        let detourCoordinator = TestCoordinator(router: detourRouter)

        sut.router.push(.details)
        sut.router.present(.modal)
        sut.coordinator.presentDetour(detourCoordinator, presenting: MockRoute.login)

        sut.coordinator.resetToCleanState()

        XCTAssertTrue(sut.router.state.stack.isEmpty, "Stack should be empty after reset")
        XCTAssertNil(sut.router.state.presented, "Modal should be dismissed after reset")
        XCTAssertNil(sut.router.state.detour, "Detour should be dismissed after reset")
        XCTAssertNil(sut.coordinator.detourCoordinator, "Detour coordinator should be dismissed after reset")
    }

    // MARK: - Modal Navigation Stack Tests

    func test_ModalCanPushRoutes() {
        let sut = makeSUT()
        let modalRouter = Router<MockRoute>(initial: .modal, factory: MockViewFactory())
        let modal = TestCoordinator(router: modalRouter)
        trackForMemoryLeaks(modal)

        // Present modal
        sut.coordinator.presentModal(modal, presenting: .modal)

        // Modal should have empty stack initially
        XCTAssertTrue(modal.router.state.stack.isEmpty, "Modal should start with empty stack")

        // Push within modal
        modal.router.push(.details)

        // Verify push succeeded
        XCTAssertEqual(modal.router.state.stack.count, 1, "Modal should have 1 item in stack")
        XCTAssertEqual(modal.router.state.stack.first, .details, "Details should be in modal stack")
    }

    func test_ModalCanPopRoutes() {
        let sut = makeSUT()
        let modalRouter = Router<MockRoute>(initial: .modal, factory: MockViewFactory())
        let modal = TestCoordinator(router: modalRouter)
        trackForMemoryLeaks(modal)

        // Present modal and push a route
        sut.coordinator.presentModal(modal, presenting: .modal)
        modal.router.push(.details)

        XCTAssertEqual(modal.router.state.stack.count, 1, "Modal should have 1 item in stack")

        // Pop within modal
        modal.pop()

        // Verify pop succeeded
        XCTAssertTrue(modal.router.state.stack.isEmpty, "Modal stack should be empty after pop")
        XCTAssertNotNil(sut.coordinator.currentModalCoordinator, "Modal should still be presented")
    }

    func test_PopAtModalRootDismissesModal() {
        let sut = makeSUT()
        let modalRouter = Router<MockRoute>(initial: .modal, factory: MockViewFactory())
        let modal = TestCoordinator(router: modalRouter)
        trackForMemoryLeaks(modal)

        // Present modal
        sut.coordinator.presentModal(modal, presenting: .modal)

        XCTAssertTrue(modal.router.state.stack.isEmpty, "Modal should start with empty stack")
        XCTAssertNotNil(sut.coordinator.currentModalCoordinator, "Modal should be presented")

        // Pop at root (should dismiss modal)
        modal.pop()

        // Verify modal was dismissed
        XCTAssertNil(sut.coordinator.currentModalCoordinator, "Modal should be dismissed after pop at root")
        XCTAssertNil(sut.router.state.presented, "Router should have cleared presented route")
    }

    func test_PopAtDetourRootDismissesDetour() {
        let sut = makeSUT()
        let detourRouter = Router<MockRoute>(initial: .details, factory: MockViewFactory())
        let detour = TestCoordinator(router: detourRouter)
        trackForMemoryLeaks(detour)

        // Present detour
        sut.coordinator.presentDetour(detour, presenting: MockRoute.details)

        XCTAssertTrue(detour.router.state.stack.isEmpty, "Detour should start with empty stack")
        XCTAssertNotNil(sut.coordinator.detourCoordinator, "Detour should be presented")

        // Pop at root (should dismiss detour)
        detour.pop()

        // Verify detour was dismissed
        XCTAssertNil(sut.coordinator.detourCoordinator, "Detour should be dismissed after pop at root")
        XCTAssertNil(sut.router.state.detour, "Router should have cleared detour route")
    }

    func test_DetourCanPushAndPopRoutes() {
        let sut = makeSUT()
        let detourRouter = Router<MockRoute>(initial: .details, factory: MockViewFactory())
        let detour = TestCoordinator(router: detourRouter)
        trackForMemoryLeaks(detour)

        // Present detour
        sut.coordinator.presentDetour(detour, presenting: MockRoute.details)

        // Push within detour
        detour.router.push(.modal)

        // Verify push succeeded
        XCTAssertEqual(detour.router.state.stack.count, 1, "Detour should have 1 item in stack")
        XCTAssertEqual(detour.router.state.stack.first, .modal, "Modal should be in detour stack")

        // Pop within detour
        detour.pop()

        // Verify pop succeeded
        XCTAssertTrue(detour.router.state.stack.isEmpty, "Detour stack should be empty after pop")
        XCTAssertNotNil(sut.coordinator.detourCoordinator, "Detour should still be presented")
    }
}
