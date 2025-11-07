//
//  CoordinatorTestHelpers.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 5/11/25.
//

import Foundation
@testable import SwiftUIFlow

// MARK: - System Under Test Helper

struct SUT {
    let router: Router<MockRoute>
    let coordinator: TestCoordinator
    let childCoordinator: TestCoordinator?
}

func makeSUT(router: Router<MockRoute>? = nil, addChild: Bool = false) -> SUT {
    let resolvedRouter = router ?? Router<MockRoute>(initial: .home, factory: MockViewFactory())
    let coordinator = TestCoordinator(router: resolvedRouter)

    var child: TestCoordinator?
    if addChild {
        child = TestCoordinator(router: resolvedRouter)
        coordinator.addChild(child!)
    }

    return SUT(router: resolvedRouter,
               coordinator: coordinator,
               childCoordinator: child)
}
