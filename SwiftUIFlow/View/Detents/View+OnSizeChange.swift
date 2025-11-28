//
//  View+OnSizeChange.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 9/11/25.
//

import SwiftUI

public extension View {
    /// Observe the size of a view and execute a closure when it changes.
    ///
    /// **Framework internal utility.** This modifier is used internally by SwiftUIFlow
    /// to automatically measure modal content for the `.custom` detent. Client code
    /// does not need to use this modifier - modal sizing happens automatically.
    ///
    /// This modifier uses a transparent GeometryReader overlay to measure the view's size
    /// without affecting the view's layout or appearance. It reports size changes both on
    /// initial appearance and whenever the size changes.
    ///
    /// ## For Framework Development Only
    ///
    /// Used by `ModalContentMeasurement` to automatically track content height:
    ///
    /// ```swift
    /// content
    ///     .onSizeChange { size in
    ///         measuredHeight = size.height
    ///     }
    ///     .preference(key: IdealHeightPreferenceKey.self, value: measuredHeight)
    /// ```
    ///
    /// - Parameter closure: A closure that receives the new size whenever it changes
    /// - Returns: A view that reports its size changes
    func onSizeChange(_ closure: @escaping (CGSize) -> Void) -> some View {
        overlay {
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        closure(geometry.size)
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        closure(newSize)
                    }
            }
        }
    }
}
