//
//  NavigationBackAction.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI

/// Environment key for the navigation back action.
/// This allows views to get the correct back action based on their context
/// (regular navigation, detour, modal, etc.)
private struct NavigationBackActionKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

/// Environment key to indicate if the current view can navigate back.
/// Root views in a navigation stack have this set to false.
private struct CanNavigateBackKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

public extension EnvironmentValues {
    /// The action to perform when the user taps a back button.
    /// In a detour, this will be `dismissDetour()`.
    /// In regular navigation, this will be `pop()`.
    var navigationBackAction: (() -> Void)? {
        get { self[NavigationBackActionKey.self] }
        set { self[NavigationBackActionKey.self] = newValue }
    }

    /// Indicates whether the current view can navigate back.
    /// This is false for root views in a navigation stack, true for pushed views.
    var canNavigateBack: Bool {
        get { self[CanNavigateBackKey.self] }
        set { self[CanNavigateBackKey.self] = newValue }
    }
}
