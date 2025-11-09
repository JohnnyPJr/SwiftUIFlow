//
//  TabCoordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 15/9/25.
//

import Foundation

open class TabCoordinator<R: Route>: Coordinator<R> {
    /// Build a TabCoordinatorView for this tab coordinator
    override public func buildCoordinatorView() -> Any {
        return TabCoordinatorView(coordinator: self)
    }

    /// Override addChild to automatically set .tab context for tab children
    override public func addChild(_ coordinator: AnyCoordinator, context: CoordinatorPresentationContext = .tab) {
        // TabCoordinator children are always tabs, so default to .tab context
        super.addChild(coordinator, context: context)
    }

    open func getTabIndex(for coordinator: AnyCoordinator) -> Int? {
        for (index, child) in children.enumerated() {
            if child === coordinator {
                return index
            }
        }
        return nil
    }

    open func switchToTab(_ index: Int) {
        // Validate tab index
        guard index >= 0, index < children.count else {
            let error = SwiftUIFlowError.invalidTabIndex(index: index,
                                                         validRange: 0 ..< children.count)
            reportError(error)
            return
        }
        router.selectTab(index)
    }

    override open func cleanStateForBubbling() {
        // TabCoordinators don't clean their stack when bubbling
        // They only dismiss modals (dismissModal handles both coordinator and router)
        if currentModalCoordinator != nil {
            dismissModal()
        }
    }

    /// Override to use TabCoordinator-specific validation logic
    override open func validateNavigationPath(to route: any Route, from caller: AnyCoordinator?) -> ValidationResult {
        return validateNavigationPathTabImpl(to: route, from: caller)
    }

    // Override navigate to handle tab switching intelligently
    override public func navigate(to route: any Route, from caller: AnyCoordinator? = nil) -> Bool {
        NavigationLogger.debug("📑 \(Self.self): Tab navigation to \(route.identifier)")

        // First check if we can handle it directly
        if let typedRoute = route as? R, canHandle(typedRoute) {
            // Let the base class handle execution
            return super.navigate(to: route, from: caller)
        }

        // Phase 1: if Super doesn't handle: Validation - ONLY at entry point (caller == nil)
        if caller == nil {
            let validationResult = validateNavigationPath(to: route, from: caller)
            if case let .failure(error) = validationResult {
                NavigationLogger.error("❌ \(Self.self): Navigation validation failed for \(route.identifier)")
                reportError(error)
                return false
            }
        }

        // Phase 2: Execution (side effects happen here)
        // Try current tab first, but not if it's the caller (prevents infinite loop)
        let currentTabIndex = router.state.selectedTab
        if currentTabIndex < children.count {
            let currentTab = children[currentTabIndex]
            // Skip current tab if it's the one calling us (it already tried and failed)
            // Also check canNavigate first to avoid trying tabs that can't handle it
            if currentTab !== caller, currentTab.canNavigate(to: route) {
                if currentTab.navigate(to: route, from: self) {
                    NavigationLogger.debug("📑 \(Self.self): Current tab handled \(route.identifier)")
                    return true
                }
            }
        }

        // Current tab couldn't handle it - check other tabs
        // Here we MUST use canNavigate to avoid switching to tabs that can't handle the route
        for (index, child) in children.enumerated() {
            if index != currentTabIndex, child !== caller, child.canNavigate(to: route) {
                NavigationLogger.info("🔄 \(Self.self): Switching to tab \(index) for \(route.identifier)")
                switchToTab(index)
                return child.navigate(to: route, from: self)
            }
        }

        // No child can handle it - bubble to parent
        // Call bubbleToParent directly instead of super.navigate which would delegate to children again
        return bubbleToParent(route: route)
    }
}

// MARK: - Validation Implementation
extension TabCoordinator {
    /// TabCoordinator-specific validation implementation
    func validateNavigationPathTabImpl(to route: any Route, from caller: AnyCoordinator?) -> ValidationResult {
        // First check if we can handle it directly
        if let typedRoute = route as? R, canHandle(typedRoute) {
            // Let the base class validate
            return validateNavigationPathBase(to: route, from: caller)
        }

        // Try current tab first, but not if it's the caller (prevents infinite loop)
        let currentTabIndex = router.state.selectedTab
        if currentTabIndex < children.count {
            let currentTab = children[currentTabIndex]
            // Skip current tab if it's the one calling us (it already tried and failed)
            if currentTab !== caller, currentTab.canNavigate(to: route) {
                let currentTabResult = currentTab.validateNavigationPath(to: route, from: self)
                if currentTabResult.isSuccess {
                    return currentTabResult
                }
            }
        }

        // Current tab couldn't handle it - check other tabs
        for (index, child) in children.enumerated() {
            if index != currentTabIndex, child !== caller, child.canNavigate(to: route) {
                // In execution we'd switch tabs, but in validation we just check if child can handle
                let childResult = child.validateNavigationPath(to: route, from: self)
                if childResult.isSuccess {
                    return childResult
                }
            }
        }

        // No child can handle it - bubble to parent
        guard let parent else {
            if canHandleFlowChange(to: route) {
                return .success
            }
            return .failure(makeError(for: route,
                                      errorType:
                                      .navigationFailed(context: "No coordinator in hierarchy can handle this route")))
        }

        return parent.validateNavigationPath(to: route, from: self)
    }
}
