//
//  SwiftUIFlowErrorHandler.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 8/11/25.
//

import Foundation

/// Global error handler for SwiftUIFlow framework.
///
/// Register a custom error handler to receive and handle all navigation errors from
/// coordinators throughout your app. This is useful for logging, analytics, or displaying
/// error messages to users.
///
/// ## Usage
///
/// Set up the error handler early in your app's lifecycle:
///
/// ```swift
/// @main
/// struct MyApp: App {
///     init() {
///         SwiftUIFlowErrorHandler.shared.setHandler { error in
///             // Log to analytics
///             Analytics.logError(error)
///
///             // Show user-friendly message
///             if case .navigationFailed = error {
///                 ToastManager.show("Navigation error occurred")
///             }
///
///             // Development logging
///             #if DEBUG
///             Logger().error("SwiftUIFlow Error: \(error.localizedDescription)")
///             #endif
///         }
///     }
/// }
/// ```
///
/// ## Default Behavior
///
/// If no handler is set, errors are logged to the console via `NavigationLogger`.
public final class SwiftUIFlowErrorHandler {
    /// Shared singleton instance
    public static let shared = SwiftUIFlowErrorHandler()

    private var handler: ((SwiftUIFlowError) -> Void)?

    private init() {}

    /// Set the global error handler.
    /// This handler will receive all errors from coordinators throughout the app.
    ///
    /// ```swift
    /// SwiftUIFlowErrorHandler.shared.setHandler { error in
    ///     Logger().error("Navigation error: \(error.localizedDescription)")
    ///     // Show toast, log to analytics, etc.
    /// }
    /// ```
    public func setHandler(_ handler: @escaping (SwiftUIFlowError) -> Void) {
        self.handler = handler
    }

    /// Report an error to the global handler.
    /// Internal - only the framework can call this.
    func report(_ error: SwiftUIFlowError) {
        if let handler {
            handler(error)
        } else {
            // Default behavior: Log the error
            NavigationLogger.error(error.debugDescription)
        }
    }

    /// Reset the handler (for testing purposes)
    func reset() {
        handler = nil
    }
}
