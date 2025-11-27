//
//  CoordinatorPresentationContext.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 4/11/25.
//

import Foundation

/// Defines how a coordinator is presented in the navigation hierarchy.
///
/// **Framework internal only.** This determines the presentation style and whether
/// the coordinator's root view should show a back button. The framework automatically
/// assigns the appropriate context when coordinators are added.
///
/// ## Automatic Assignment
///
/// - `TabCoordinator.addChild()` automatically uses `.tab`
/// - Regular `Coordinator.addChild()` uses `.pushed`
/// - Modal coordinators are assigned `.modal` by the framework
/// - Detour coordinators are assigned `.detour` by the framework
/// - Root coordinators default to `.root`
enum CoordinatorPresentationContext {
    /// The root coordinator of the application.
    /// Root views in this coordinator do NOT show back buttons.
    case root

    /// A coordinator that's a tab in a TabCoordinator.
    /// Root views in tab coordinators do NOT show back buttons.
    case tab

    /// A coordinator that's pushed as a child in a regular navigation flow.
    /// Root views in pushed coordinators SHOULD show back buttons.
    case pushed

    /// A coordinator presented as a modal sheet.
    /// Root views in modal coordinators COULD show back buttons (to dismiss).
    case modal

    /// A coordinator presented as a detour (fullScreenCover).
    /// Root views in detour coordinators SHOULD show back buttons (to dismiss).
    case detour

    /// Whether this presentation context should show a back button on the coordinator's root view.
    var shouldShowBackButton: Bool {
        switch self {
        case .root, .tab:
            return false
        case .pushed, .modal, .detour:
            return true
        }
    }
}
