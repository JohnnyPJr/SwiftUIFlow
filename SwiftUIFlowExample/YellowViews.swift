//
//  YellowViews.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI
import SwiftUIFlow

struct YellowView: View {
    let coordinator: YellowCoordinator

    var body: some View {
        ZStack {
            Color.yellow.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Yellow Tab")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                Button("Lighten Up") {
                    let _ = coordinator.navigate(to: YellowRoute.lightYellow)
                }
                .buttonStyle(NavigationButtonStyle(color: .white.opacity(0.5)))

                Button("Darken Up") {
                    let _ = coordinator.navigate(to: YellowRoute.darkYellow)
                }
                .buttonStyle(NavigationButtonStyle(color: .black.opacity(0.3)))
            }
        }
        .withInfoButton {
            let _ = coordinator.navigate(to: YellowRoute.info)
        }
        .customNavigationBar(title: "Yellow",
                             titleColor: .black,
                             backgroundColor: Color.yellow.opacity(0.8))
    }
}

struct LightYellowView: View {
    let coordinator: YellowCoordinator

    var body: some View {
        ZStack {
            Color.yellow.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Light Yellow")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                Text("Pushed from Yellow Tab")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.7))

                Button("Navigate to Dark Green") {
                    _ = coordinator.navigate(to: GreenRoute.darkGreen)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .customNavigationBar(title: "Light Yellow",
                             titleColor: .black,
                             backgroundColor: Color.yellow.opacity(0.5))
    }
}

struct DarkYellowView: View {
    let coordinator: YellowModalCoordinator

    var body: some View {
        ZStack {
            Color.orange.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Dark Yellow")
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
