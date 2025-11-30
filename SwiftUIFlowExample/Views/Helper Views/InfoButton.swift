//
//  InfoButton.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 9/11/25.
//

import SwiftUI
import SwiftUIFlow

/// A reusable modifier that adds an info button to views.
/// The button appears in the top-trailing corner and triggers the provided action.
struct InfoButton: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        ZStack(alignment: .topTrailing) {
            content

            Button {
                action()
            } label: {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundColor(.primary.opacity(0.7))
            }
            .padding()
        }
    }
}

public extension View {
    /// Adds an info button in the top-trailing corner of the view.
    /// - Parameter action: The action to perform when the button is tapped
    func withInfoButton(action: @escaping () -> Void) -> some View {
        modifier(InfoButton(action: action))
    }
}
