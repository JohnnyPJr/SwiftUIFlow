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

final class MainTabCoordinator: Coordinator<MainTabRoute> {
    private let tab2: Tab2Coordinator
    private let tab5: Tab5Coordinator

    override init(router: Router<MainTabRoute>) {
        // Initialize tab coordinators
        tab2 = Tab2Coordinator(router: Router(initial: .startUnlock, factory: DummyFactory()))
        tab5 = Tab5Coordinator(router: Router(initial: .batteryStatus, factory: DummyFactory()))

        super.init(router: router)

        // Add them as children (now parent will be set correctly)
        addChild(tab2)
        addChild(tab5)
    }

    func switchTab(to index: Int) {
        router.selectTab(index)
    }

    override func resetToCleanState() {
        super.resetToCleanState()
        // Reset all child tabs when main coordinator resets
        for child in children {
            child.resetToCleanState()
        }
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let route = route as? MainTabRoute else { return false }

        switch route {
        case .tab2:
            router.selectTab(1)
            return true
        case .tab5:
            router.selectTab(4)
            return true
        default:
            return false
        }
    }

    override func navigate(to route: any Route) -> Bool {
        if route is Tab5Route {
            router.selectTab(4)
        }
        return super.navigate(to: route)
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}

// MARK: - Tab2Coordinator

final class Tab2Coordinator: Coordinator<Tab2Route> {
    private let unlock: UnlockCoordinator

    override init(router: Router<Tab2Route>) {
        unlock = UnlockCoordinator(router: Router(initial: .enterCode, factory: DummyFactory()))
        super.init(router: router)

        addChild(unlock)
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let route = route as? Tab2Route else { return false }
        return route == .startUnlock
    }

    deinit {
        print("💀 Deinit: \(Self.self)")
    }
}

// MARK: - UnlockCoordinator

final class UnlockCoordinator: Coordinator<UnlockRoute> {
    let result: UnlockResultCoordinator = .init(router: Router(initial: .showResult, factory: DummyFactory()))

    override init(router: Router<UnlockRoute>) {
        super.init(router: router)
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let route = route as? UnlockRoute else { return false }

        switch route {
        case .enterCode, .loading:
            return true
        case .success:
            presentModal(result)
            return true
        }
    }

    override func navigate(to route: any Route) -> Bool {
        if let modal = modalCoordinator, !modal.canHandle(route) {
            dismissModal()
        }
        return super.navigate(to: route)
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
