//
//  Coordinators.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import Foundation
import OSLog
import SwiftUIFlow

// MARK: - App Coordinator (Root Orchestrator)

/// Root coordinator that orchestrates major app flows.
/// Manages transitions between Login and MainTab coordinators.
/// Never recreated - exists for the lifetime of the app.
class AppCoordinator: FlowOrchestrator<AppRoute> {
    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .login, factory: factory))
        factory.coordinator = self
        // Start with login flow
        transitionToFlow(LoginCoordinator(), root: .login)
    }

    override func canHandle(_ route: any Route) -> Bool {
        // AppCoordinator doesn't directly handle routes - it delegates to child flow coordinators
        return false
    }

    /// Check if this coordinator can handle flow changes (without executing them).
    /// Used during navigation validation to avoid side effects.
    override func canHandleFlowChange(to route: any Route) -> Bool {
        guard let appRoute = route as? AppRoute else { return false }
        return appRoute == .login || appRoute == .tabRoot
    }

    /// Handle flow changes when routes bubble to the root.
    /// This is called when LoginCoordinator or any child coordinator navigates
    /// to an AppRoute that they can't handle - it bubbles here for orchestration.
    override func handleFlowChange(to route: any Route) -> Bool {
        guard let appRoute = route as? AppRoute else {
            return false
        }

        switch appRoute {
        case .login:
            transitionToFlow(LoginCoordinator(), root: .login)
            return true
        case .tabRoot:
            transitionToFlow(MainTabCoordinator(), root: .tabRoot)
            return true
        }
    }
}

// MARK: - Login Coordinator

/// Login flow coordinator.
/// Handles login, signup, forgot password flows.
/// Created fresh on logout, deallocated after successful login.
class LoginCoordinator: Coordinator<AppRoute> {
    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .login, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        guard let appRoute = route as? AppRoute else { return false }
        return appRoute == .login
    }

    deinit {
        Logger(subsystem: "com.swiftuiflow.example", category: "Lifecycle").info("🗑️ LoginCoordinator deallocated")
    }
}

// MARK: - Main Tab Coordinator

/// Main tab coordinator that manages the 5 tabs.
/// This coordinator is RECREATED each time the user logs in,
/// ensuring fresh state and allowing service calls to run.
class MainTabCoordinator: TabCoordinator<AppRoute> {
    var redCoordinator: RedCoordinator!
    var greenCoordinator: GreenCoordinator!
    var blueCoordinator: BlueCoordinator!
    var yellowCoordinator: YellowCoordinator!
    var purpleCoordinator: PurpleCoordinator!

    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .tabRoot, factory: factory))
        factory.coordinator = self

        // Create fresh child coordinators
        redCoordinator = RedCoordinator()
        greenCoordinator = GreenCoordinator()
        blueCoordinator = BlueCoordinator()
        yellowCoordinator = YellowCoordinator()
        purpleCoordinator = PurpleCoordinator()

        addChild(redCoordinator)
        addChild(greenCoordinator)
        addChild(blueCoordinator)
        addChild(yellowCoordinator)
        addChild(purpleCoordinator)
    }

    override func canHandle(_ route: any Route) -> Bool {
        // MainTabCoordinator only delegates to children, never handles directly
        return false
    }

    deinit {
        Logger(subsystem: "com.swiftuiflow.example", category: "Lifecycle").info("🗑️ MainTabCoordinator deallocated")
    }
}

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

class RedModalCoordinator: Coordinator<RedRoute> {
    init() {
        let factory = RedViewFactory()
        super.init(router: Router(initial: .darkRed, factory: factory))
        factory.coordinator = self
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
        if let deepBlueRoute = route as? DeepBlueRoute {
            switch deepBlueRoute {
            case .level1:
                return nil // Already at root level
            case .level2:
                return [DeepBlueRoute.level1, DeepBlueRoute.level2]
            case .level3:
                return [DeepBlueRoute.level1, DeepBlueRoute.level2, DeepBlueRoute.level3]
            case .level3Modal, .level3NestedModal:
                // Modals require being at level3 first - build path to level3
                // After path is built, the modal will be presented
                return [DeepBlueRoute.level1, DeepBlueRoute.level2, DeepBlueRoute.level3]
            }
        }

        // Handle OceanRoute paths - Ocean is presented from level3Modal's nested modal
        // So we need to be at level3 before the modals can be presented
        if route is OceanRoute {
            // Build path to level3, then modals will be presented, then Ocean will be pushed
            return [DeepBlueRoute.level1, DeepBlueRoute.level2, DeepBlueRoute.level3]
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

class YellowModalCoordinator: Coordinator<YellowRoute> {
    init() {
        let factory = YellowViewFactory()
        super.init(router: Router(initial: .darkYellow, factory: factory))
        factory.coordinator = self
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
    init() {
        let factory = RainbowViewFactory()
        super.init(router: Router(initial: .red, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is RainbowRoute
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
        // This is only called when stack is empty (deeplink scenario)
        // You can check current state to determine which path to build
        switch oceanRoute {
        case .surface:
            return [OceanRoute.surface]
        case .shallow:
            return [OceanRoute.shallow]
        case .deep:
            // Example: Could have multiple paths based on some condition
            // if someCondition {
            //     return [OceanRoute.shallow, OceanRoute.deep] // Scenic route
            // } else {
            //     return [OceanRoute.deep] // Direct route
            // }
            return [OceanRoute.shallow, OceanRoute.deep]
        case .abyss:
            return [OceanRoute.shallow, OceanRoute.deep, OceanRoute.abyss]
        }
    }
}
