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
                    _ = coordinator.navigate(to: GreenRoute.lightGreen)
                }
                .buttonStyle(NavigationButtonStyle(color: .white.opacity(0.3)))

                Button("Darken Up") {
                    _ = coordinator.navigate(to: GreenRoute.darkGreen)
                }
                .buttonStyle(NavigationButtonStyle(color: .black.opacity(0.3)))
            }
        }
        .withInfoButton {
            _ = coordinator.navigate(to: GreenRoute.info)
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
                    _ = coordinator.navigate(to: YellowRoute.lightYellow)
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
    @Environment(\.navigationBackAction) var backAction
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

                Text("(Native Navigation Bar)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                Spacer().frame(height: 40)

                Button("Go Even Darker") {
                    _ = coordinator.navigate(to: GreenRoute.evenDarkerGreen)
                }
                .buttonStyle(NavigationButtonStyle(color: .white.opacity(0.3)))

                Button("Present Darkest Green (Modal on Modal)") {
                    _ = coordinator.navigate(to: GreenRoute.darkestGreen)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green.opacity(0.3))
            }
        }
        .navigationTitle("Dark Green")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    backAction?()
                }
            }
        }
    }
}

struct EvenDarkerGreenView: View {
    let coordinator: GreenModalCoordinator

    var body: some View {
        ZStack {
            Color(red: 0, green: 0.3, blue: 0).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Even Darker Green")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Pushed from Modal")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .navigationTitle("Even Darker Green")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DarkestGreenView: View {
    @Environment(\.navigationBackAction) var backAction
    let coordinator: GreenDarkestModalCoordinator

    var body: some View {
        ZStack {
            Color(red: 0, green: 0.2, blue: 0).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Darkest Green")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Modal Upon Modal! 🎉")
                    .font(.title2)
                    .foregroundColor(.green.opacity(0.7))

                Text("This modal is presented on top of another modal")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .navigationTitle("Darkest Green")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    backAction?()
                }
            }
        }
    }
}
