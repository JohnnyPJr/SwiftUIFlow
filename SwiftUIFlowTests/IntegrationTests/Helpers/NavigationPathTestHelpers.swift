//
//  NavigationPathTestHelpers.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 1/12/25.
//

import Foundation
import SwiftUI
@testable import SwiftUIFlow

// MARK: - Routes

enum PathRoute: Route {
    case root
    case step1
    case step2
    case finalDestination
    case noPath

    var identifier: String { "\(self)" }
}

enum MainPathRoute: Route {
    case home
    case pathFlow

    var identifier: String { "\(self)" }
}

enum EmptyPathRoute: Route {
    case root
    case destination

    var identifier: String { "\(self)" }
}

enum LongPathRoute: Route {
    case root
    case step1, step2, step3, step4, step5
    case step6, step7, step8, step9, final

    var identifier: String { "\(self)" }
}

// MARK: - Test Coordinators

/// Test coordinator with navigationPath() implementation
/// Used for testing basic path building functionality
final class PathTestCoordinator: Coordinator<PathRoute> {
    init() {
        super.init(router: Router(initial: .root, factory: DummyPathFactory()))
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is PathRoute
    }

    override func navigationPath(for route: any Route) -> [any Route]? {
        guard let pathRoute = route as? PathRoute else { return nil }

        switch pathRoute {
        case .root:
            return nil
        case .step1:
            return nil // No path - direct navigation
        case .step2:
            return [PathRoute.step1, PathRoute.step2]
        case .finalDestination:
            return [PathRoute.step1, PathRoute.step2, PathRoute.finalDestination]
        case .noPath:
            return nil
        }
    }
}

/// Parent coordinator that delegates to PathTestCoordinator child
/// Used for testing cross-coordinator path building
final class MainPathCoordinator: Coordinator<MainPathRoute> {
    private let pathChild: PathTestCoordinator

    override init(router: Router<MainPathRoute>) {
        pathChild = PathTestCoordinator()
        super.init(router: router)
        addChild(pathChild)
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is MainPathRoute
    }
}

/// Test coordinator that returns empty array for navigationPath
/// Used for testing empty path handling
final class EmptyPathCoordinator: Coordinator<EmptyPathRoute> {
    init() {
        super.init(router: Router(initial: .root, factory: DummyPathFactory()))
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is EmptyPathRoute
    }

    override func navigationPath(for route: any Route) -> [any Route]? {
        guard route is EmptyPathRoute else { return nil }
        return [] // Empty array - should navigate directly
    }
}

/// Test coordinator with long path (10 steps)
/// Used for testing performance of path building
final class LongPathCoordinator: Coordinator<LongPathRoute> {
    init() {
        super.init(router: Router(initial: .root, factory: DummyPathFactory()))
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is LongPathRoute
    }

    override func navigationPath(for route: any Route) -> [any Route]? {
        guard let pathRoute = route as? LongPathRoute else { return nil }

        if pathRoute == .final {
            return [LongPathRoute.step1,
                    LongPathRoute.step2,
                    LongPathRoute.step3,
                    LongPathRoute.step4,
                    LongPathRoute.step5,
                    LongPathRoute.step6,
                    LongPathRoute.step7,
                    LongPathRoute.step8,
                    LongPathRoute.step9,
                    LongPathRoute.final]
        }
        return nil
    }
}

// MARK: - Factories

final class DummyPathFactory<R: Route>: ViewFactory<R> {
    override func buildView(for route: R) -> AnyView? {
        AnyView(EmptyView())
    }
}
