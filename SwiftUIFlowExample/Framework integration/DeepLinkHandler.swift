//
//  DeepLinkHandler.swift
//  SwiftUIFlowExample
//
//  Created for testing deep link scenarios
//

import Foundation
import SwiftUIFlow

/// Simulates handling deep links from push notifications, URL schemes, etc.
/// Static methods allow calling from anywhere in the app without needing to pass around an instance
class DeepLinkHandler {
    // Store a weak reference to AppCoordinator that can be set once
    private weak static var appCoordinator: AppCoordinator?

    /// Configure the handler with the app coordinator (call once at app startup)
    static func configure(with coordinator: AppCoordinator) {
        appCoordinator = coordinator
    }

    // MARK: - Simulated Deep Link Scenarios

    /// Scenario 1: Navigate to Light Purple (cleans all state)
    /// Simulates: Push notification "Check out this new purple feature!"
    /// User could be anywhere (even deep in evenDarkerGreen modal)
    /// Expected: Dismisses modals, cleans stacks, switches to Purple tab, shows lightPurple
    static func simulateNavigateDeepLink() {
        guard let mainTab = appCoordinator?.currentFlow as? MainTabCoordinator else {
            print("❌ DeepLinkHandler: Not in main app")
            return
        }

        print("🔗 DeepLinkHandler: NAVIGATE to Light Purple")
        print("   - Simulating push notification received")
        print("   - This will clean all state (modals, stacks, pushed children)")
        print("   - User will lose their current context")

        // Navigate to the route - framework handles everything
        mainTab.navigate(to: GreenRoute.evenDarkerGreen)
    }

    /// Scenario 2: Present Detour to Light Purple (preserves all state)
    /// Simulates: Push notification "You have a message in purple section"
    /// User could be anywhere (even deep in evenDarkerGreen modal)
    /// Expected: Shows purple as detour, preserves all navigation context
    static func simulateDetourDeepLink() {
        guard let mainTab = appCoordinator?.currentFlow as? MainTabCoordinator else {
            print("❌ DeepLinkHandler: Not in main app")
            return
        }

        print("🔗 DeepLinkHandler: DETOUR to Light Purple")
        print("   - Simulating push notification received")
        print("   - This will preserve all state")
        print("   - User can tap back to return to their context")

        // Create a coordinator for the detour
        // In real app: coordinator/route would be determined by notification payload
        let detourCoordinator = YellowCoordinator(root: .lightYellow)

        mainTab.presentDetour(detourCoordinator, presenting: YellowRoute.lightYellow)
    }
}
