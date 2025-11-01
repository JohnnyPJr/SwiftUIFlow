//
//  LoginView.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI
import SwiftUIFlow

struct LoginView: View {
    let appCoordinator: AppCoordinator

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue, .purple],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Welcome")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)

                Text("Login Screen")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))

                Spacer().frame(height: 60)

                Button("Login (Transition to Main App)") {
                    // Admin operation: completely replace the flow
                    appCoordinator.transitionToNewFlow(root: .tabRoot)
                }
                .buttonStyle(NavigationButtonStyle(color: .white.opacity(0.2)))

                Text("(Uses transitionToNewFlow admin operation)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}
