//
//  Coordinator+NavigationHelpers.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 7/11/25.
//

import Foundation

// MARK: - Validation Phase (No Side Effects)
extension Coordinator {
    /// Base implementation of validation - called from validateNavigationPath()
    func validateNavigationPathBase(to route: any Route, from caller: AnyCoordinator?) -> ValidationResult {
        // 1. Smart navigation check (no side effects - just checking state)
        if let typedRoute = route as? R, canValidateSmartNavigation(to: typedRoute) {
            return .success
        }

        // 2. Modal/Detour navigation check (mirrors handleModalNavigation/handleDetourNavigation)
        if let modalDetourResult = validateModalAndDetourNavigation(to: route, from: caller) {
            return modalDetourResult
        }

        // 3. Direct handling check (mirrors canHandle + executeNavigation)
        if let directHandlingResult = validateDirectHandling(of: route) {
            return directHandlingResult // Can be success OR failure (specific error)
        }

        // 4. Delegate to children (mirrors delegateToChildren)
        if let childrenResult = validateChildrenCanHandle(route: route, caller: caller) {
            return childrenResult
        }

        // 5. Bubble to parent (mirrors bubbleToParent)
        return validateBubbleToParent(route: route)
    }

    private func canValidateSmartNavigation(to route: R) -> Bool {
        // Already at route?
        if isAlreadyAt(route: route) {
            return true
        }

        // Route in stack? (would pop back)
        if router.state.stack.firstIndex(where: { $0 == route }) != nil {
            return true
        }

        // Route is root? (would pop to root or already there)
        if route == router.state.root {
            return true
        }

        return false
    }

    private func validateModalAndDetourNavigation(to route: any Route,
                                                  from caller: AnyCoordinator?) -> ValidationResult?
    {
        // Only check modal/detour if caller is NOT one of our children/modal/detour
        // (If caller is a child, we already checked modal before delegating to children)
        let callerIsOurChild = caller != nil && internalChildren.contains(where: { $0 === caller })
        let callerIsOurModalOrDetour = (caller === currentModalCoordinator) || (caller === detourCoordinator)

        // Check modal
        if let modal = currentModalCoordinator, !callerIsOurChild, !callerIsOurModalOrDetour {
            let modalResult = modal.validateNavigationPath(to: route, from: self)
            if modalResult.isSuccess {
                return modalResult
            }
            // Modal didn't handle - in execution we'd dismiss and continue
            // So continue validation (don't return failure)
        }

        // Check detour
        if let detour = detourCoordinator, !callerIsOurChild, !callerIsOurModalOrDetour {
            let detourResult = detour.validateNavigationPath(to: route, from: self)
            if detourResult.isSuccess {
                return detourResult
            }
            // Detour didn't handle - in execution we'd dismiss and continue
            // So continue validation (don't return failure)
        }

        return nil // Neither modal nor detour handled it - continue to next check
    }

    private func validateDirectHandling(of route: any Route) -> ValidationResult? {
        guard let typedRoute = route as? R, canHandle(typedRoute) else {
            return nil // Can't handle - continue to next check
        }

        // Check if this navigation type can be executed
        switch navigationType(for: typedRoute) {
        case .push, .replace:
            return .success
        case .modal:
            // Can we execute modal navigation?
            // Check if modal is already presented with this root route
            if let currentModal = currentModalCoordinator, currentModal.rootRoute.identifier == route.identifier {
                return .success
            }
            // Check if we have a modal coordinator configured with this root route
            if modalCoordinators.contains(where: { $0.router.state.root.identifier == route.identifier }) {
                return .success
            }
            // Modal navigation type but no coordinator configured
            return .failure(makeError(for: route, errorType: .modalCoordinatorNotConfigured))
        }
    }

    private func validateChildrenCanHandle(route: any Route, caller: AnyCoordinator?) -> ValidationResult? {
        for child in internalChildren where child !== caller {
            // Safety check: Ensure parent relationship is consistent
            // This should always be true, but we verify to maintain invariants
            guard child.parent === self else { continue }

            // Check if child or its descendants can handle this route (mirrors execution with canNavigate)
            if child.canNavigate(to: route) {
                let childResult = child.validateNavigationPath(to: route, from: self)
                if childResult.isSuccess {
                    return childResult
                }
            }
        }

        // Check if any modal coordinator can handle this route for subsequent navigation
        // (mirrors delegateToChildren execution)
        for modal in modalCoordinators where modal !== caller {
            if modal.canNavigate(to: route) {
                // Modal coordinator or its descendants can handle subsequent navigation
                // In execution, we'd present modal with its root route, then navigate
                // Here we just validate that the modal can handle it
                return .success
            }
        }

        return nil // No child handled it - continue to next check
    }

    private func validateBubbleToParent(route: any Route) -> ValidationResult {
        guard let parent else {
            // At root - check if flow change can be handled (without executing it)
            if canHandleFlowChange(to: route) {
                return .success
            }
            // No coordinator in hierarchy can handle this route
            return
                .failure(makeError(for: route,
                                   errorType:
                                   .navigationFailed(context: "No coordinator in hierarchy can handle this route")))
        }

        // In execution we'd clean state before bubbling, but validation doesn't need to check
        // We just validate that parent can handle the route
        return parent.validateNavigationPath(to: route, from: self)
    }
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
                // Get the navigation type the child coordinator expects for this route
                let navType = child.navigationType(for: route)

                // Check if child is already pushed - if so, just navigate without re-pushing
                let isAlreadyPushed = router.state.pushedChildren.contains(where: { $0 === child })

                if !isAlreadyPushed {
                    // Push child coordinator to parent's navigation stack
                    router.pushChild(child)
                    child.parent = self
                    child.presentationContext = .pushed

                    let navTypeLabel = navType == .modal ? "for modal" : navType == .replace ? "(replace)" : ""

                    NavigationLogger
                        .debug("👶 \(Self.self): Pushed child coordinator \(navTypeLabel) for \(route.identifier)")
                }

                // Navigate to the route (whether already pushed or not)
                _ = child.navigate(to: route, from: self)
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
                // Build navigation path if needed before presenting the modal
                // This handles cases where the route is handled by a descendant
                // but the parent coordinator needs to build a path to the correct state first
                _ = buildNavigationPath(for: route)

                // Modal or its descendants can handle subsequent navigation - present modal with its root route first
                let initialRoute = modal.router.state.root
                let detents = modalDetentConfiguration(for: initialRoute)
                presentModal(modal, presenting: initialRoute, detentConfiguration: detents)
                _ = modal.navigate(to: route, from: self)
                NavigationLogger.debug("📲 \(Self.self): Presented modal -> navigating to \(route.identifier)")
                return true
            }
        }

        return false
    }

    private func buildNavigationPath(for route: any Route) -> Bool {
        guard let path = navigationPath(for: route),
              !path.isEmpty,
              router.state.stack.isEmpty else { return false }

        NavigationLogger.debug("🗺️ \(Self.self): Building navigation path to \(route.identifier)")

        for intermediateRoute in path {
            // Skip if this route is the current root (don't push root onto stack)
            if intermediateRoute.identifier == router.state.root.identifier {
                NavigationLogger.debug("⏭️ \(Self.self): Skipping root \(intermediateRoute.identifier) in path")
                continue
            }

            guard let typedRoute = intermediateRoute as? R else {
                NavigationLogger.error("❌ \(Self.self): Navigation path contains invalid route type")
                return false
            }

            switch navigationType(for: typedRoute) {
            case .push:
                router.push(typedRoute)
            case .replace:
                router.replace(typedRoute)
            case .modal:
                NavigationLogger.error("❌ \(Self.self): Navigation path cannot contain modal routes")
                return false
            }
        }

        return true
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
        // Check if this route requires building a navigation path
        // Only build path if we're at the root (stack is empty) - meaning this is a deeplink scenario
        // If stack has items, we're already navigating within this coordinator, so navigate normally
        if buildNavigationPath(for: route) {
            // If the target route is in the path, we're done (path includes destination)
            // If not, fall through to execute the target route (e.g., modal presentation)
            if let path = navigationPath(for: route),
               path.contains(where: { $0.identifier == route.identifier })
            {
                return true
            }
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
            if lastChild.allRoutes.count > 1 {
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
