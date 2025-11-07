//
//  Coordinator+NavigationHelpers.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 7/11/25.
//

import Foundation

// MARK: - Private Navigation Helpers
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
            NavigationLogger.error("❌ \(Self.self): Could not handle \(route.identifier)")
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

    func executeNavigation(for route: R) {
        switch navigationType(for: route) {
        case .push:
            router.push(route)
        case .replace:
            router.replace(route)
        case .modal:
            if let currentModal = currentModalCoordinator, currentModal.canHandle(route) {
                router.present(route)
                _ = currentModal.navigate(to: route, from: self)
                return
            }

            guard let modalChild = modalCoordinators.first(where: { $0.canHandle(route) }) else {
                assertionFailure("Modal navigation a navigator that can handle route: \(route.identifier).")
                return
            }

            currentModalCoordinator = modalChild
            modalChild.parent = self
            modalChild.presentationContext = .modal
            router.present(route)
            _ = modalChild.navigate(to: route, from: self)
        case .detour:
            assertionFailure("Detours must be presented explicitly via presentDetour(), not through navigate()")
            return
        case let .tabSwitch(index):
            router.selectTab(index)
        }
    }
}
