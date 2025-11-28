//
//  TabCoordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 15/9/25.
//

import Foundation

/// A specialized coordinator for managing tab-based navigation with automatic tab switching.
///
/// `TabCoordinator` extends `Coordinator` to provide tab bar functionality, including automatic
/// tab switching when navigating to routes handled by different tabs. Child coordinators added
/// to a `TabCoordinator` automatically become tabs.
///
/// ## Basic Usage
///
/// Create a TabCoordinator and add child coordinators as tabs:
///
/// ```swift
/// class MainTabCoordinator: TabCoordinator<AppRoute> {
///     init() {
///         let router = Router(initial: .home, factory: AppViewFactory())
///         super.init(router: router)
///
///         // Add child coordinators - each becomes a tab
///         addChild(HomeCoordinator())
///         addChild(SearchCoordinator())
///         addChild(ProfileCoordinator())
///     }
/// }
/// ```
///
/// Each child coordinator should override `tabItem` to define its tab bar appearance:
///
/// ```swift
/// class HomeCoordinator: Coordinator<HomeRoute> {
///     override var tabItem: (text: String, image: String)? {
///         return ("Home", "house.fill")
///     }
/// }
/// ```
///
/// ## Automatic Tab Switching
///
/// When you navigate to a route, `TabCoordinator` automatically switches to the tab
/// that can handle that route. This enables deep linking and cross-tab navigation
/// without manual tab selection:
///
/// ```swift
/// // From anywhere in the app, navigate to a profile route
/// // TabCoordinator will automatically switch to the Profile tab
/// coordinator.navigate(to: ProfileRoute.detail(userId: "123"))
/// ```
///
/// ## Manual Tab Selection
///
/// You can also switch tabs programmatically:
///
/// ```swift
/// class MainTabCoordinator: TabCoordinator<AppRoute> {
///     func showNotifications() {
///         switchToTab(2)  // Switch to third tab (0-indexed)
///     }
/// }
/// ```
///
/// ## See Also
///
/// - `Coordinator` - Base coordinator class
/// - `TabCoordinatorView` - SwiftUI view that renders the tab bar UI
open class TabCoordinator<R: Route>: Coordinator<R> {
    /// Build a TabCoordinatorView for this tab coordinator
    override public func buildCoordinatorView() -> Any {
        return TabCoordinatorView(coordinator: self)
    }

    /// Override addChild to automatically set .tab context for tab children
    override public func addChild(_ coordinator: Coordinator<some Route>) {
        // TabCoordinator children are always tabs, so use .tab context
        super.addChild(coordinator, context: .tab)
    }

    /// Get the tab index for a coordinator
    /// **Framework internal only**
    func getTabIndex(for coordinator: AnyCoordinator) -> Int? {
        for (index, child) in internalChildren.enumerated() {
            if child === coordinator {
                return index
            }
        }
        return nil
    }

    /// Programmatically switch to a specific tab by index.
    ///
    /// This method allows you to change the selected tab from code, such as in response
    /// to deep links, notifications, or user actions in other parts of the UI.
    ///
    /// ## Example
    ///
    /// ```swift
    /// class MainTabCoordinator: TabCoordinator<AppRoute> {
    ///     func showNotifications() {
    ///         switchToTab(2)  // Switch to notifications tab
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter index: The zero-based index of the tab to switch to
    /// - Note: The framework will report an error if the index is out of bounds
    open func switchToTab(_ index: Int) {
        // Validate tab index
        guard index >= 0, index < internalChildren.count else {
            let error = SwiftUIFlowError.invalidTabIndex(index: index,
                                                         validRange: 0 ..< internalChildren.count)
            reportError(error)
            return
        }
        router.selectTab(index)
    }

    override func cleanStateForBubbling() {
        // TabCoordinators don't clean their stack when bubbling
        // They only dismiss modals (dismissModal handles both coordinator and router)
        if currentModalCoordinator != nil {
            dismissModal()
        }
    }

    /// Override to use TabCoordinator-specific validation logic
    /// **Framework internal only**
    override func validateNavigationPath(to route: any Route, from caller: AnyCoordinator?) -> ValidationResult {
        return validateNavigationPathTabImpl(to: route, from: caller)
    }

    /// Internal navigation with caller tracking - overridden for tab logic
    /// **Framework internal only**
    override func navigate(to route: any Route, from caller: AnyCoordinator?) -> Bool {
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
        if currentTabIndex < internalChildren.count {
            let currentTab = internalChildren[currentTabIndex]
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
        for (index, child) in internalChildren.enumerated() {
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
        if currentTabIndex < internalChildren.count {
            let currentTab = internalChildren[currentTabIndex]
            // Skip current tab if it's the one calling us (it already tried and failed)
            if currentTab !== caller, currentTab.canNavigate(to: route) {
                let currentTabResult = currentTab.validateNavigationPath(to: route, from: self)
                if currentTabResult.isSuccess {
                    return currentTabResult
                }
            }
        }

        // Current tab couldn't handle it - check other tabs
        for (index, child) in internalChildren.enumerated() {
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
