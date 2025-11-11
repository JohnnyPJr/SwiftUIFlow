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
    /// This modifier uses a transparent GeometryReader overlay to measure the view's size
    /// without affecting the view's layout or appearance. It reports size changes both on
    /// initial appearance and whenever the size changes.
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// struct ContentSizedModal: View {
    ///     @State private var contentHeight: CGFloat?
    ///
    ///     var body: some View {
    ///         VStack {
    ///             Text("Dynamic Content")
    ///             // ... more content
    ///         }
    ///         .onSizeChange { size in
    ///             contentHeight = size.height
    ///         }
    ///     }
    /// }
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
