//
//  SupportingCoordinators.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import Foundation
import OSLog
import SwiftUIFlow

class RedModalCoordinator: Coordinator<RedRoute> {
    init() {
        let factory = RedViewFactory()
        super.init(router: Router(initial: .darkRed, factory: factory))
        factory.coordinator = self
    }
}

class GreenModalCoordinator: Coordinator<GreenRoute> {
    init() {
        let factory = GreenViewFactory()
        super.init(router: Router(initial: .darkGreen, factory: factory))
        factory.coordinator = self

        // Add another modal coordinator for modal-upon-modal demo
        let darkestModalCoord = GreenDarkestModalCoordinator()
        addModalCoordinator(darkestModalCoord)
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let greenRoute = route as? GreenRoute else { return false }
        // Does NOT handle .darkGreen (its root), handles subsequent routes only
        return greenRoute == .evenDarkerGreen || greenRoute == .darkestGreen
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let greenRoute = route as? GreenRoute else { return .push }
        // darkestGreen is presented as modal on top of this modal
        return greenRoute == .darkestGreen ? .modal : .push
    }
}

class GreenDarkestModalCoordinator: Coordinator<GreenRoute> {
    init() {
        let factory = GreenViewFactory()
        super.init(router: Router(initial: .darkestGreen, factory: factory))
        factory.coordinator = self
    }
}

class BlueModalCoordinator: Coordinator<BlueRoute> {
    init() {
        let factory = BlueViewFactory()
        super.init(router: Router(initial: .darkBlue, factory: factory))
        factory.coordinator = self
    }
}

// MARK: - DeepBlue Coordinator (Pushed child with 3 levels → modal → ocean pushed child)

final class DeepBlueCoordinator: Coordinator<DeepBlueRoute> {
    var level3ModalCoordinator: DeepBlueLevel3ModalCoordinator!

    init() {
        let factory = DeepBlueViewFactory()
        super.init(router: Router(initial: .level1, factory: factory))
        factory.coordinator = self

        // Level 3 can present a modal
        level3ModalCoordinator = DeepBlueLevel3ModalCoordinator()
        addModalCoordinator(level3ModalCoordinator)
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let deepBlueRoute = route as? DeepBlueRoute else { return false }
        // Only handle routes up to level3Modal
        // level3NestedModal is handled by level3ModalCoordinator (not in our modalCoordinators)
        return deepBlueRoute != .level3NestedModal
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let deepBlueRoute = route as? DeepBlueRoute else { return .push }

        switch deepBlueRoute {
        case .level1, .level2, .level3:
            return .push
        case .level3Modal, .level3NestedModal:
            return .modal
        }
    }

    override func navigationPath(for route: any Route) -> [any Route]? {
        // Handle DeepBlueRoute paths
        // Paths should NOT include the root (level1) since we start there
        if let deepBlueRoute = route as? DeepBlueRoute {
            switch deepBlueRoute {
            case .level1:
                return nil // Already at root level
            case .level2:
                return [DeepBlueRoute.level2]
            case .level3:
                return [DeepBlueRoute.level2, DeepBlueRoute.level3]
            case .level3Modal, .level3NestedModal:
                // Modals require being at level3 first - build path to level3
                // After path is built, the modal will be presented
                return [DeepBlueRoute.level2, DeepBlueRoute.level3]
            }
        }

        // Handle OceanRoute paths - Ocean is presented from level3Modal's nested modal
        // So we need to be at level3 before the modals can be presented
        if route is OceanRoute {
            // Build path to level3, then modals will be presented, then Ocean will be pushed
            return [DeepBlueRoute.level2, DeepBlueRoute.level3]
        }

        return nil
    }
}

// MARK: - DeepBlue Level 3 Modal Coordinator (first modal)

final class DeepBlueLevel3ModalCoordinator: Coordinator<DeepBlueRoute> {
    var nestedModalCoordinator: DeepBlueNestedModalCoordinator!

    init() {
        let factory = DeepBlueViewFactory()
        super.init(router: Router(initial: .level3Modal, factory: factory))
        factory.coordinator = self

        // Add nested modal coordinator that contains Ocean
        nestedModalCoordinator = DeepBlueNestedModalCoordinator()
        addModalCoordinator(nestedModalCoordinator)
    }

    override func canHandle(_ route: any Route) -> Bool {
        // Does NOT handle .level3Modal (its root), handles .level3NestedModal
        guard let deepBlueRoute = route as? DeepBlueRoute else { return false }
        return deepBlueRoute == .level3NestedModal
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let deepBlueRoute = route as? DeepBlueRoute else { return .push }
        return deepBlueRoute == .level3NestedModal ? .modal : .push
    }
}

// MARK: - DeepBlue Nested Modal Coordinator (second modal with Ocean as pushed child)

final class DeepBlueNestedModalCoordinator: Coordinator<DeepBlueRoute> {
    var oceanCoordinator: OceanCoordinator!

    init() {
        let factory = DeepBlueViewFactory()
        super.init(router: Router(initial: .level3NestedModal, factory: factory))
        factory.coordinator = self

        // Add Ocean coordinator as PUSHED CHILD
        oceanCoordinator = OceanCoordinator()
        addChild(oceanCoordinator)
    }

    override func canHandle(_ route: any Route) -> Bool {
        // Does NOT handle .level3NestedModal (its root), delegates to oceanCoordinator child
        return false
    }

    override func navigationType(for route: any Route) -> NavigationType {
        return .push
    }
}

class YellowModalCoordinator: Coordinator<YellowRoute> {
    init() {
        let factory = YellowViewFactory()
        super.init(router: Router(initial: .darkYellow, factory: factory))
        factory.coordinator = self
    }
}

class PurpleModalCoordinator: Coordinator<PurpleRoute> {
    init() {
        let factory = PurpleViewFactory()
        super.init(router: Router(initial: .darkPurple, factory: factory))
        factory.coordinator = self
    }
}

// MARK: - Info Modal Coordinators

class RedInfoCoordinator: Coordinator<RedRoute> {
    init() {
        let factory = RedViewFactory()
        super.init(router: Router(initial: .info, factory: factory))
        factory.coordinator = self
    }
}

class GreenInfoCoordinator: Coordinator<GreenRoute> {
    init() {
        let factory = GreenViewFactory()
        super.init(router: Router(initial: .info, factory: factory))
        factory.coordinator = self
    }
}

class BlueInfoCoordinator: Coordinator<BlueRoute> {
    init() {
        let factory = BlueViewFactory()
        super.init(router: Router(initial: .info, factory: factory))
        factory.coordinator = self
    }
}

class YellowInfoCoordinator: Coordinator<YellowRoute> {
    init() {
        let factory = YellowViewFactory()
        super.init(router: Router(initial: .info, factory: factory))
        factory.coordinator = self
    }
}

class PurpleInfoCoordinator: Coordinator<PurpleRoute> {
    init() {
        let factory = PurpleViewFactory()
        super.init(router: Router(initial: .info, factory: factory))
        factory.coordinator = self
    }
}

// MARK: - Rainbow Coordinator (Testing Pushed Children)

final class RainbowCoordinator: Coordinator<RainbowRoute> {
    private let detailPath: [RainbowRoute] = [.orange, .yellow, .green, .blue, .purple]
    var detailCoordinator: RainbowDetailCoordinator!

    init() {
        let factory = RainbowViewFactory()
        super.init(router: Router(initial: .red, factory: factory))
        factory.coordinator = self

        detailCoordinator = RainbowDetailCoordinator()
        addChild(detailCoordinator)
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is RainbowRoute
    }

    override func navigationPath(for route: any Route) -> [any Route]? {
        if route is RainbowDetailRoute {
            return detailPath
        }

        guard let rainbowRoute = route as? RainbowRoute,
              let index = detailPath.firstIndex(of: rainbowRoute) else { return nil }

        return Array(detailPath.prefix(index + 1))
    }
}

final class RainbowDetailCoordinator: Coordinator<RainbowDetailRoute> {
    init() {
        let factory = RainbowDetailViewFactory()
        super.init(router: Router(initial: .detail, factory: factory))
        factory.coordinator = self

        let modalCoordinator = RainbowDetailModalCoordinator()
        addModalCoordinator(modalCoordinator)
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is RainbowDetailRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let route = route as? RainbowDetailRoute else { return .push }
        return route == .modal ? .modal : .push
    }

    override func modalDetentConfiguration(for route: any Route) -> ModalDetentConfiguration {
        route as? RainbowDetailRoute == .modal
            ? ModalDetentConfiguration(detents: [.medium])
            : ModalDetentConfiguration(detents: [.large])
    }
}

final class RainbowDetailModalCoordinator: Coordinator<RainbowDetailRoute> {
    init() {
        let factory = RainbowDetailViewFactory()
        super.init(router: Router(initial: .modal, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is RainbowDetailRoute
    }
}

// MARK: - Ocean Coordinator (Testing Deep Cross-Coordinator Navigation)

final class OceanCoordinator: Coordinator<OceanRoute> {
    init() {
        let factory = OceanViewFactory()
        super.init(router: Router(initial: .surface, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is OceanRoute
    }

    override func navigationPath(for route: any Route) -> [any Route]? {
        guard let oceanRoute = route as? OceanRoute else { return nil }

        // Define the sequential path for each ocean depth
        // Paths should NOT include the root (surface) since we start there
        switch oceanRoute {
        case .surface:
            return nil // Already at root
        case .shallow:
            return [OceanRoute.shallow]
        case .deep:
            // Example: Could have multiple paths based on some condition
            // if someCondition {
            //     return [OceanRoute.shallow, OceanRoute.deep] // Scenic route through shallow
            // } else {
            //     return [OceanRoute.deep] // Direct route
            // }
            return [OceanRoute.shallow, OceanRoute.deep]
        case .abyss:
            return [OceanRoute.shallow, OceanRoute.deep, OceanRoute.abyss]
        }
    }
}
