//
//  ErrorReportingView.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 8/11/25.
//

import SwiftUI

/// A report-only placeholder used when view creation fails.
///
/// This view intentionally renders no UI. SwiftUIFlow reports the error through
/// `SwiftUIFlowErrorHandler`, and the client app decides how to present user-facing feedback
/// such as a toast, banner, or fallback screen.
struct ErrorReportingView: View {
    init(error: SwiftUIFlowError) {
        SwiftUIFlowErrorHandler.shared.report(error)
    }

    var body: some View {
        // Intentionally empty: user-facing error UI belongs to the client app's error handler.
        EmptyView()
    }
}
