//
//  TestCoordinator.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Foundation
@testable import SwiftUIFlow

class TestCoordinator: Coordinator<MockRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        guard let route = route as? MockRoute else { return false }
        // TestCoordinator can handle details routes
        return route == .details
    }
}

final class TestCoordinatorWithChild: Coordinator<MockRoute> {
    let child: TestCoordinator

    override init(router: Router<MockRoute> = Router<MockRoute>(initial: .home, factory: MockViewFactory())) {
        child = TestCoordinator(router: Router<MockRoute>(initial: .home, factory: MockViewFactory()))
        super.init(router: router)
        addChild(child)
    }

    override func canHandle(_ route: any Route) -> Bool {
        // Parent doesn't handle anything directly
        return false
    }
}

final class TestCoordinatorWithChildThatCantHandleNavigation: TestCoordinator {
    let child: Coordinator<MockRoute>

    override init(router: Router<MockRoute> = Router<MockRoute>(initial: .home, factory: MockViewFactory())) {
        child = Coordinator(router: router)
        super.init(router: router)
        addChild(child)
    }
}

final class TestModalCoordinator: Coordinator<MockRoute> {
    override func navigationType(for route: any Route) -> NavigationType {
        return .modal
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let route = route as? MockRoute else { return false }
        return route == .details || route == .modal
    }
}

// Parent coordinator that presents .modal as modal and pushes .details
final class TestMixedNavigationCoordinator: Coordinator<MockRoute> {
    override func navigationType(for route: any Route) -> NavigationType {
        guard let route = route as? MockRoute else { return .push }
        // Only .modal is presented as modal, .details is pushed
        return route == .modal ? .modal : .push
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let route = route as? MockRoute else { return false }
        return route == .details || route == .modal
    }
}

final class TestTabCoordinator: TabCoordinator<MainTabRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        // TestTabCoordinator doesn't handle routes directly
        // Tab switching happens automatically via children
        return false
    }
}

final class TestReplaceCoordinator: Coordinator<MockRoute> {
    override func navigationType(for route: any Route) -> NavigationType {
        // Use replace for all routes (for testing replace navigation)
        return .replace
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let route = route as? MockRoute else { return false }
        // Can handle details and modal (for multi-step flow tests)
        return route == .details || route == .modal
    }
}

final class TestModalThatCantHandle: Coordinator<MockRoute> {
    override func navigationType(for route: any Route) -> NavigationType {
        return .modal
    }

    override func canHandle(_ route: any Route) -> Bool {
        // This modal can't handle any routes
        return false
    }
}

final class TestCoordinatorThatCleansOnBubble: TestCoordinator {
    override func canHandle(_ route: any Route) -> Bool {
        // This coordinator can't handle any routes - will always bubble to parent
        return false
    }

    override func shouldCleanStateForBubbling(route: any Route) -> Bool {
        return true // Always clean when bubbling
    }
}

final class TestCoordinatorWithFlowChange: TestCoordinator {
    var flowChangeWasCalled = false
    var flowChangeRoute: (any Route)?
    var shouldHandleFlowChange = true

    override init(router: Router<MockRoute> = Router<MockRoute>(initial: .home, factory: MockViewFactory())) {
        super.init(router: router)
    }

    override func canHandleFlowChange(to route: any Route) -> Bool {
        guard let mockRoute = route as? MockRoute else { return false }
        // Can handle flow changes for login route
        return mockRoute == .login
    }

    override func handleFlowChange(to route: any Route) -> Bool {
        flowChangeWasCalled = true
        flowChangeRoute = route
        return shouldHandleFlowChange
    }
}
