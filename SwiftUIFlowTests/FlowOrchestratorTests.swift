//
//  FlowOrchestratorTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 5/11/25.
//

import SwiftUI
@testable import SwiftUIFlow
import XCTest

final class FlowOrchestratorTests: XCTestCase {
    // MARK: - Basic Functionality

    func test_TransitionToFlow_CreatesAndInstallsCoordinator() {
        let orchestrator = TestFlowOrchestrator()

        orchestrator.transitionToFlow(TestFlowCoordinator(), root: .flow1)

        XCTAssertNotNil(orchestrator.currentFlow, "Should have a current flow")
        XCTAssertTrue(orchestrator.currentFlow is TestFlowCoordinator,
                      "Current flow should be TestFlowCoordinator")
        XCTAssertEqual(orchestrator.children.count, 1, "Should have one child")
        XCTAssertTrue(orchestrator.children.first === orchestrator.currentFlow,
                      "Child should be the current flow")
    }

    func test_TransitionToFlow_TransitionsToNewRoot() {
        let orchestrator = TestFlowOrchestrator()

        orchestrator.transitionToFlow(TestFlowCoordinator(), root: .flow1)

        XCTAssertEqual(orchestrator.router.state.root, .flow1, "Should transition to new root")
    }

    func test_TransitionToFlow_SetsParentRelationship() {
        let orchestrator = TestFlowOrchestrator()

        orchestrator.transitionToFlow(TestFlowCoordinator(), root: .flow1)

        XCTAssertTrue(orchestrator.currentFlow?.parent === orchestrator,
                      "Current flow's parent should be orchestrator")
    }

    // MARK: - Flow Cleanup

    func test_TransitionToFlow_DeallocatesPreviousFlow() {
        let orchestrator = TestFlowOrchestrator()

        let firstFlow = TestFlowCoordinator()
        trackForMemoryLeaks(firstFlow)

        orchestrator.transitionToFlow(firstFlow, root: .flow1)
        orchestrator.transitionToFlow(TestFlowCoordinator(), root: .flow2)

        XCTAssertNotNil(orchestrator.currentFlow, "Should have new current flow")
    }

    func test_TransitionToFlow_RemovesPreviousFlowFromChildren() {
        let orchestrator = TestFlowOrchestrator()

        let firstFlow = TestFlowCoordinator()
        trackForMemoryLeaks(firstFlow)

        orchestrator.transitionToFlow(firstFlow, root: .flow1)
        orchestrator.transitionToFlow(TestFlowCoordinator(), root: .flow2)

        XCTAssertFalse(orchestrator.children.contains(where: { $0 === firstFlow }),
                       "First flow should be removed from children")
        XCTAssertEqual(orchestrator.children.count, 1, "Should have only one child")
    }

    func test_TransitionToFlow_ClearsPreviousFlowParentReference() {
        let orchestrator = TestFlowOrchestrator()

        let firstFlow = TestFlowCoordinator()
        trackForMemoryLeaks(firstFlow)

        orchestrator.transitionToFlow(firstFlow, root: .flow1)
        orchestrator.transitionToFlow(TestFlowCoordinator(), root: .flow2)

        XCTAssertNil(firstFlow.parent, "First flow's parent should be cleared")
    }

    // MARK: - Integration with handleFlowChange

    func test_FlowOrchestrator_WorksWithHandleFlowChange() {
        let orchestrator = TestFlowOrchestratorWithFlowChange()

        // Navigate to flow2 (should trigger handleFlowChange)
        let handled = orchestrator.navigate(to: FlowRoute.flow2)

        XCTAssertTrue(handled, "Navigation should succeed")
        XCTAssertEqual(orchestrator.router.state.root, .flow2, "Should be at flow2")
        XCTAssertNotNil(orchestrator.currentFlow, "Should have current flow")
    }

    // MARK: - Coordinator Installation

    func test_TransitionToFlow_UsesProvidedCoordinator() {
        let orchestrator = TestFlowOrchestrator()
        let specificCoordinator = TestFlowCoordinator()

        orchestrator.transitionToFlow(specificCoordinator, root: .flow1)

        XCTAssertTrue(orchestrator.currentFlow === specificCoordinator,
                      "Should use the provided coordinator instance")
    }
}
