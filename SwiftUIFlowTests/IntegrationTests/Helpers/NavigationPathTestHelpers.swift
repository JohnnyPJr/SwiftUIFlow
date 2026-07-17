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

enum PathRoute: String, Route {
    case root
    case step1
    case step2
    case finalDestination
    case noPath
}

enum MainPathRoute: String, Route {
    case home
    case pathFlow
}

enum EmptyPathRoute: String, Route {
    case root
    case destination
}

enum LongPathRoute: String, Route {
    case root
    case step1, step2, step3, step4, step5
    case step6, step7, step8, step9, final
}

enum MalformedPathRoute: Route {
    case root
    case prerequisite
    case modalPrerequisite
    case alias
    case destination

    var identifier: String {
        switch self {
        case .alias, .destination:
            "malformedPath.collidingDestination"
        default:
            "malformedPath.\(self)"
        }
    }
}

enum ForeignPathRoute: Route {
    case invalid

    var identifier: String {
        "malformedPath.foreign.invalid"
    }
}

enum DescendantPathParentRoute: Route {
    case root
    case context
    case modalContext

    var identifier: String {
        "descendantPath.parent.\(self)"
    }
}

enum DescendantPathGrandchildRoute: Route {
    case root
    case destination

    var identifier: String {
        "descendantPath.grandchild.\(self)"
    }
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

/// Parent coordinator that needs to build its own route stack before delegating to a pushed child.
final class DescendantPathParentCoordinator: Coordinator<DescendantPathParentRoute> {
    init(grandchild: DescendantPathGrandchildCoordinator) {
        super.init(router: Router(initial: .root, factory: DummyPathFactory()))
        addChild(grandchild)
    }

    override func canHandle(_ route: any Route) -> Bool {
        route is DescendantPathParentRoute
    }

    override func navigationPath(for route: any Route) -> [any Route]? {
        if route is DescendantPathGrandchildRoute {
            return [DescendantPathParentRoute.context]
        }

        return nil
    }
}

final class MalformedDescendantPathParentCoordinator: Coordinator<DescendantPathParentRoute> {
    enum PathKind {
        case modalRoute
        case foreignRoute
    }

    private let pathKind: PathKind

    init(grandchild: DescendantPathGrandchildCoordinator, pathKind: PathKind) {
        self.pathKind = pathKind
        super.init(router: Router(initial: .root, factory: DummyPathFactory()))
        addChild(grandchild)
    }

    override func canHandle(_ route: any Route) -> Bool {
        route is DescendantPathParentRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let route = route as? DescendantPathParentRoute else { return .push }
        return route == .modalContext ? .modal : .push
    }

    override func navigationPath(for route: any Route) -> [any Route]? {
        if route is DescendantPathGrandchildRoute {
            switch pathKind {
            case .modalRoute:
                return [DescendantPathParentRoute.modalContext]
            case .foreignRoute:
                return [ForeignPathRoute.invalid]
            }
        }

        return nil
    }
}

final class DescendantPathGrandchildCoordinator: Coordinator<DescendantPathGrandchildRoute> {
    init() {
        super.init(router: Router(initial: .root, factory: DummyPathFactory()))
    }

    override func canHandle(_ route: any Route) -> Bool {
        route is DescendantPathGrandchildRoute
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

/// Test coordinator for regression coverage around malformed navigation paths.
/// Paths must be fully validated before any stack mutation occurs.
final class MalformedPathCoordinator: Coordinator<MalformedPathRoute> {
    enum PathKind {
        case foreignRoute
        case modalRoute
        case validPathIncludingDestination
        case validPathExcludingDestination
        case validPathStartingWithRoot
        case sameIdentifierAsDestination
    }

    private let pathKind: PathKind

    init(pathKind: PathKind) {
        self.pathKind = pathKind
        super.init(router: Router(initial: .root, factory: DummyPathFactory()))
    }

    override func canHandle(_ route: any Route) -> Bool {
        route is MalformedPathRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let route = route as? MalformedPathRoute else { return .push }
        return route == .modalPrerequisite ? .modal : .push
    }

    override func navigationPath(for route: any Route) -> [any Route]? {
        guard route as? MalformedPathRoute == .destination else { return nil }

        switch pathKind {
        case .foreignRoute:
            return [MalformedPathRoute.prerequisite, ForeignPathRoute.invalid]
        case .modalRoute:
            return [MalformedPathRoute.prerequisite, MalformedPathRoute.modalPrerequisite]
        case .validPathIncludingDestination:
            return [MalformedPathRoute.prerequisite, MalformedPathRoute.destination]
        case .validPathExcludingDestination:
            return [MalformedPathRoute.prerequisite]
        case .validPathStartingWithRoot:
            return [MalformedPathRoute.root,
                    MalformedPathRoute.prerequisite,
                    MalformedPathRoute.destination]
        case .sameIdentifierAsDestination:
            return [MalformedPathRoute.alias]
        }
    }
}

// MARK: - Factories

final class DummyPathFactory<R: Route>: ViewFactory<R> {
    override func buildView(for route: R) -> AnyView? {
        AnyView(EmptyView())
    }
}
