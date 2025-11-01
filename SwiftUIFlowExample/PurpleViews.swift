//
//  PurpleViews.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI
import SwiftUIFlow

struct PurpleView: View {
    let appCoordinator: AppCoordinator

    var body: some View {
        ZStack {
            Color.purple.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Purple Tab")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Button("Lighten Up") {
                    appCoordinator.navigate(to: PurpleRoute.lightPurple)
                }
                .buttonStyle(NavigationButtonStyle(color: .white.opacity(0.3)))

                Button("Darken Up") {
                    appCoordinator.navigate(to: PurpleRoute.darkPurple)
                }
                .buttonStyle(NavigationButtonStyle(color: .black.opacity(0.3)))

                Spacer().frame(height: 60)

                VStack(spacing: 10) {
                    Text("Admin Operation Demo")
                        .font(.headline)
                        .foregroundColor(.white)

                    Button("Logout (Transition to Login)") {
                        // Admin operation: completely replace the root flow
                        appCoordinator.transitionToNewFlow(root: .login)
                    }
                    .buttonStyle(NavigationButtonStyle(color: .white.opacity(0.5)))

                    Text("(Uses transitionToNewFlow)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

struct LightPurpleView: View {
    let appCoordinator: AppCoordinator

    var body: some View {
        ZStack {
            Color.purple.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Light Purple")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Pushed from Purple Tab")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                Spacer().frame(height: 40)

                Text("Replace Navigation Demo")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("(Simulates network call with success/failure)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                HStack(spacing: 20) {
                    Button("Success ✓") {
                        appCoordinator.navigate(to: PurpleRoute.result(success: true))
                    }
                    .buttonStyle(NavigationButtonStyle(color: .green))

                    Button("Failure ✗") {
                        appCoordinator.navigate(to: PurpleRoute.result(success: false))
                    }
                    .buttonStyle(NavigationButtonStyle(color: .red))
                }
            }
        }
    }
}

struct DarkPurpleView: View {
    let appCoordinator: AppCoordinator

    var body: some View {
        ZStack {
            Color(red: 0.3, green: 0, blue: 0.5).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Dark Purple")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Presented as Modal")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

struct ResultView: View {
    let success: Bool
    let appCoordinator: AppCoordinator

    var body: some View {
        ZStack {
            (success ? Color.green : Color.red).ignoresSafeArea()

            VStack(spacing: 20) {
                Text(success ? "Success!" : "Failed!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Replaced Light Purple")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                Text("(Back button returns to Purple Tab)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}
