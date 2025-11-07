//
//  CustomNavigationBar.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI
import SwiftUIFlow

/// A completely custom navigation bar component that replaces SwiftUI's native navigation bar.
/// This demonstrates how clients can build their own navigation UI with any design they want.
struct CustomNavigationBar: View {
    @Environment(\.navigationBackAction) private var environmentBackAction
    @Environment(\.canNavigateBack) private var canNavigateBack
    @Environment(\.dismiss) private var dismiss

    let title: String
    let titleColor: Color
    let backgroundColor: Color
    let onBack: (() -> Void)?
    let trailingButton: (() -> AnyView)?

    init(title: String,
         titleColor: Color = .primary,
         backgroundColor: Color = .clear,
         onBack: (() -> Void)? = nil,
         trailingButton: (() -> AnyView)? = nil)
    {
        self.title = title
        self.titleColor = titleColor
        self.backgroundColor = backgroundColor
        self.onBack = onBack
        self.trailingButton = trailingButton
    }

    var body: some View {
        ZStack {
            // Back button - leading
            HStack {
                // Show back button only if we can navigate back (framework determines this) and there's a back action
                if canNavigateBack, let backAction = environmentBackAction ?? onBack {
                    Button(action: backAction) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(titleColor)
                    }
                }

                Spacer()
            }

            // Title - centered
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(titleColor)

            // Trailing button - trailing
            HStack {
                Spacer()

                if let trailingButton {
                    trailingButton()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .overlay(Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(height: 1),
            alignment: .bottom)
    }
}

/// ViewModifier that applies a custom navigation bar to a view
struct CustomNavigationBarModifier: ViewModifier {
    let title: String
    let titleColor: Color
    let backgroundColor: Color
    let onBack: (() -> Void)?
    let trailingButton: (() -> AnyView)?

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            CustomNavigationBar(title: title,
                                titleColor: titleColor,
                                backgroundColor: backgroundColor,
                                onBack: onBack,
                                trailingButton: trailingButton)

            content
        }
        .navigationBarHidden(true)
    }
}

/// Extension to make it easy to apply custom navigation bars
extension View {
    /// Applies a custom navigation bar to this view, hiding the native SwiftUI navigation bar.
    ///
    /// The back button visibility is automatically determined by the framework based on the navigation stack state.
    /// Root views (empty stack) won't show a back button, pushed views will.
    ///
    /// Example usage:
    /// ```swift
    /// struct MyView: View {
    ///     var body: some View {
    ///         ScrollView {
    ///             // content
    ///         }
    ///         .customNavigationBar(
    ///             title: "My Screen",
    ///             titleColor: .red
    ///         )
    ///     }
    /// }
    /// ```
    func customNavigationBar(title: String,
                             titleColor: Color = .primary,
                             backgroundColor: Color = .clear,
                             onBack: (() -> Void)? = nil,
                             trailingButton: (() -> AnyView)? = nil) -> some View
    {
        modifier(CustomNavigationBarModifier(title: title,
                                             titleColor: titleColor,
                                             backgroundColor: backgroundColor,
                                             onBack: onBack,
                                             trailingButton: trailingButton))
    }
}
