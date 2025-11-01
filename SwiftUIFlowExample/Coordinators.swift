//
//  Coordinators.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import Foundation
import SwiftUIFlow

// MARK: - App Coordinator (Tab Coordinator)

class AppCoordinator: TabCoordinator<AppRoute> {
    var redCoordinator: RedCoordinator!
    var greenCoordinator: GreenCoordinator!
    var blueCoordinator: BlueCoordinator!
    var yellowCoordinator: YellowCoordinator!
    var purpleCoordinator: PurpleCoordinator!

    init() {
        let viewFactory = AppViewFactory()
        let router = Router(initial: .tabRoot, factory: viewFactory)
        super.init(router: router)

        // Set the appCoordinator reference on the view factory
        viewFactory.appCoordinator = self

        // Now create coordinators with self reference
        redCoordinator = RedCoordinator(appCoordinator: self)
        greenCoordinator = GreenCoordinator(appCoordinator: self)
        blueCoordinator = BlueCoordinator(appCoordinator: self)
        yellowCoordinator = YellowCoordinator(appCoordinator: self)
        purpleCoordinator = PurpleCoordinator(appCoordinator: self)

        addChild(redCoordinator)
        addChild(greenCoordinator)
        addChild(blueCoordinator)
        addChild(yellowCoordinator)
        addChild(purpleCoordinator)
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is AppRoute
    }
}

// MARK: - Red Tab Coordinator

class RedCoordinator: Coordinator<RedRoute> {
    init(appCoordinator: AppCoordinator) {
        let viewFactory = RedViewFactory()
        viewFactory.appCoordinator = appCoordinator
        let router = Router(initial: .red, factory: viewFactory)
        super.init(router: router)

        let modalCoord = RedModalCoordinator(appCoordinator: appCoordinator)
        addModalCoordinator(modalCoord)
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is RedRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let redRoute = route as? RedRoute else { return .push }

        switch redRoute {
        case .red, .lightRed:
            return .push
        case .darkRed:
            return .modal
        }
    }
}

class RedModalCoordinator: Coordinator<RedRoute> {
    init(appCoordinator: AppCoordinator) {
        let viewFactory = RedViewFactory()
        viewFactory.appCoordinator = appCoordinator
        let router = Router(initial: .darkRed, factory: viewFactory)
        super.init(router: router)
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let redRoute = route as? RedRoute else { return false }
        return redRoute == .darkRed
    }
}

// MARK: - Green Tab Coordinator

class GreenCoordinator: Coordinator<GreenRoute> {
    init(appCoordinator: AppCoordinator) {
        let viewFactory = GreenViewFactory()
        viewFactory.appCoordinator = appCoordinator
        let router = Router(initial: .green, factory: viewFactory)
        super.init(router: router)

        let modalCoord = GreenModalCoordinator(appCoordinator: appCoordinator)
        addModalCoordinator(modalCoord)
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is GreenRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let greenRoute = route as? GreenRoute else { return .push }

        switch greenRoute {
        case .green, .lightGreen:
            return .push
        case .darkGreen:
            return .modal
        }
    }
}

class GreenModalCoordinator: Coordinator<GreenRoute> {
    init(appCoordinator: AppCoordinator) {
        let viewFactory = GreenViewFactory()
        viewFactory.appCoordinator = appCoordinator
        let router = Router(initial: .darkGreen, factory: viewFactory)
        super.init(router: router)
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let greenRoute = route as? GreenRoute else { return false }
        return greenRoute == .darkGreen
    }
}

// MARK: - Blue Tab Coordinator

class BlueCoordinator: Coordinator<BlueRoute> {
    init(appCoordinator: AppCoordinator) {
        let viewFactory = BlueViewFactory()
        viewFactory.appCoordinator = appCoordinator
        let router = Router(initial: .blue, factory: viewFactory)
        super.init(router: router)

        let modalCoord = BlueModalCoordinator(appCoordinator: appCoordinator)
        addModalCoordinator(modalCoord)
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is BlueRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let blueRoute = route as? BlueRoute else { return .push }

        switch blueRoute {
        case .blue, .lightBlue:
            return .push
        case .darkBlue:
            return .modal
        }
    }
}

class BlueModalCoordinator: Coordinator<BlueRoute> {
    init(appCoordinator: AppCoordinator) {
        let viewFactory = BlueViewFactory()
        viewFactory.appCoordinator = appCoordinator
        let router = Router(initial: .darkBlue, factory: viewFactory)
        super.init(router: router)
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let blueRoute = route as? BlueRoute else { return false }
        return blueRoute == .darkBlue
    }
}

// MARK: - Yellow Tab Coordinator

class YellowCoordinator: Coordinator<YellowRoute> {
    init(appCoordinator: AppCoordinator) {
        let viewFactory = YellowViewFactory()
        viewFactory.appCoordinator = appCoordinator
        let router = Router(initial: .yellow, factory: viewFactory)
        super.init(router: router)

        let modalCoord = YellowModalCoordinator(appCoordinator: appCoordinator)
        addModalCoordinator(modalCoord)
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is YellowRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let yellowRoute = route as? YellowRoute else { return .push }

        switch yellowRoute {
        case .yellow, .lightYellow:
            return .push
        case .darkYellow:
            return .modal
        }
    }
}

class YellowModalCoordinator: Coordinator<YellowRoute> {
    init(appCoordinator: AppCoordinator) {
        let viewFactory = YellowViewFactory()
        viewFactory.appCoordinator = appCoordinator
        let router = Router(initial: .darkYellow, factory: viewFactory)
        super.init(router: router)
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let yellowRoute = route as? YellowRoute else { return false }
        return yellowRoute == .darkYellow
    }
}

// MARK: - Purple Tab Coordinator

class PurpleCoordinator: Coordinator<PurpleRoute> {
    init(appCoordinator: AppCoordinator) {
        let viewFactory = PurpleViewFactory()
        viewFactory.appCoordinator = appCoordinator
        let router = Router(initial: .purple, factory: viewFactory)
        super.init(router: router)

        let modalCoord = PurpleModalCoordinator(appCoordinator: appCoordinator)
        addModalCoordinator(modalCoord)
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is PurpleRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let purpleRoute = route as? PurpleRoute else { return .push }

        switch purpleRoute {
        case .purple, .lightPurple:
            return .push
        case .darkPurple:
            return .modal
        case .result:
            return .replace
        }
    }
}

class PurpleModalCoordinator: Coordinator<PurpleRoute> {
    init(appCoordinator: AppCoordinator) {
        let viewFactory = PurpleViewFactory()
        viewFactory.appCoordinator = appCoordinator
        let router = Router(initial: .darkPurple, factory: viewFactory)
        super.init(router: router)
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let purpleRoute = route as? PurpleRoute else { return false }
        return purpleRoute == .darkPurple
    }
}
