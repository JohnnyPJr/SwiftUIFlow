//
//  BlueViews.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI
import SwiftUIFlow

struct BlueView: View {
    let coordinator: BlueCoordinator

    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Blue Tab")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Button("Lighten Up") {
                    coordinator.navigate(to: BlueRoute.lightBlue)
                }
                .buttonStyle(NavigationButtonStyle(color: .white.opacity(0.3)))

                Button("Darken Up") {
                    coordinator.navigate(to: BlueRoute.darkBlue)
                }
                .buttonStyle(NavigationButtonStyle(color: .black.opacity(0.3)))
            }
        }
        .customNavigationBar(title: "Blue",
                             titleColor: .white,
                             backgroundColor: Color.blue.opacity(0.8))
    }
}

struct LightBlueView: View {
    let coordinator: BlueCoordinator

    var body: some View {
        ZStack {
            Color.blue.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Light Blue")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Pushed from Blue Tab")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                Spacer().frame(height: 40)

                Button("Detour to Red's Light Screen") {
                    let redDetourCoordinator = RedCoordinator()
                    coordinator.presentDetour(redDetourCoordinator, presenting: RedRoute.lightRed)
                }
                .buttonStyle(NavigationButtonStyle(color: .red))

                Text("(Preserves this context)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .customNavigationBar(title: "Light Blue",
                             titleColor: .white,
                             backgroundColor: Color.blue.opacity(0.5))
    }
}

struct DarkBlueView: View {
    let coordinator: BlueModalCoordinator

    var body: some View {
        ZStack {
            Color(red: 0, green: 0, blue: 0.5).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Dark Blue")
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
