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
            HStack(alignment: .top) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 8) {
                    Text(error.errorDescription ?? "Unknown Error")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(error.recommendedRecoveryAction)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.95))
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding(.horizontal)
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let error: SwiftUIFlowError?
    let autoDismissAfter: TimeInterval

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented, let error {
                VStack {
                    ErrorToastView(error: error) {
                        isPresented = false
                    }
                    .padding(.top, 50)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: isPresented)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissAfter) {
                        isPresented = false
                    }
                }
            }
        }
    }
}

extension View {
    func errorToast(isPresented: Binding<Bool>,
                    error: SwiftUIFlowError?,
                    autoDismissAfter: TimeInterval = 4.0) -> some View
    {
        modifier(ToastModifier(isPresented: isPresented, error: error, autoDismissAfter: autoDismissAfter))
    }
}
