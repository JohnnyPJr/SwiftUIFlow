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

        // Now create coordinators
        redCoordinator = RedCoordinator()
        greenCoordinator = GreenCoordinator()
        blueCoordinator = BlueCoordinator()
        yellowCoordinator = YellowCoordinator()
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
    init() {
        let viewFactory = RedViewFactory()
        let router = Router(initial: .red, factory: viewFactory)
        super.init(router: router)

        viewFactory.coordinator = self

        let modalCoord = RedModalCoordinator()
        addModalCoordinator(modalCoord)
    }

    override var tabItem: (text: String, image: String)? {
        return ("Red", "paintpalette.fill")
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
    init() {
        let viewFactory = RedViewFactory()
        let router = Router(initial: .darkRed, factory: viewFactory)
        super.init(router: router)

        viewFactory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let redRoute = route as? RedRoute else { return false }
        return redRoute == .darkRed
    }
}

// MARK: - Green Tab Coordinator

class GreenCoordinator: Coordinator<GreenRoute> {
    init() {
        let viewFactory = GreenViewFactory()
        let router = Router(initial: .green, factory: viewFactory)
        super.init(router: router)

        viewFactory.coordinator = self

        let modalCoord = GreenModalCoordinator()
        addModalCoordinator(modalCoord)
    }

    override var tabItem: (text: String, image: String)? {
        return ("Green", "leaf.fill")
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
    init() {
        let viewFactory = GreenViewFactory()
        let router = Router(initial: .darkGreen, factory: viewFactory)
        super.init(router: router)

        viewFactory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let greenRoute = route as? GreenRoute else { return false }
        return greenRoute == .darkGreen
    }
}

// MARK: - Blue Tab Coordinator

class BlueCoordinator: Coordinator<BlueRoute> {
    init() {
        let viewFactory = BlueViewFactory()
        let router = Router(initial: .blue, factory: viewFactory)
        super.init(router: router)

        viewFactory.coordinator = self

        let modalCoord = BlueModalCoordinator()
        addModalCoordinator(modalCoord)
    }

    override var tabItem: (text: String, image: String)? {
        return ("Blue", "water.waves")
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
    init() {
        let viewFactory = BlueViewFactory()
        let router = Router(initial: .darkBlue, factory: viewFactory)
        super.init(router: router)

        viewFactory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let blueRoute = route as? BlueRoute else { return false }
        return blueRoute == .darkBlue
    }
}

// MARK: - Yellow Tab Coordinator

class YellowCoordinator: Coordinator<YellowRoute> {
    init() {
        let viewFactory = YellowViewFactory()
        let router = Router(initial: .yellow, factory: viewFactory)
        super.init(router: router)

        viewFactory.coordinator = self

        let modalCoord = YellowModalCoordinator()
        addModalCoordinator(modalCoord)
    }

    override var tabItem: (text: String, image: String)? {
        return ("Yellow", "sun.max.fill")
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
    init() {
        let viewFactory = YellowViewFactory()
        let router = Router(initial: .darkYellow, factory: viewFactory)
        super.init(router: router)

        viewFactory.coordinator = self
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
        let router = Router(initial: .purple, factory: viewFactory)
        super.init(router: router)

        viewFactory.coordinator = self
        viewFactory.appCoordinator = appCoordinator

        let modalCoord = PurpleModalCoordinator()
        addModalCoordinator(modalCoord)
    }

    override var tabItem: (text: String, image: String)? {
        return ("Purple", "sparkles")
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
    init() {
        let viewFactory = PurpleViewFactory()
        let router = Router(initial: .darkPurple, factory: viewFactory)
        super.init(router: router)

        viewFactory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let purpleRoute = route as? PurpleRoute else { return false }
        return purpleRoute == .darkPurple
    }
}
