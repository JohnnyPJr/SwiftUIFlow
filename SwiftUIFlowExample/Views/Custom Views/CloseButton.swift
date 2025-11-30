//
//  CloseButton.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI
import SwiftUIFlow

/// A reusable modifier that adds a close button to modal views.
/// The button appears in the top-trailing corner and calls the navigationBackAction.
struct CloseButton: ViewModifier {
    @Environment(\.navigationBackAction) var backAction

    func body(content: Content) -> some View {
        ZStack(alignment: .topTrailing) {
            content

            Button {
                backAction?()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.primary.opacity(0.7))
            }
            .padding()
        }
    }
}

public extension View {
    /// Adds a close button in the top-trailing corner of the view.
    /// The button will call the navigationBackAction from the environment.
    func withCloseButton() -> some View {
        modifier(CloseButton())
    }
}
