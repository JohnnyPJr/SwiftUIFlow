//
//  OceanViews.swift
//  SwiftUIFlowExample
//
//  Created for testing deep cross-coordinator navigation
//

import SwiftUI
import SwiftUIFlow

// MARK: - Ocean Surface View

struct OceanSurfaceView: View {
    let coordinator: OceanCoordinator

    var body: some View {
        VStack(spacing: 20) {
            Text("🌊 Ocean Surface")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("You are at the surface of the ocean")
                .font(.body)
                .foregroundColor(.secondary)

            Spacer()

            Button("Dive to Shallow Water") {
                coordinator.navigate(to: OceanRoute.shallow)
            }
            .buttonStyle(NavigationButtonStyle(color: .cyan))

            Spacer()
        }
        .padding()
        .navigationTitle("Ocean Surface")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Ocean Shallow View

struct OceanShallowView: View {
    let coordinator: OceanCoordinator

    var body: some View {
        VStack(spacing: 20) {
            Text("🐠 Shallow Water")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Sunlight still reaches here")
                .font(.body)
                .foregroundColor(.secondary)

            Spacer()

            Button("Dive Deeper") {
                coordinator.navigate(to: OceanRoute.deep)
            }
            .buttonStyle(NavigationButtonStyle(color: .cyan))

            Spacer()
        }
        .padding()
        .navigationTitle("Shallow Water")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Ocean Deep View

struct OceanDeepView: View {
    let coordinator: OceanCoordinator

    var body: some View {
        VStack(spacing: 20) {
            Text("🐙 Deep Water")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("The pressure is intense")
                .font(.body)
                .foregroundColor(.secondary)

            Spacer()

            Button("Descend to the Abyss") {
                coordinator.navigate(to: OceanRoute.abyss)
            }
            .buttonStyle(NavigationButtonStyle(color: .cyan))

            Spacer()
        }
        .padding()
        .navigationTitle("Deep Water")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Ocean Abyss View

struct OceanAbyssView: View {
    let coordinator: OceanCoordinator

    var body: some View {
        VStack(spacing: 20) {
            Text("🦑 The Abyss")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("The deepest point - complete darkness")
                .font(.body)
                .foregroundColor(.secondary)

            Text("Navigation Path:")
                .font(.headline)
                .padding(.top, 20)

            Text("Dark Blue → Ocean Surface → Shallow → Deep → Abyss")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.cyan)
                .padding()

            Spacer()
        }
        .padding()
        .navigationTitle("The Abyss")
        .navigationBarTitleDisplayMode(.inline)
    }
}
