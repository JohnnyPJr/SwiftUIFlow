//
//  TestCoordinator.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Foundation
@testable import SwiftUIFlow

final class TestCoordinator: Coordinator<MockRoute> {
    var didHandleRoute = false
    var lastHandledRoute: MockRoute?

    override func handle(route: MockRoute) -> Bool {
        didHandleRoute = true
        lastHandledRoute = route
        return true
    }
}

final class TestCoordinatorWithChild: Coordinator<MockRoute> {
    let child: TestCoordinator

    override init(router: Router<MockRoute> = Router<MockRoute>(initial: .home)) {
        self.child = TestCoordinator(router: Router<MockRoute>(initial: .home))
        super.init(router: router)
        addChild(child)
    }
}
