//
//  SwiftUIFlowError.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 7/11/25.
//

import Foundation

/// Errors that can occur during navigation and view rendering in SwiftUIFlow
public enum SwiftUIFlowError: Error, LocalizedError, Equatable {
    // MARK: - Navigation Errors

    /// Navigation to a route failed because no coordinator could handle it
    case navigationFailed(coordinator: String, route: String, routeType: String, context: String)

    /// Attempted to present a modal but no modal coordinator was configured
    case modalCoordinatorNotConfigured(coordinator: String, route: String, routeType: String)

    /// Attempted to navigate to a detour route via navigate() instead of presentDetour()
    case invalidDetourNavigation(coordinator: String, route: String, routeType: String)

    // MARK: - View Creation Errors

    /// ViewFactory failed to create a view for the given route
    case viewCreationFailed(coordinator: String, route: String, routeType: String, viewType: ViewType)

    // MARK: - Configuration Errors

    /// Attempted to switch to a tab index that doesn't exist
    case invalidTabIndex(index: Int, validRange: Range<Int>)

    /// Attempted to add a child coordinator that's already been added
    case duplicateChild(coordinator: String)

    /// Attempted to create a circular reference (coordinator as its own parent/child)
    case circularReference(coordinator: String)

    /// Framework configuration error (catch-all for other setup issues)
    case configurationError(message: String)

    // MARK: - Equatable

    public static func == (lhs: SwiftUIFlowError, rhs: SwiftUIFlowError) -> Bool {
        switch (lhs, rhs) {
        case let (.navigationFailed(c1, r1, rt1, ctx1), .navigationFailed(c2, r2, rt2, ctx2)):
            return c1 == c2 && r1 == r2 && rt1 == rt2 && ctx1 == ctx2
        case let (.modalCoordinatorNotConfigured(c1, r1, rt1), .modalCoordinatorNotConfigured(c2, r2, rt2)):
            return c1 == c2 && r1 == r2 && rt1 == rt2
        case let (.invalidDetourNavigation(c1, r1, rt1), .invalidDetourNavigation(c2, r2, rt2)):
            return c1 == c2 && r1 == r2 && rt1 == rt2
        case let (.viewCreationFailed(c1, r1, rt1, v1), .viewCreationFailed(c2, r2, rt2, v2)):
            return c1 == c2 && r1 == r2 && rt1 == rt2 && v1 == v2
        case let (.invalidTabIndex(i1, r1), .invalidTabIndex(i2, r2)):
            return i1 == i2 && r1 == r2
        case let (.duplicateChild(c1), .duplicateChild(c2)):
            return c1 == c2
        case let (.circularReference(c1), .circularReference(c2)):
            return c1 == c2
        case let (.configurationError(m1), .configurationError(m2)):
            return m1 == m2
        default:
            return false
        }
    }
}

/// Type of view that failed to be created
public enum ViewType: Equatable {
    case root
    case pushed
    case modal
    case detour
}

/// Result of navigation validation
public enum ValidationResult {
    case success
    case failure(SwiftUIFlowError)

    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    var error: SwiftUIFlowError? {
        if case let .failure(error) = self {
            return error
        }
        return nil
    }
}

extension SwiftUIFlowError {
    /// Helper enum for creating errors without repeating coordinator/route info
    enum ErrorType {
        case navigationFailed(context: String)
        case modalCoordinatorNotConfigured
        case invalidDetourNavigation
        case viewCreationFailed(viewType: ViewType)
    }
}

public extension SwiftUIFlowError {
    /// User-friendly description of the error (LocalizedError protocol)
    var errorDescription: String? {
        switch self {
        case let .navigationFailed(_, route, _, context):
            return "Navigation failed for '\(route)'. \(context)"
        case let .modalCoordinatorNotConfigured(_, route, _):
            return "Cannot present '\(route)' as modal - no modal coordinator configured"
        case let .invalidDetourNavigation(_, route, _):
            return "Cannot navigate to '\(route)' - detours must use presentDetour()"
        case let .viewCreationFailed(_, route, _, viewType):
            return "Failed to create \(viewType) view for '\(route)'"
        case let .invalidTabIndex(index, validRange):
            return "Invalid tab index \(index) - valid range is \(validRange.lowerBound)..<\(validRange.upperBound)"
        case let .duplicateChild(coordinator):
            return "Coordinator '\(coordinator)' is already a child and cannot be added again"
        case let .circularReference(coordinator):
            return "Cannot add '\(coordinator)' as it would create a circular reference"
        case let .configurationError(message):
            return "Configuration error: \(message)"
        }
    }

    /// Technical details for debugging
    var debugDescription: String {
        switch self {
        case let .navigationFailed(coordinator, route, routeType, context):
            "NavigationFailed: coordinator=\(coordinator) route=\(route) routeType=\(routeType) context=\(context)"
        case let .modalCoordinatorNotConfigured(coordinator, route, routeType):
            "ModalCoordinatorNotConfigured: coordinator=\(coordinator) route=\(route) routeType=\(routeType)"
        case let .invalidDetourNavigation(coordinator, route, routeType):
            "InvalidDetourNavigation: coordinator=\(coordinator) route=\(route) routeType=\(routeType)"
        case let .viewCreationFailed(coordinator, route, routeType, viewType):
            "ViewCreationFailed: coordinator=\(coordinator) route=\(route) routeType=\(routeType) viewType=\(viewType)"
        case let .invalidTabIndex(index, validRange):
            "InvalidTabIndex: index=\(index) validRange=\(validRange.lowerBound)..<\(validRange.upperBound)"
        case let .duplicateChild(coordinator):
            "DuplicateChild: coordinator=\(coordinator)"
        case let .circularReference(coordinator):
            "CircularReference: coordinator=\(coordinator)"
        case let .configurationError(message):
            "ConfigurationError: \(message)"
        }
    }

    /// Recommended action to fix the error
    var recommendedRecoveryAction: String {
        switch self {
        case let .navigationFailed(_, _, routeType, _):
            return "Ensure a coordinator in the hierarchy implements canHandle() for \(routeType) routes"
        case let .modalCoordinatorNotConfigured(coordinator, _, routeType):
            return "Call addModalCoordinator() on \(coordinator) with a coordinator that handles \(routeType)"
        case .invalidDetourNavigation:
            return "Use coordinator.presentDetour(_:presenting:) instead of coordinator.navigate(to:)"
        case let .viewCreationFailed(_, _, routeType, _):
            return "Ensure ViewFactory.view(for:) returns a view for \(routeType) routes"
        case let .invalidTabIndex(_, validRange):
            return "Use switchToTab() with an index between \(validRange.lowerBound) and \(validRange.upperBound - 1)"
        case .duplicateChild:
            return "Remove the coordinator from children before adding it again, or check if it's already added"
        case .circularReference:
            return "Check coordinator hierarchy - a coordinator cannot be its own parent or child"
        case .configurationError:
            return "Review coordinator initialization and configuration"
        }
    }
}
