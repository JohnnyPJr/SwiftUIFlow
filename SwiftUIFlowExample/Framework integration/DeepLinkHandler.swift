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

    /// Scenario 1: Navigate to Even Darker Green (cleans all state)
    /// Simulates: Push notification "Check out this new feature!"
    /// User could be anywhere (even deep in a modal with pushed children)
    /// Expected: Dismisses modals, cleans stacks, switches to Green tab, navigates to evenDarkerGreen
    static func simulateNavigateDeepLink() {
        guard let mainTab = appCoordinator?.currentFlow as? MainTabCoordinator else {
            return
        }

        // Navigate to the route - framework handles everything
        // This will clean all state and navigate to the destination
        mainTab.navigate(to: GreenRoute.evenDarkerGreen)
    }

    /// Scenario 2: Present Detour to Light Yellow (preserves all state)
    /// Simulates: Push notification "You have a message!" - needs immediate attention but preserves context
    /// User could be anywhere (even deep in evenDarkerGreen modal)
    /// Expected: Shows yellow as fullscreen detour overlay, preserves all navigation context underneath
    ///
    /// This is the **realistic approach** for detours:
    /// - Detours are presented from a central location (AppCoordinator/MainTabCoordinator)
    /// - Used for app-wide interruptions: push notifications, alerts, system messages
    /// - User can dismiss to return to exactly where they were
    /// - Unlike navigate(), this PRESERVES the user's context
    static func simulateDetourDeepLink() {
        guard let mainTab = appCoordinator?.currentFlow as? MainTabCoordinator else {
            return
        }

        // Create a coordinator for the detour
        // In real app: coordinator/route would be determined by notification payload
        let detourCoordinator = YellowCoordinator(root: .lightYellow)

        // Present detour from central location (MainTabCoordinator)
        // This is how detours should be used in production apps
        mainTab.presentDetour(detourCoordinator, presenting: YellowRoute.lightYellow)
    }
}
