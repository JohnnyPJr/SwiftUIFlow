//
//  PurpleViews.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI
import SwiftUIFlow

struct PurpleView: View {
    let coordinator: PurpleCoordinator

    var body: some View {
        ZStack {
            Color.purple.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Purple Tab")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Button("Lighten Up") {
                    let _ = coordinator.navigate(to: PurpleRoute.lightPurple)
                }
                .buttonStyle(NavigationButtonStyle(color: .white.opacity(0.3)))

                Button("Darken Up") {
                    let _ = coordinator.navigate(to: PurpleRoute.darkPurple)
                }
                .buttonStyle(NavigationButtonStyle(color: .black.opacity(0.3)))

                Spacer().frame(height: 60)

                VStack(spacing: 10) {
                    Text("Flow Change Demo")
                        .font(.headline)
                        .foregroundColor(.white)

                    Button("Logout") {
                        // Navigate to login - bubbles to AppCoordinator via handleFlowChange
                        let _ = coordinator.navigate(to: AppRoute.login)
                    }
                    .buttonStyle(NavigationButtonStyle(color: .white.opacity(0.5)))

                    Text("(Navigates via bubbling to trigger flow change)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .withInfoButton {
            coordinator.presentModal(coordinator.infoCoordinator,
                                     presenting: .info,
                                     detentConfiguration: ModalDetentConfiguration(detents: [.fullscreen]))
        }
        .customNavigationBar(title: "Purple",
                             titleColor: .white,
                             backgroundColor: Color.purple.opacity(0.8))
    }
}

struct LightPurpleView: View {
    let coordinator: PurpleCoordinator

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
                        let _ = coordinator.navigate(to: PurpleRoute.result(success: true))
                    }
                    .buttonStyle(NavigationButtonStyle(color: .green))

                    Button("Failure ✗") {
                        let _ = coordinator.navigate(to: PurpleRoute.result(success: false))
                    }
                    .buttonStyle(NavigationButtonStyle(color: .red))
                }
            }
        }
        .customNavigationBar(title: "Light Purple",
                             titleColor: .white,
                             backgroundColor: Color.purple.opacity(0.5))
    }
}

struct DarkPurpleView: View {
    let coordinator: PurpleModalCoordinator

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
        .customNavigationBar(title: "Dark Purple",
                             titleColor: .white,
                             backgroundColor: Color(red: 0.3, green: 0, blue: 0.5).opacity(0.8))
    }
}

struct ResultView: View {
    let success: Bool
    let coordinator: PurpleCoordinator

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
        .customNavigationBar(title: success ? "Success" : "Failed",
                             titleColor: .white,
                             backgroundColor: success ? Color.green.opacity(0.8) : Color.red.opacity(0.8))
    }
}
