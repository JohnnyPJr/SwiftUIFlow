//
//  ViewUtilities.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI

/// Helper function to type-erase any value to AnyView
/// Used internally by CoordinatorView and TabCoordinatorView to handle type-erased coordinator views
func eraseToAnyView(_ view: Any) -> AnyView {
    if let swiftUIView = view as? any View {
        return AnyView(swiftUIView)
    } else {
        // This should never happen - buildCoordinatorView() always returns a View
        // If it does, it's a framework bug, not a user error
        NavigationLogger.error("❌ Type erasure failed: buildCoordinatorView() returned non-View type \(type(of: view))")
        return AnyView(EmptyView())
    }
}
