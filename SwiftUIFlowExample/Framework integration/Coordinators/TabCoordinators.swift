//
//  TabCoordinators.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import Foundation
import OSLog
import SwiftUIFlow

// MARK: - Red Tab Coordinator

class RedCoordinator: Coordinator<RedRoute> {
    var infoCoordinator: RedInfoCoordinator!
    var rainbowCoordinator: RainbowCoordinator!

    init(root: RedRoute = .red) {
        let factory = RedViewFactory()
        super.init(router: Router(initial: root, factory: factory))
        factory.coordinator = self
        let modalCoord = RedModalCoordinator()
        addModalCoordinator(modalCoord)

        infoCoordinator = RedInfoCoordinator()
        addModalCoordinator(infoCoordinator)

        // Add rainbow coordinator as child for testing pushed children
        rainbowCoordinator = RainbowCoordinator()
        addChild(rainbowCoordinator)
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
        case .darkRed, .info:
            return .modal
        }
    }

    override func modalDetentConfiguration(for route: any Route) -> ModalDetentConfiguration {
        guard let redRoute = route as? RedRoute else {
            return ModalDetentConfiguration(detents: [.large])
        }

        switch redRoute {
        case .info:
            return ModalDetentConfiguration(detents: [.custom, .medium],
                                            selectedDetent: .custom)
        default:
            return ModalDetentConfiguration(detents: [.large])
        }
    }
}

// MARK: - Green Tab Coordinator

class GreenCoordinator: Coordinator<GreenRoute> {
    var infoCoordinator: GreenInfoCoordinator!

    init() {
        let factory = GreenViewFactory()
        super.init(router: Router(initial: .green, factory: factory))
        factory.coordinator = self
        let modalCoord = GreenModalCoordinator()
        addModalCoordinator(modalCoord)

        infoCoordinator = GreenInfoCoordinator()
        addModalCoordinator(infoCoordinator)
    }

    override var tabItem: (text: String, image: String)? {
        return ("Green", "leaf.fill")
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let greenRoute = route as? GreenRoute else { return false }
        return greenRoute == .darkGreen || greenRoute == .lightGreen || greenRoute == .info
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let greenRoute = route as? GreenRoute else { return .push }

        switch greenRoute {
        case .green, .lightGreen, .evenDarkerGreen:
            return .push
        case .darkGreen, .info, .darkestGreen:
            return .modal
        }
    }

    override func modalDetentConfiguration(for route: any Route) -> ModalDetentConfiguration {
        guard let greenRoute = route as? GreenRoute else {
            return ModalDetentConfiguration(detents: [.large])
        }

        switch greenRoute {
        case .info:
            return ModalDetentConfiguration(detents: [.small])
        default:
            return ModalDetentConfiguration(detents: [.large])
        }
    }
}

// MARK: - Blue Tab Coordinator

class BlueCoordinator: Coordinator<BlueRoute> {
    var infoCoordinator: BlueInfoCoordinator!
    var deepBlueCoordinator: DeepBlueCoordinator!

    init() {
        let factory = BlueViewFactory()
        super.init(router: Router(initial: .blue, factory: factory))
        factory.coordinator = self
        let modalCoord = BlueModalCoordinator()
        addModalCoordinator(modalCoord)

        infoCoordinator = BlueInfoCoordinator()
        addModalCoordinator(infoCoordinator)

        // Add DeepBlue coordinator as child for testing complex nested navigation
        deepBlueCoordinator = DeepBlueCoordinator()
        addChild(deepBlueCoordinator)
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
        case .blue, .lightBlue, .invalidView:
            return .push
        case .darkBlue, .info:
            return .modal
        }
    }

    override func modalDetentConfiguration(for route: any Route) -> ModalDetentConfiguration {
        guard let blueRoute = route as? BlueRoute else {
            return ModalDetentConfiguration(detents: [.large])
        }

        switch blueRoute {
        case .info:
            return ModalDetentConfiguration(detents: [.medium])
        default:
            return ModalDetentConfiguration(detents: [.large])
        }
    }
}

// MARK: - Yellow Tab Coordinator

class YellowCoordinator: Coordinator<YellowRoute> {
    var infoCoordinator: YellowInfoCoordinator!

    init(root: YellowRoute = .yellow) {
        let factory = YellowViewFactory()
        super.init(router: Router(initial: root, factory: factory))
        factory.coordinator = self
        let modalCoord = YellowModalCoordinator()
        addModalCoordinator(modalCoord)

        infoCoordinator = YellowInfoCoordinator()
        addModalCoordinator(infoCoordinator)
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
        case .darkYellow, .info:
            return .modal
        }
    }

    override func modalDetentConfiguration(for route: any Route) -> ModalDetentConfiguration {
        guard let yellowRoute = route as? YellowRoute else {
            return ModalDetentConfiguration(detents: [.large])
        }

        switch yellowRoute {
        case .info:
            return ModalDetentConfiguration(detents: [.large])
        default:
            return ModalDetentConfiguration(detents: [.large])
        }
    }
}

// MARK: - Purple Tab Coordinator

class PurpleCoordinator: Coordinator<PurpleRoute> {
    var infoCoordinator: PurpleInfoCoordinator!

    init() {
        let factory = PurpleViewFactory()
        super.init(router: Router(initial: .purple, factory: factory))
        factory.coordinator = self
        let modalCoord = PurpleModalCoordinator()
        addModalCoordinator(modalCoord)

        infoCoordinator = PurpleInfoCoordinator()
        addModalCoordinator(infoCoordinator)
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
        case .darkPurple, .info:
            return .modal
        case .result:
            return .replace
        }
    }

    override func modalDetentConfiguration(for route: any Route) -> ModalDetentConfiguration {
        guard let purpleRoute = route as? PurpleRoute else {
            return ModalDetentConfiguration(detents: [.large])
        }

        switch purpleRoute {
        case .info:
            return ModalDetentConfiguration(detents: [.fullscreen])
        default:
            return ModalDetentConfiguration(detents: [.large])
        }
    }
}
