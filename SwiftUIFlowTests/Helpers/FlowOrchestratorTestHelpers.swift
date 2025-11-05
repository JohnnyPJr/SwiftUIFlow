//
//  FlowOrchestratorTestHelpers.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 5/11/25.
//

import SwiftUI
@testable import SwiftUIFlow

// MARK: - Test Routes

enum FlowRoute: Route {
    case flow1
    case flow2

    var identifier: String {
        switch self {
        case .flow1: return "flow1"
        case .flow2: return "flow2"
        }
    }
}

// MARK: - Test View Factory

class FlowRouteViewFactory: ViewFactory<FlowRoute> {
    override func buildView(for route: FlowRoute) -> AnyView? {
        return nil
    }
}

// MARK: - Test Coordinators

class TestFlowOrchestrator: FlowOrchestrator<FlowRoute> {
    init() {
        let router = Router<FlowRoute>(initial: .flow1, factory: FlowRouteViewFactory())
        super.init(router: router)
    }
}

class TestFlowCoordinator: Coordinator<FlowRoute> {
    let handledRoute: FlowRoute

    init(handles route: FlowRoute = .flow1) {
        handledRoute = route
        let router = Router<FlowRoute>(initial: route, factory: FlowRouteViewFactory())
        super.init(router: router)
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let flowRoute = route as? FlowRoute else { return false }
        return flowRoute == handledRoute
    }
}

class TestFlowOrchestratorWithFlowChange: FlowOrchestrator<FlowRoute> {
    init() {
        let router = Router<FlowRoute>(initial: .flow1, factory: FlowRouteViewFactory())
        super.init(router: router)

        // Start with flow1
        transitionToFlow(TestFlowCoordinator(), root: .flow1)
    }

    override func handleFlowChange(to route: any Route) -> Bool {
        guard let flowRoute = route as? FlowRoute else { return false }

        switch flowRoute {
        case .flow1:
            transitionToFlow(TestFlowCoordinator(handles: .flow1), root: .flow1)
            return true
        case .flow2:
            transitionToFlow(TestFlowCoordinator(handles: .flow2), root: .flow2)
            return true
        }
    }
}
