//
//  ModalHeightPreferenceKeys.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 9/11/25.
//

import SwiftUI

/// PreferenceKey for propagating the ideal (full content) height from child views to parent views.
///
/// This is used for the `.custom` detent to automatically size modals to their content.
/// **The framework automatically measures content height** - you don't need to do anything
/// for basic modals. This PreferenceKey is only needed for advanced multi-section modals.
///
/// ## Automatic Sizing (Most Common)
///
/// For most modals, just return your content and the framework measures it automatically:
///
/// ```swift
/// struct InfoView: View {
///     var body: some View {
///         VStack(spacing: 16) {
///             Text("Title").font(.title2)
///             Text("Description").font(.subheadline)
///         }
///         .padding()
///         // No measurement code needed - framework handles it automatically!
///     }
/// }
/// ```
///
/// ## Advanced: Multi-Section Modals
///
/// Only use this PreferenceKey directly when you need fine-grained control over
/// which sections contribute to ideal vs minimum height:
///
/// ```swift
/// struct AdvancedModalContent: View {
///     var body: some View {
///         VStack {
///             HeaderSection()
///                 .preference(key: IdealHeightPreferenceKey.self, value: 100)
///             MainSection()
///                 .preference(key: IdealHeightPreferenceKey.self, value: 200)
///             // Total ideal height = 300
///         }
///     }
/// }
/// ```
public struct IdealHeightPreferenceKey: PreferenceKey {
    public static var defaultValue: CGFloat?

    public static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        guard let current = value, let next = nextValue() else {
            value = value ?? nextValue()
            return
        }
        value = current + next
    }
}

/// PreferenceKey for propagating the minimum height from child views to parent views.
///
/// This is used for the `.small` detent to show only essential content (e.g., header only).
/// **The framework automatically measures content height** - this PreferenceKey is only
/// needed for advanced use cases where you want to control what's visible in the `.small` detent.
///
/// ## Automatic Sizing (Most Common)
///
/// For most modals, the framework automatically determines appropriate minimum height:
///
/// ```swift
/// struct InfoView: View {
///     var body: some View {
///         VStack(spacing: 16) {
///             Text("Title").font(.title2)
///             Text("Description").font(.subheadline)
///         }
///         .padding()
///         // Framework automatically handles both ideal and minimum heights!
///     }
/// }
/// ```
///
/// ## Advanced: Custom Small Detent Height
///
/// Only use this PreferenceKey when you need to specify exactly what's visible
/// in the `.small` detent state:
///
/// ```swift
/// struct AdvancedModalContent: View {
///     var body: some View {
///         VStack {
///             HeaderSection()
///                 .preference(key: MinHeightPreferenceKey.self, value: 80)
///             // Only header visible in .small detent
///             MainSection()
///         }
///     }
/// }
/// ```
public struct MinHeightPreferenceKey: PreferenceKey {
    public static var defaultValue: CGFloat?

    public static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        guard let current = value, let next = nextValue() else {
            value = value ?? nextValue()
            return
        }
        value = current + next
    }
}
