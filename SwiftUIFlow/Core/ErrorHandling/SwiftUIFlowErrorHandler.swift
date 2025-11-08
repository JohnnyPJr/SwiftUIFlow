//
//  SwiftUIFlowErrorHandler.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 8/11/25.
//

import Foundation

/// Global error handler for SwiftUIFlow framework.
/// Clients register a single error handler that receives all errors from the framework.
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
    ///     print("Error: \(error)")
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
