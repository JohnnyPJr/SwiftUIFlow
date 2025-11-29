//
//  RainbowViews.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 16/11/25.
//

import SwiftUI
import SwiftUIFlow

struct RainbowRedView: View {
    let coordinator: RainbowCoordinator

    var body: some View {
        ZStack {
            Color.red.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Rainbow Red")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Button("Go to Orange") {
                    _ = coordinator.navigate(to: RainbowRoute.orange)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .customNavigationBar(title: "Rainbow Red", backgroundColor: .red)
    }
}

struct RainbowOrangeView: View {
    let coordinator: RainbowCoordinator

    var body: some View {
        ZStack {
            Color.orange.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Rainbow Orange")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Button("Go to Yellow") {
                    _ = coordinator.navigate(to: RainbowRoute.yellow)
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
            }
        }
        .customNavigationBar(title: "Rainbow Orange", backgroundColor: .orange)
    }
}

struct RainbowYellowView: View {
    let coordinator: RainbowCoordinator

    var body: some View {
        ZStack {
            Color.yellow.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Rainbow Yellow")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                Button("Go to Green") {
                    _ = coordinator.navigate(to: RainbowRoute.green)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .customNavigationBar(title: "Rainbow Yellow", backgroundColor: .yellow)
    }
}

struct RainbowGreenView: View {
    let coordinator: RainbowCoordinator

    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Rainbow Green")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Button("Go to Blue") {
                    _ = coordinator.navigate(to: RainbowRoute.blue)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .customNavigationBar(title: "Rainbow Green", backgroundColor: .green)
    }
}

struct RainbowBlueView: View {
    let coordinator: RainbowCoordinator

    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Rainbow Blue")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Button("Go to Purple") {
                    _ = coordinator.navigate(to: RainbowRoute.purple)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)

                Button("Detour to Yellow's Light Screen") {
                    let yellowDetourCoordinator = YellowCoordinator(root: .lightYellow)
                    coordinator.presentDetour(yellowDetourCoordinator, presenting: YellowRoute.lightYellow)
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
            }
        }
        .customNavigationBar(title: "Rainbow Blue", backgroundColor: .blue)
    }
}

struct RainbowPurpleView: View {
    let coordinator: RainbowCoordinator

    var body: some View {
        ZStack {
            Color.purple.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Rainbow Purple")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Button("Back to Red") {
                    _ = coordinator.navigate(to: RainbowRoute.red)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Button("Go to Dark Blue Tab") {
                    _ = coordinator.navigate(to: BlueRoute.darkBlue)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .customNavigationBar(title: "Rainbow Purple", backgroundColor: .purple)
    }
}
