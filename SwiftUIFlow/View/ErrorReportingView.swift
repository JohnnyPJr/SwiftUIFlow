//
//  ErrorReportingView.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 8/11/25.
//

import SwiftUI

/// A view that reports an error immediately upon initialization
struct ErrorReportingView: View {
    init(error: SwiftUIFlowError) {
        SwiftUIFlowErrorHandler.shared.report(error)
    }

    var body: some View {
        EmptyView()
    }
}
