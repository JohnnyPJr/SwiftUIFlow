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
/// Multiple sections can report their heights, which are summed together.
///
/// ## Example Usage
///
/// ```swift
/// struct ModalContent: View {
///     @State private var headerHeight: CGFloat?
///     @State private var mainHeight: CGFloat?
///
///     var idealHeight: CGFloat? {
///         let heights = [headerHeight, mainHeight].compactMap { $0 }
///         return heights.isEmpty ? nil : heights.reduce(0, +)
///     }
///
///     var body: some View {
///         VStack {
///             HeaderView()
///                 .onSizeChange { headerHeight = $0.height }
///             MainView()
///                 .onSizeChange { mainHeight = $0.height }
///         }
///         .preference(key: IdealHeightPreferenceKey.self, value: idealHeight)
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
/// Multiple sections can report their heights, which are summed together.
///
/// ## Example Usage
///
/// ```swift
/// struct ModalContent: View {
///     @State private var headerHeight: CGFloat?
///
///     var minHeight: CGFloat? {
///         headerHeight
///     }
///
///     var body: some View {
///         VStack {
///             HeaderView()
///                 .onSizeChange { headerHeight = $0.height }
///             MainView()
///         }
///         .preference(key: MinHeightPreferenceKey.self, value: minHeight)
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
