//
//  PushedChildRouteFlattener.swift
//  SwiftUIFlow
//
//  Created by Codex on 30/7/26.
//

import Foundation

enum PushedChildRouteFlattener {
    /// Recursively collect pushed coordinators in visible navigation order.
    static func coordinators(from children: [any CoordinatorType]) -> [any CoordinatorType] {
        coordinators(from: children, visited: [])
    }

    private static func coordinators(from children: [any CoordinatorType],
                                     visited: Set<ObjectIdentifier>) -> [any CoordinatorType]
    {
        children.flatMap { child -> [any CoordinatorType] in
            let identifier = ObjectIdentifier(child)
            guard !visited.contains(identifier) else { return [] }

            var nextVisited = visited
            nextVisited.insert(identifier)

            return [child] + coordinators(from: child.pushedChildren, visited: nextVisited)
        }
    }

    /// Recursively flatten pushed child routes in the same order SwiftUI should render them.
    static func routes(from children: [any CoordinatorType]) -> [ChildRouteWrapper] {
        routes(from: children, visited: [])
    }

    private static func routes(from children: [any CoordinatorType],
                               visited: Set<ObjectIdentifier>) -> [ChildRouteWrapper]
    {
        children.flatMap { child -> [ChildRouteWrapper] in
            let identifier = ObjectIdentifier(child)
            guard !visited.contains(identifier) else { return [] }

            var nextVisited = visited
            nextVisited.insert(identifier)

            let ownRoutes = child.allRoutes.map { route in
                ChildRouteWrapper(route: route, coordinator: child)
            }

            return ownRoutes + routes(from: child.pushedChildren, visited: nextVisited)
        }
    }
}
