//
//  LoginView.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI
import SwiftUIFlow

struct LoginView: View {
    let coordinator: LoginCoordinator

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

                Button("Login") {
                    // Navigate to main app - bubbles to AppCoordinator via handleFlowChange
                    coordinator.navigate(to: AppRoute.tabRoot)
                }
                .buttonStyle(NavigationButtonStyle(color: .white.opacity(0.2)))

                Text("(Navigates via bubbling to trigger flow change)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}
