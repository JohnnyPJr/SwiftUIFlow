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
        router.selectTab(index)
    }

    override open func cleanStateForBubbling() {
        // TabCoordinators don't clean their stack when bubbling
        // They only dismiss modals (dismissModal handles both coordinator and router)
        if currentModalCoordinator != nil {
            dismissModal()
        }
    }

    // Override navigate to handle tab switching intelligently
    override public func navigate(to route: any Route, from caller: AnyCoordinator? = nil) -> Bool {
        print("📑 \(Self.self): Tab navigation to \(route.identifier)")

        // First check if we can handle it directly
        if let typedRoute = route as? R, canHandle(typedRoute) {
            // Let the base class handle execution
            return super.navigate(to: route, from: caller)
        }

        // Try current tab first, but not if it's the caller (prevents infinite loop)
        let currentTabIndex = router.state.selectedTab
        if currentTabIndex < children.count {
            let currentTab = children[currentTabIndex]
            // Skip current tab if it's the one calling us (it already tried and failed)
            // Also check canNavigate first to avoid trying tabs that can't handle it
            if currentTab !== caller, currentTab.canNavigate(to: route) {
                if currentTab.navigate(to: route, from: self) {
                    print("📑 \(Self.self): Current tab handled \(route.identifier)")
                    return true
                }
            }
        }

        // Current tab couldn't handle it - check other tabs
        // Here we MUST use canNavigate to avoid switching to tabs that can't handle the route
        for (index, child) in children.enumerated() {
            if index != currentTabIndex, child !== caller, child.canNavigate(to: route) {
                print("🔄 \(Self.self): Switching to tab \(index) for \(route.identifier)")
                switchToTab(index)
                return child.navigate(to: route, from: self)
            }
        }

        // No child can handle it - bubble to parent
        // Call bubbleToParent directly instead of super.navigate which would delegate to children again
        return bubbleToParent(route: route)
    }
}
