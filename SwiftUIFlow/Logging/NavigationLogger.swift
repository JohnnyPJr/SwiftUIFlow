//
//  NavigationLogger.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 7/11/25.
//

import OSLog

/// Internal logger for navigation debugging.
///
/// This logger only outputs in DEBUG builds and is used internally
/// by the framework to help developers understand navigation flow.
enum NavigationLogger {
    private static let logger = Logger(subsystem: "com.swiftuiflow",
                                       category: "Navigation")

    /// Log debug-level navigation information
    /// - Parameter message: The message to log
    static func debug(_ message: String) {
        #if DEBUG
            logger.debug("\(message)")
        #endif
    }

    /// Log info-level navigation information
    /// - Parameter message: The message to log
    static func info(_ message: String) {
        #if DEBUG
            logger.info("\(message)")
        #endif
    }

    /// Log error-level navigation information
    /// - Parameter message: The message to log
    static func error(_ message: String) {
        #if DEBUG
            logger.error("\(message)")
        #endif
    }
}
