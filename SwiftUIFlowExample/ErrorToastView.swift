//
//  ErrorToastView.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 8/11/25.
//

import SwiftUI
import SwiftUIFlow

struct ErrorToastView: View {
    let error: SwiftUIFlowError
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)

                Text(error.errorDescription ?? "Unknown Error")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Text(error.recommendedRecoveryAction)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .background(Color.red.opacity(0.95))
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding(.horizontal)
    }
}
