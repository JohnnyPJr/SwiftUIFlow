//
//  IntegrationTestHelpers.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 7/8/25.
//

import Foundation
import SwiftUI
@testable import SwiftUIFlow

// MARK: - Routes
enum MainTabRoute: Route {
    case tab1, tab2, tab3, tab4, tab5
    var identifier: String { "\(self)" }
}

enum Tab2Route: Route {
    case startUnlock
    var identifier: String { "\(self)" }
}

enum UnlockRoute: Route {
    case enterCode, loading, success
    var identifier: String { "\(self)" }
}

enum UnlockResultRoute: Route {
    case showResult
    var identifier: String { "\(self)" }
}

enum Tab5Route: Route {
    case batteryStatus
    var identifier: String { "\(self)" }
}

// MARK: - Factories

final class DummyFactory<R: Route>: ViewFactory<R> {
    override func buildView(for route: R) -> AnyView? {
        AnyView(EmptyView())
    }
}

// MARK: - Coordinators

// MARK: - MainTabCoordinator

final class MainTabCoordinator: TabCoordinator<MainTabRoute> {
    private let tab2: Tab2Coordinator
    private let tab5: Tab5Coordinator

    override init(router: Router<MainTabRoute>) {
        // Initialize tab coordinators
        tab2 = Tab2Coordinator(router: Router(initial: .startUnlock, factory: DummyFactory()))
        tab5 = Tab5Coordinator(router: Router(initial: .batteryStatus, factory: DummyFactory()))

        super.init(router: router)

        // Add them as children (now parent will be set correctly)
        // Adding placeholder coordinators for tabs 1, 3, 4
        addChild(Coordinator(router: Router(initial: MainTabRoute.tab1, factory: DummyFactory())))
        addChild(tab2)
        addChild(Coordinator(router: Router(initial: MainTabRoute.tab3, factory: DummyFactory())))
        addChild(Coordinator(router: Router(initial: MainTabRoute.tab4, factory: DummyFactory())))
        addChild(tab5)
    }

    override func canHandle(_ route: any Route) -> Bool {
        // Tab coordinator handles tab routes to switch tabs
        return route is MainTabRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        // Map MainTabRoute to tab indices
        guard let tabRoute = route as? MainTabRoute else {
            return .push // Not a tab route, use default
        }

        let tabIndex = switch tabRoute {
        case .tab1: 0
        case .tab2: 1
        case .tab3: 2
        case .tab4: 3
        case .tab5: 4
        }

        return .tabSwitch(index: tabIndex)
    }

    func switchTab(to index: Int) {
        switchToTab(index)
    }

    override func resetToCleanState() {
        super.resetToCleanState()
        // Reset all child tabs when main coordinator resets
        for child in children {
            child.resetToCleanState()
        }
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}

// MARK: - Tab2Coordinator

final class Tab2Coordinator: Coordinator<Tab2Route> {
    private var unlock: UnlockCoordinator?

    override func canHandle(_ route: any Route) -> Bool {
        // Tab2 can handle Tab2Routes directly
        guard let route = route as? Tab2Route else { return false }
        return route == .startUnlock
    }

    override func canNavigate(to route: any Route) -> Bool {
        // Can handle directly?
        if canHandle(route) {
            return true
        }

        // Will create UnlockCoordinator for UnlockRoutes
        if route is UnlockRoute {
            return true
        }

        // Check existing children
        return super.canNavigate(to: route)
    }

    override func navigate(to route: any Route, from caller: AnyCoordinator? = nil) -> Bool {
        // Special handling for UnlockRoute - ensure child exists
        if route is UnlockRoute, unlock == nil {
            unlock = UnlockCoordinator(router: Router(initial: .enterCode, factory: DummyFactory()))
            addChild(unlock!)
        }

        // Let base class handle the rest
        return super.navigate(to: route, from: caller)
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}

// MARK: - UnlockCoordinator

final class UnlockCoordinator: Coordinator<UnlockRoute> {
    var result: UnlockResultCoordinator?

    override func canHandle(_ route: any Route) -> Bool {
        guard let route = route as? UnlockRoute else { return false }

        switch route {
        case .enterCode, .loading:
            return true
        case .success:
            // Create and present result modal
            if result == nil {
                result = UnlockResultCoordinator(router: Router(initial: .showResult, factory: DummyFactory()))
                presentModal(result!, presenting: .success) // Handles both coordinator and router
            }
            return true
        }
    }

    override func shouldDismissModalFor(route: any Route) -> Bool {
        // Dismiss modal for non-unlock related routes
        return !(route is UnlockRoute || route is UnlockResultRoute)
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}

final class UnlockResultCoordinator: Coordinator<UnlockResultRoute> {
    override func canHandle(_ route: any Route) -> Bool {
        guard let route = route as? UnlockResultRoute else { return false }
        return route == .showResult
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}

// MARK: - Tab5Coordinator

final class Tab5Coordinator: Coordinator<Tab5Route> {
    private(set) var didHandleBatteryStatus = false

    override func canHandle(_ route: any Route) -> Bool {
        guard let route = route as? Tab5Route else { return false }

        if route == .batteryStatus {
            didHandleBatteryStatus = true
            return true
        }
        return false
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}
