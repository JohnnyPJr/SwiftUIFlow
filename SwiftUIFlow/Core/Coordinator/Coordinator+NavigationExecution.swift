//
//  Coordinator+NavigationExecution.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 7/11/25.
//

import Foundation

private enum NavigationPathEntryValidation<R: Route> {
    case valid(route: R, navigationType: NavigationType)
    case skipRoot(route: R)
    case invalidRouteType
    case modalRoute
}

// MARK: - Execution Phase (With Side Effects)
extension Coordinator {
    func trySmartNavigation(to route: R) -> Bool {
        if isAlreadyAt(route: route) {
            NavigationLogger.debug("✋ \(Self.self): Already at \(route.identifier), skipping navigation")
            return true
        }

        if router.state.stack.firstIndex(where: { $0 == route }) != nil {
            NavigationLogger.debug("⏪ \(Self.self): Popping back to \(route.identifier)")
            popTo(route)
            return true
        }

        if route == router.state.root {
            if !router.state.stack.isEmpty {
                NavigationLogger.debug("⏪ \(Self.self): Popping to root \(route.identifier)")
                popToRoot()
                return true
            } else {
                NavigationLogger.debug("✋ \(Self.self): Already at root \(route.identifier)")
                return true
            }
        }

        return false
    }

    func handleModalNavigation(to route: any Route, from caller: AnyCoordinator?) -> Bool {
        guard let modal = currentModalCoordinator else { return false }

        var modalHandledRoute = false

        if modal !== caller {
            modalHandledRoute = modal.navigate(to: route, from: self)
        }

        if modalHandledRoute, currentModalCoordinator === modal {
            NavigationLogger.debug("📱 \(Self.self): Modal handled \(route.identifier)")
            return true
        }

        if currentModalCoordinator === modal {
            if !modalHandledRoute || shouldDismissModalFor(route: route) {
                NavigationLogger.debug("🚪 \(Self.self): Dismissing modal for \(route.identifier)")
                dismissModal()
            }
        }

        return false
    }

    func handleDetourNavigation(to route: any Route, from caller: AnyCoordinator?) -> Bool {
        guard let detour = detourCoordinator else { return false }

        var detourHandledRoute = false

        if detour !== caller {
            detourHandledRoute = detour.navigate(to: route, from: self)
        }

        if detourHandledRoute, detourCoordinator === detour {
            NavigationLogger.debug("🚀 \(Self.self): Detour handled \(route.identifier)")
            return true
        }

        if detourCoordinator === detour {
            if !detourHandledRoute {
                // Detours always dismiss if they don't handle the route
                NavigationLogger.debug("🔙 \(Self.self): Dismissing detour for \(route.identifier)")
                dismissDetour()
            }
        }

        return false
    }

    func delegateToChildren(route: any Route, caller: AnyCoordinator?) -> Bool {
        // Try delegating to internal children first
        if delegateToInternalChildren(route: route, caller: caller) {
            return true
        }

        // Then try modal coordinators
        return delegateToModalChildren(route: route, caller: caller)
    }

    private func delegateToInternalChildren(route: any Route, caller: AnyCoordinator?) -> Bool {
        for child in internalChildren where child !== caller {
            if child.canNavigate(to: route) {
                if let pathResult = validateNavigationPathDefinition(for: route) {
                    if case let .failure(error) = pathResult {
                        reportError(error)
                        return false
                    }
                }

                // Build this coordinator's path before pushing/delegating to the child.
                // This handles deep links where a child or descendant route requires the parent
                // coordinator to reach a specific local context first.
                let parentPathResult = buildNavigationPath(for: route)
                if case .failed = parentPathResult {
                    return false
                }
                let didBuildParentPath = parentPathResult.didBuildPath

                // Get the navigation type the child coordinator expects for this route
                let navType = child.navigationType(for: route)

                // Check if child is already pushed - if so, just navigate without re-pushing
                let isAlreadyPushed = router.state.pushedChildren.contains(where: { $0 === child })
                let previousParent = child.parent
                let previousPresentationContext = child.presentationContext

                if !isAlreadyPushed {
                    // Push child coordinator to parent's navigation stack
                    router.pushChild(child)
                    child.parent = self
                    child.presentationContext = .pushed

                    let navTypeLabel = navType == .modal ? "for modal" : navType == .replace ? "(replace)" : ""

                    NavigationLogger
                        .debug("👶 \(Self.self): Pushed child coordinator \(navTypeLabel) for \(route.identifier)")
                }

                // Navigate to the route (whether already pushed or not). Validation should have
                // caught expected failures; this backstop prevents delegated failures being reported
                // as parent success and rolls back only state introduced by this call.
                let didNavigate = child.navigate(to: route, from: self)
                guard didNavigate else {
                    if !isAlreadyPushed {
                        router.popChild()
                        child.parent = previousParent
                        child.presentationContext = previousPresentationContext
                    }
                    if didBuildParentPath {
                        router.popToRoot()
                    }
                    return false
                }

                return true
            }
        }

        return false
    }

    private func delegateToModalChildren(route: any Route, caller: AnyCoordinator?) -> Bool {
        // Check if any modal coordinator can handle this route (for subsequent navigation)
        // Parent doesn't handle this route, but modal child or its descendants might
        for modal in modalCoordinators where modal !== caller {
            if modal.canNavigate(to: route) {
                if let pathResult = validateNavigationPathDefinition(for: route) {
                    if case let .failure(error) = pathResult {
                        reportError(error)
                        return false
                    }
                }

                // Build navigation path if needed before presenting the modal.
                // This handles cases where the route is handled by a descendant
                // but the parent coordinator needs to build a path to the correct state first.
                // A malformed path is a contract error - abort rather than present the modal on
                // top of a state that was never correctly built (error already reported).
                let parentPathResult = buildNavigationPath(for: route)
                if case .failed = parentPathResult {
                    return false
                }
                let didBuildParentPath = parentPathResult.didBuildPath

                // Modal or its descendants can handle subsequent navigation - present modal with its root route first
                let initialRoute = modal.router.state.root
                let detents = modalDetentConfiguration(for: initialRoute)
                let wasAlreadyPresented = currentModalCoordinator === modal
                presentModal(modal, presenting: initialRoute, detentConfiguration: detents)

                let didNavigate = modal.navigate(to: route, from: self)
                guard didNavigate else {
                    if !wasAlreadyPresented, currentModalCoordinator === modal {
                        dismissModal()
                    }
                    if didBuildParentPath {
                        router.popToRoot()
                    }
                    return false
                }

                NavigationLogger.debug("📲 \(Self.self): Presented modal -> navigating to \(route.identifier)")
                return true
            }
        }

        return false
    }

    /// Outcome of attempting to build a navigation path for a route.
    ///
    /// Distinguishes the three genuinely different cases that a `Bool` return would conflate:
    /// - `.notRequired`: no path is needed (none defined, empty, or stack already populated) —
    ///   the caller should continue with normal direct navigation.
    /// - `.failed`: a path was defined but is malformed (contains a foreign-type or modal route) —
    ///   the caller must stop; nothing was mutated.
    /// - `.built`: the path was validated and applied. `includesDestination` reports whether the
    ///   destination route was part of the path (so the caller knows whether it still needs to
    ///   execute the destination directly).
    private enum NavigationPathBuildResult {
        case notRequired
        case failed
        case built(includesDestination: Bool)

        var didBuildPath: Bool {
            if case .built = self {
                return true
            }
            return false
        }
    }

    private func buildNavigationPath(for route: any Route) -> NavigationPathBuildResult {
        guard let path = navigationPath(for: route),
              !path.isEmpty,
              router.state.stack.isEmpty else { return .notRequired }

        NavigationLogger.debug("🗺️ \(Self.self): Building navigation path to \(route.identifier)")

        // Phase 1: Validate the entire path and resolve navigation types WITHOUT mutating state.
        // A navigation path must contain only this coordinator's own (`R`) routes, and none of them
        // may be modal routes (modals are a separate presentation layer, not a pushed prerequisite).
        // Any violation is a contract error in the consumer's `navigationPath(for:)` override; we
        // abort here so the stack is never left partially built.
        // The destination as this coordinator's own route type, if applicable. Resolved once
        // (loop-invariant) so path membership is checked with typed equality, not identifier
        // strings - two distinct `R` cases with colliding identifiers must not be conflated.
        let typedDestination = route as? R

        var resolvedPath: [(route: R, navigationType: NavigationType)] = []
        var includesDestination = false
        for intermediateRoute in path {
            switch classifyNavigationPathEntry(intermediateRoute) {
            case .invalidRouteType:
                reportInvalidPathRouteType(for: route)
                return .failed
            case .modalRoute:
                reportModalRouteInPath(for: route)
                return .failed
            case let .skipRoot(typedRoute):
                // Track before skipping root so a destination that is also root still counts
                // as already included in the path.
                if let typedDestination, typedRoute == typedDestination {
                    includesDestination = true
                }
                NavigationLogger.debug("⏭️ \(Self.self): Skipping root \(typedRoute.identifier) in path")
            case let .valid(typedRoute, navType):
                // Track whether the destination itself appears in the path (typed equality).
                if let typedDestination, typedRoute == typedDestination {
                    includesDestination = true
                }
                resolvedPath.append((typedRoute, navType))
            }
        }

        // Phase 2: All routes are valid - apply them. State is only mutated once the whole path
        // is known to be buildable, preserving atomicity.
        for entry in resolvedPath {
            switch entry.navigationType {
            case .push:
                router.push(entry.route)
            case .replace:
                router.replace(entry.route)
            case .modal:
                break // Unreachable: modal routes are rejected in Phase 1.
            }
        }

        return .built(includesDestination: includesDestination)
    }

    func validateNavigationPathDefinition(for route: any Route) -> ValidationResult? {
        guard let path = navigationPath(for: route),
              !path.isEmpty,
              router.state.stack.isEmpty else { return nil }

        for intermediateRoute in path {
            switch classifyNavigationPathEntry(intermediateRoute) {
            case .invalidRouteType:
                return .failure(invalidPathRouteTypeError(for: route))
            case .modalRoute:
                return .failure(modalRouteInPathError(for: route))
            case .skipRoot, .valid:
                continue
            }
        }

        return .success
    }

    private func classifyNavigationPathEntry(_ pathRoute: any Route) -> NavigationPathEntryValidation<R> {
        // Cast before any root comparison: a foreign route must be rejected even if its
        // identifier happens to collide with the root's identifier.
        guard let typedRoute = pathRoute as? R else {
            return .invalidRouteType
        }

        if typedRoute == router.state.root {
            return .skipRoot(route: typedRoute)
        }

        let navType = navigationType(for: typedRoute)
        guard navType != .modal else {
            return .modalRoute
        }

        return .valid(route: typedRoute, navigationType: navType)
    }

    private func invalidPathRouteTypeError(for route: any Route) -> SwiftUIFlowError {
        makeError(for: route,
                  errorType:
                  .navigationFailed(context: """
                  navigationPath(for:) returned a route of a different type; \
                  a path may only contain this coordinator's own routes
                  """))
    }

    private func modalRouteInPathError(for route: any Route) -> SwiftUIFlowError {
        makeError(for: route,
                  errorType:
                  .navigationFailed(context: """
                  navigationPath(for:) returned a modal route; \
                  a path may only contain pushed/replaced routes
                  """))
    }

    private func reportInvalidPathRouteType(for route: any Route) {
        NavigationLogger
            .error("""
            ❌ \(Self.self): Navigation path contains invalid route type - \
            aborting without mutating state
            """)
        reportError(invalidPathRouteTypeError(for: route))
    }

    private func reportModalRouteInPath(for route: any Route) {
        NavigationLogger
            .error("""
            ❌ \(Self.self): Navigation path cannot contain modal routes - \
            aborting without mutating state
            """)
        reportError(modalRouteInPathError(for: route))
    }

    func bubbleToParent(route: any Route) -> Bool {
        guard let parent else {
            // At the root - try flow change handler before failing
            if handleFlowChange(to: route) {
                NavigationLogger
                    .info("🔄 \(Self.self): Handled flow change to \(route.identifier)")
                return true
            }
            // Validation already checked that flow change can be handled
            // This should never fail, but we log for safety
            NavigationLogger
                .error("❌ \(Self.self): Could not handle \(route.identifier) - validation should have caught this")
            return false
        }

        NavigationLogger.debug("⬆️ \(Self.self): Bubbling \(route.identifier) to parent")

        if shouldCleanStateForBubbling(route: route) {
            NavigationLogger.debug("🧹 \(Self.self): Cleaning state before bubbling")
            cleanStateForBubbling()
        }

        return parent.navigate(to: route, from: self)
    }

    func isAlreadyAt(route: R) -> Bool {
        switch navigationType(for: route) {
        case .push, .replace:
            let currentRoute = router.state.currentRoute
            let isAt = currentRoute == route
            NavigationLogger.debug("🔍 isAlreadyAt check: currentRoute=\(currentRoute.identifier)")
            return isAt
        case .modal:
            return router.state.presented == route
        }
    }

    func executeNavigation(for route: R) -> Bool {
        // Check if this route requires building a navigation path.
        // Only build path if we're at the root (stack is empty) - meaning this is a deeplink scenario.
        // If stack has items, we're already navigating within this coordinator, so navigate normally.
        switch buildNavigationPath(for: route) {
        case .failed:
            // A path was defined but malformed. Nothing was mutated; error already reported.
            // Stop here rather than falling through to push the destination without its prerequisites.
            return false
        case let .built(includesDestination):
            // Path built successfully. If it already included the destination, we're done.
            // Otherwise fall through to execute the target route (e.g., modal presentation).
            if includesDestination {
                return true
            }
        case .notRequired:
            break // No path needed - continue with normal direct navigation.
        }

        // Default behavior - direct navigation
        switch navigationType(for: route) {
        case .push:
            router.push(route)
            return true
        case .replace:
            router.replace(route)
            return true
        case .modal:
            if let currentModal = currentModalCoordinator, currentModal.rootRoute.identifier == route.identifier {
                // Modal is already presented with this root route - already at destination
                return true
            }

            // Find modal coordinator by matching root identifier (not canHandle)
            // Parent handles the modal's entry route, child handles subsequent routes
            guard let modalChild = modalCoordinators
                .first(where: { $0.router.state.root.identifier == route.identifier })
            else {
                NavigationLogger
                    .error("❌ \(Self.self): Modal coordinator not found - validation should have caught this")
                return false
            }

            // Get detent configuration from parent coordinator
            let detents = modalDetentConfiguration(for: route)

            // Present modal using internal API
            presentModal(modalChild, presenting: route, detentConfiguration: detents)
            _ = modalChild.navigate(to: route, from: self)
            return true
        }
    }

    // MARK: - Navigation Stack Control

    /// Pop one screen from the navigation stack
    func pop() {
        // Pushed childs pop handling
        if let lastChild = router.state.pushedChildren.last {
            // Descend into the deepest pushed descendant first. The flattened NavigationStack
            // renders a child's own routes before its pushed children, so a pushed grandchild
            // is the last visible route and must pop before the immediate child is removed.
            if !lastChild.pushedChildren.isEmpty || lastChild.allRoutes.count > 1 {
                lastChild.pop()
            } else {
                router.popChild()
            }
            return
        }

        // Modal/detour childs handling
        if router.state.stack.isEmpty {
            switch presentationContext {
            case .modal:
                parent?.dismissModal()
                return
            case .detour:
                parent?.dismissDetour()
                return
            default:
                break
            }
        }

        // Normal pop handling
        router.pop()
    }

    /// Pop all screens and return to the root of this coordinator's flow
    func popToRoot() {
        router.popToRoot()
    }

    /// Pop to a specific route in the stack (if it exists)
    func popTo(_ route: R) {
        guard let index = router.state.stack.firstIndex(where: { $0 == route }) else {
            return
        }

        let popCount = router.state.stack.count - index - 1
        for _ in 0 ..< popCount {
            router.pop()
        }
    }
}
