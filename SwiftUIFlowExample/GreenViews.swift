//
//  GreenViews.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI
import SwiftUIFlow

struct GreenView: View {
    let coordinator: GreenCoordinator

    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Green Tab")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Button("Lighten Up") {
                    coordinator.navigate(to: GreenRoute.lightGreen)
                }
                .buttonStyle(NavigationButtonStyle(color: .white.opacity(0.3)))

                Button("Darken Up") {
                    coordinator.navigate(to: GreenRoute.darkGreen)
                }
                .buttonStyle(NavigationButtonStyle(color: .black.opacity(0.3)))
            }
        }
        .customNavigationBar(title: "Green",
                             titleColor: .white,
                             backgroundColor: Color.green.opacity(0.8))
    }
}

struct LightGreenView: View {
    let coordinator: GreenCoordinator

    var body: some View {
        ZStack {
            Color.green.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Light Green")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Pushed from Green Tab")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                Spacer().frame(height: 40)

                Button("Jump to Yellow's Light Screen") {
                    coordinator.navigate(to: YellowRoute.lightYellow)
                }
                .buttonStyle(NavigationButtonStyle(color: .yellow))
            }
        }
        .customNavigationBar(title: "Light Green",
                             titleColor: .white,
                             backgroundColor: Color.green.opacity(0.5))
    }
}

struct DarkGreenView: View {
    let coordinator: GreenModalCoordinator

    var body: some View {
        ZStack {
            Color(red: 0, green: 0.5, blue: 0).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Dark Green")
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
