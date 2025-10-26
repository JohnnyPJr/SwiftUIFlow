//
//  TabCoordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 15/9/25.
//

import Foundation

open class TabCoordinator<R: Route>: Coordinator<R> {
    override open func navigationType(for route: any Route) -> NavigationType {
        // TabCoordinator subclasses MUST override this method to provide route-to-tab-index mapping
        fatalError("TabCoordinator subclass must override navigationType(for:) to provide route-to-tab-index mapping")
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
        if modalCoordinator != nil {
            dismissModal()
        }
    }

    // Override navigate to handle tab switching intelligently
    override public func navigate(to route: any Route, from caller: AnyCoordinator? = nil) -> Bool {
        print("📑 \(Self.self): Tab navigation to \(route.identifier)")

        // First check if we can handle it directly (unlikely for tab coordinator)
        if let typedRoute = route as? R, canHandle(typedRoute) {
            // Let the base class handle execution
            return super.navigate(to: route, from: caller)
        }

        // Check if current tab can handle it first (avoid unnecessary tab switches)
        let currentTabIndex = router.state.selectedTab
        if currentTabIndex < children.count {
            let currentTab = children[currentTabIndex]
            // Use canNavigate to check recursively
            if currentTab.canNavigate(to: route) {
                print("📑 \(Self.self): Current tab can handle \(route.identifier)")
                return currentTab.navigate(to: route, from: self)
            }
        }

        // Current tab can't handle it, check other tabs
        for (index, child) in children.enumerated() {
            if index != currentTabIndex, child.canNavigate(to: route) {
                print("🔄 \(Self.self): Switching to tab \(index) for \(route.identifier)")
                switchToTab(index)
                return child.navigate(to: route, from: self)
            }
        }

        // No child can handle it - bubble up
        return super.navigate(to: route, from: caller)
    }
}
