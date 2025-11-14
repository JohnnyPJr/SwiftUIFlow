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
        let callerIsOurChild = caller != nil && children.contains(where: { $0 === caller })
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
        case .push, .replace, .tabSwitch:
            return .success
        case .modal:
            // Can we execute modal navigation?
            if let currentModal = currentModalCoordinator, currentModal.canHandle(route) {
                return .success
            }
            if modalCoordinators.contains(where: { $0.canHandle(route) }) {
                return .success
            }
            // Modal navigation type but no coordinator configured
            return .failure(makeError(for: route, errorType: .modalCoordinatorNotConfigured))
        }
    }

    private func validateChildrenCanHandle(route: any Route, caller: AnyCoordinator?) -> ValidationResult? {
        for child in children where child !== caller {
            // CRITICAL: Only delegate to children whose parent is actually us
            // (A child might be in our children array but have its parent temporarily changed,
            // e.g., when presented as a detour elsewhere)
            guard child.parent === self else { continue }

            let childResult = child.validateNavigationPath(to: route, from: self)
            if childResult.isSuccess {
                return childResult
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
        for child in children where child !== caller {
            if child.canHandle(route) {
                // Get the navigation type the child coordinator expects for this route
                let navType = child.navigationType(for: route)

                switch navType {
                case .push:
                    // Push child coordinator to parent's navigation stack
                    router.pushChild(child)
                    child.parent = self
                    child.presentationContext = .pushed
                    _ = child.navigate(to: route, from: self)
                    NavigationLogger.debug("👶 \(Self.self): Pushed child coordinator for \(route.identifier)")
                    return true

                case .replace:
                    // Push child coordinator (first time), child will handle replace internally
                    router.pushChild(child)
                    child.parent = self
                    child.presentationContext = .pushed
                    _ = child.navigate(to: route, from: self)
                    NavigationLogger.debug("👶 \(Self.self): Pushed child coordinator (replace) for \(route.identifier)")
                    return true

                case .modal:
                    // Delegate modal navigation to child - let child handle its own modal presentation
                    _ = child.navigate(to: route, from: self)
                    NavigationLogger.debug("👶 \(Self.self): Child handled modal navigation for \(route.identifier)")
                    return true

                case .tabSwitch:
                    // Tab switching doesn't make sense for child delegation, just delegate
                    _ = child.navigate(to: route, from: self)
                    NavigationLogger.debug("👶 \(Self.self): Child handled tab switch for \(route.identifier)")
                    return true
                }
            }
        }
        return false
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
        case let .tabSwitch(index):
            return router.state.selectedTab == index
        case .push, .replace:
            return router.state.currentRoute == route
        case .modal:
            return router.state.presented == route
        }
    }

    func executeNavigation(for route: R) -> Bool {
        switch navigationType(for: route) {
        case .push:
            router.push(route)
            return true
        case .replace:
            router.replace(route)
            return true
        case .modal:
            if let currentModal = currentModalCoordinator, currentModal.canHandle(route) {
                // Modal is already presented - let it handle navigation internally
                _ = currentModal.navigate(to: route, from: self)
                return true
            }

            guard let modalChild = modalCoordinators.first(where: { $0.canHandle(route) }) else {
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
        case let .tabSwitch(index):
            router.selectTab(index)
            return true
        }
    }
}
