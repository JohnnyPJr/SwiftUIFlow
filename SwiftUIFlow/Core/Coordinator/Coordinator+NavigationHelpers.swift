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
    func validateNavigationPathBase(to route: any Route, from caller: AnyCoordinator?) -> Bool {
        // 1. Smart navigation check (no side effects - just checking state)
        if let typedRoute = route as? R, canValidateSmartNavigation(to: typedRoute) {
            return true
        }

        // 2. Modal/Detour navigation check (mirrors handleModalNavigation/handleDetourNavigation)
        if validateModalAndDetourNavigation(to: route, from: caller) {
            return true
        }

        // 3. Direct handling check (mirrors canHandle + executeNavigation)
        if validateDirectHandling(of: route) {
            return true
        }

        // 4. Delegate to children (mirrors delegateToChildren)
        if validateChildrenCanHandle(route: route, caller: caller) {
            return true
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

    private func validateModalAndDetourNavigation(to route: any Route, from caller: AnyCoordinator?) -> Bool {
        // Only check modal/detour if caller is NOT one of our children/modal/detour
        // (If caller is a child, we already checked modal before delegating to children)
        let callerIsOurChild = caller != nil && children.contains(where: { $0 === caller })
        let callerIsOurModalOrDetour = (caller === currentModalCoordinator) || (caller === detourCoordinator)

        // Check modal
        if let modal = currentModalCoordinator, !callerIsOurChild, !callerIsOurModalOrDetour {
            if modal.validateNavigationPath(to: route, from: self) {
                return true
            }
            // Modal didn't handle - in execution we'd dismiss and continue
            // So continue validation (don't return false)
        }

        // Check detour
        if let detour = detourCoordinator, !callerIsOurChild, !callerIsOurModalOrDetour {
            if detour.validateNavigationPath(to: route, from: self) {
                return true
            }
            // Detour didn't handle - in execution we'd dismiss and continue
            // So continue validation (don't return false)
        }

        return false
    }

    private func validateDirectHandling(of route: any Route) -> Bool {
        guard let typedRoute = route as? R, canHandle(typedRoute) else {
            return false
        }

        // Check if this navigation type can be executed
        switch navigationType(for: typedRoute) {
        case .push, .replace, .tabSwitch:
            return true
        case .modal:
            // Can we execute modal navigation?
            if let currentModal = currentModalCoordinator, currentModal.canHandle(route) {
                return true
            }
            return modalCoordinators.contains(where: { $0.canHandle(route) })
        case .detour:
            return false // Invalid - detour through navigate() not allowed
        }
    }

    private func validateChildrenCanHandle(route: any Route, caller: AnyCoordinator?) -> Bool {
        for child in children where child !== caller {
            // CRITICAL: Only delegate to children whose parent is actually us
            // (A child might be in our children array but have its parent temporarily changed,
            // e.g., when presented as a detour elsewhere)
            guard child.parent === self else { continue }

            if child.validateNavigationPath(to: route, from: self) {
                return true
            }
        }
        return false
    }

    private func validateBubbleToParent(route: any Route) -> Bool {
        guard let parent else {
            // At root - check if flow change can be handled (without executing it)
            return canHandleFlowChange(to: route)
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
            if !detourHandledRoute || shouldDismissDetourFor(route: route) {
                NavigationLogger.debug("🔙 \(Self.self): Dismissing detour for \(route.identifier)")
                dismissDetour()
            }
        }

        return false
    }

    func delegateToChildren(route: any Route, caller: AnyCoordinator?) -> Bool {
        for child in children where child !== caller {
            if child.navigate(to: route, from: self) {
                NavigationLogger.debug("👶 \(Self.self): Child handled \(route.identifier)")
                return true
            }
        }
        return false
    }

    func bubbleToParent(route: any Route) -> Bool {
        guard let parent else {
            // At the root - try flow change handler before failing
            if handleFlowChange(to: route) {
                NavigationLogger.info("🔄 \(Self.self): Handled flow change to \(route.identifier)")
                return true
            }
            // Navigation failed - no coordinator in hierarchy can handle this route
            NavigationLogger.error("❌ \(Self.self): Could not handle \(route.identifier)")
            reportError(makeError(for: route,
                                  errorType: .navigationFailed(context:
                                      "No coordinator in hierarchy can handle this route")))
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
        case .detour:
            return router.state.detour?.identifier == route.identifier
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
                router.present(route)
                _ = currentModal.navigate(to: route, from: self)
                return true
            }

            guard let modalChild = modalCoordinators.first(where: { $0.canHandle(route) }) else {
                reportError(makeError(for: route, errorType: .modalCoordinatorNotConfigured))
                return false
            }

            currentModalCoordinator = modalChild
            modalChild.parent = self
            modalChild.presentationContext = .modal
            router.present(route)
            _ = modalChild.navigate(to: route, from: self)
            return true
        case .detour:
            reportError(makeError(for: route, errorType: .invalidDetourNavigation))
            return false
        case let .tabSwitch(index):
            router.selectTab(index)
            return true
        }
    }
}
