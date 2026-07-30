//
//  Coordinator+NavigationValidation.swift
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

    /// Internal (not private) so TabCoordinator's validation can reuse the exact same
    /// modal/detour validation stage, keeping validation in lockstep with execution.
    func validateModalAndDetourNavigation(to route: any Route,
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

        // Validate this coordinator's own navigationPath(for:) before accepting direct handling.
        // This keeps validation in lockstep with executeNavigation/buildNavigationPath, including
        // when this coordinator is reached through parent delegation with caller != nil.
        if let pathResult = validateNavigationPathDefinition(for: route) {
            if case .failure = pathResult {
                return pathResult
            }
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
                if let pathResult = validateNavigationPathDefinition(for: route) {
                    if case .failure = pathResult {
                        return pathResult
                    }
                }

                return child.validateNavigationPath(to: route, from: self)
            }
        }

        // Check if any modal coordinator can handle this route for subsequent navigation
        // (mirrors delegateToChildren execution)
        for modal in modalCoordinators where modal !== caller {
            if modal.canNavigate(to: route) {
                if let pathResult = validateNavigationPathDefinition(for: route) {
                    if case .failure = pathResult {
                        return pathResult
                    }
                }

                // Modal coordinator or its descendants can handle subsequent navigation.
                // Validate the modal's own path before execution presents it.
                return modal.validateNavigationPath(to: route, from: self)
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
