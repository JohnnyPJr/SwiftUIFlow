//
//  YellowViews.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI
import SwiftUIFlow

struct YellowView: View {
    let appCoordinator: AppCoordinator

    var body: some View {
        ZStack {
            Color.yellow.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Yellow Tab")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                Button("Lighten Up") {
                    appCoordinator.navigate(to: YellowRoute.lightYellow)
                }
                .buttonStyle(NavigationButtonStyle(color: .white.opacity(0.5)))

                Button("Darken Up") {
                    appCoordinator.navigate(to: YellowRoute.darkYellow)
                }
                .buttonStyle(NavigationButtonStyle(color: .black.opacity(0.3)))
            }
        }
    }
}

struct LightYellowView: View {
    let appCoordinator: AppCoordinator

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
            }
        }
    }
}

struct DarkYellowView: View {
    let appCoordinator: AppCoordinator

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
