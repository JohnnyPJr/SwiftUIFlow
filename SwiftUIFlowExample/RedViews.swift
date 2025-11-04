//
//  RedViews.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI
import SwiftUIFlow

struct RedView: View {
    let coordinator: RedCoordinator

    var body: some View {
        ZStack {
            Color.red.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Red Tab")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Button("Lighten Up") {
                    coordinator.navigate(to: RedRoute.lightRed)
                }
                .buttonStyle(NavigationButtonStyle(color: .white.opacity(0.3)))

                Button("Darken Up") {
                    coordinator.navigate(to: RedRoute.darkRed)
                }
                .buttonStyle(NavigationButtonStyle(color: .black.opacity(0.3)))
            }
        }
        .customNavigationBar(title: "Red",
                             titleColor: .white,
                             backgroundColor: Color.red.opacity(0.8))
    }
}

struct LightRedView: View {
    let coordinator: RedCoordinator

    var body: some View {
        ZStack {
            Color.red.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Light Red")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Pushed from Red Tab")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .customNavigationBar(title: "Light Red",
                             titleColor: .white,
                             backgroundColor: Color.red.opacity(0.5))
    }
}

struct DarkRedView: View {
    let coordinator: RedModalCoordinator

    var body: some View {
        ZStack {
            Color(red: 0.5, green: 0, blue: 0).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Dark Red")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Presented as Modal")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                Spacer().frame(height: 40)

                Button("Jump to Dark Yellow") {
                    coordinator.navigate(to: YellowRoute.darkYellow)
                }
                .buttonStyle(NavigationButtonStyle(color: .yellow))

                Text("(Should dismiss modal & show dark yellow)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}
