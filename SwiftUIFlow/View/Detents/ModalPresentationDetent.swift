//
//  ModalPresentationDetent.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 9/11/25.
//

import SwiftUI

/// Defines how a modal sheet should be presented in terms of its height.
///
/// This enum provides a declarative way to control modal presentation detents,
/// including an automatic content-based sizing option.
///
/// ## Example Usage
///
/// ```swift
/// // Simple fixed detent
/// coordinator.presentModal(modalCoordinator, presenting: .settings, detent: .medium)
///
/// // Content-sized modal (automatic height)
/// coordinator.presentModal(modalCoordinator, presenting: .details, detent: .custom)
///
/// // Multiple detents with selection
/// coordinator.presentModal(
///     modalCoordinator,
///     presenting: .options,
///     detents: [.small, .medium, .custom],
///     selectedDetent: .custom
/// )
/// ```
public enum ModalPresentationDetent: Equatable {
    /// A small detent, typically the shortest height.
    /// Maps to a height calculated from the modal's minimum content (e.g., header only).
    case small

    /// A medium detent, typically a mid-range height.
    /// Maps to SwiftUI's native `.medium` detent (~50% screen height).
    case medium

    /// A large detent, typically the full screen or maximum height.
    /// Maps to `.fraction(0.999)` to avoid the 3D push effect.
    case large

    /// An extra large detent, taking up the entire screen with native behavior.
    /// Maps to SwiftUI's native `.large` detent (100% screen height).
    /// Note: This is still a sheet, not a fullScreenCover.
    case extraLarge

    /// True fullscreen presentation using fullScreenCover.
    /// Presents the modal using fullScreenCover instead of sheet.
    /// Cannot be combined with other detents.
    case fullscreen

    /// An automatic detent based on the content size.
    /// The modal will size itself to fit its content exactly.
    /// Uses GeometryReader and PreferenceKeys to measure content dynamically.
    case custom
}

/// Configuration for modal presentation detents, including height measurements.
public struct ModalDetentConfiguration: Equatable {
    /// The available detents for the modal
    public let detents: [ModalPresentationDetent]

    /// The currently selected detent (if multiple detents are provided)
    public var selectedDetent: ModalPresentationDetent?

    /// Measured minimum height (typically header only, used for .small)
    public var minHeight: CGFloat?

    /// Measured ideal height (all content, used for .custom)
    public var idealHeight: CGFloat?

    public init(detents: [ModalPresentationDetent] = [.large],
                selectedDetent: ModalPresentationDetent? = nil,
                minHeight: CGFloat? = nil,
                idealHeight: CGFloat? = nil)
    {
        self.detents = detents
        self.selectedDetent = selectedDetent
        self.minHeight = minHeight
        self.idealHeight = idealHeight
    }

    /// Check if this configuration should use fullScreenCover instead of sheet
    /// Only uses fullScreenCover when .fullscreen is the ONLY detent
    /// When combined with other detents (e.g., [.custom, .fullscreen]), uses sheet with .large
    var shouldUseFullScreenCover: Bool {
        return detents == [.fullscreen]
    }

    /// Convert a ModalPresentationDetent to SwiftUI's PresentationDetent
    func toPresentationDetent(_ detent: ModalPresentationDetent) -> PresentationDetent {
        switch detent {
        case .small:
            return .height(minHeight ?? 100)
        case .medium:
            return .medium
        case .large:
            // Use 0.999 fraction to avoid 3D effect that pushes the presenting view behind
            return .fraction(0.999)
        case .extraLarge:
            // Use native .large for maximum sheet height
            return .large
        case .fullscreen:
            // This shouldn't be used with sheet - handled separately with fullScreenCover
            return .large
        case .custom:
            return .height(idealHeight ?? 200)
        }
    }

    /// Map from SwiftUI's PresentationDetent back to ModalPresentationDetent
    func fromPresentationDetent(_ detent: PresentationDetent) -> ModalPresentationDetent? {
        // Check if it matches our custom height
        if detent == .height(idealHeight ?? 0) {
            return .custom
        }

        // Check if it matches our small height
        if detent == .height(minHeight ?? 0) {
            return .small
        }

        // Check standard detents
        if detent == .medium {
            return .medium
        }

        if detent == .fraction(0.999) {
            return .large
        }

        if detent == .large {
            // If .fullscreen is in our detents array, map SwiftUI's .large to .fullscreen
            // Otherwise map to .extraLarge
            return detents.contains(.fullscreen) ? .fullscreen : .extraLarge
        }

        return nil
    }

    public static func == (lhs: ModalDetentConfiguration, rhs: ModalDetentConfiguration) -> Bool {
        lhs.detents == rhs.detents &&
            lhs.selectedDetent == rhs.selectedDetent &&
            lhs.minHeight == rhs.minHeight &&
            lhs.idealHeight == rhs.idealHeight
    }
}
