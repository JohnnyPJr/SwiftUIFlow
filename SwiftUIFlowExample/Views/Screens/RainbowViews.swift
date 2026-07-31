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
                    coordinator.navigate(to: RainbowRoute.orange)
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
                    coordinator.navigate(to: RainbowRoute.yellow)
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
                    coordinator.navigate(to: RainbowRoute.green)
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
                    coordinator.navigate(to: RainbowRoute.blue)
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
                    coordinator.navigate(to: RainbowRoute.purple)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)

                Button("Simulate Detour (Yellow)") {
                    DeepLinkHandler.simulateDetourDeepLink()
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)

                Text("(Preserves context, like push notification)")
                    .font(.caption)
                    .foregroundColor(.white)
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
                    coordinator.navigate(to: RainbowRoute.red)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Button("Go to Even Darker Green") {
                    coordinator.navigate(to: GreenRoute.evenDarkerGreen)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button("🌊 Dive to the Abyss") {
                    coordinator.navigate(to: OceanRoute.abyss)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)

                Button("Test Nested Pushed Child") {
                    coordinator.navigate(to: RainbowDetailRoute.detail)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(LinearGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple],
                                           startPoint: .leading,
                                           endPoint: .trailing))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                }

                Text("Expected: Red → Rainbow → Rainbow Detail")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .customNavigationBar(title: "Rainbow Purple", backgroundColor: .purple)
    }
}

struct RainbowDetailView: View {
    let coordinator: RainbowDetailCoordinator

    var body: some View {
        ZStack {
            LinearGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Text("Rainbow Detail")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Nested pushed child rendered successfully")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Regression playground: pushed child → pushed grandchild → navigation")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Deep Link to Purple Tab") {
                        coordinator.navigate(to: PurpleRoute.purple)
                    }
                    .buttonStyle(NavigationButtonStyle(color: .purple))

                    Text("Rainbow Detail → Purple tab")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))

                    Divider()
                        .background(Color.white.opacity(0.8))
                        .padding(.vertical, 4)

                    Button("Navigate to This Detail Again") {
                        coordinator.navigate(to: RainbowDetailRoute.detail)
                    }
                    .buttonStyle(NavigationButtonStyle(color: .indigo))

                    Text("Expected: no duplicate push, no visual change")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)

                    Button("Present Detail Modal") {
                        coordinator.navigate(to: RainbowDetailRoute.modal)
                    }
                    .buttonStyle(NavigationButtonStyle(color: .pink))

                    Text("Expected: medium modal from pushed grandchild, dismiss returns here")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)

                    Button("Present Yellow Detour") {
                        DeepLinkHandler.simulateDetourDeepLink()
                    }
                    .buttonStyle(NavigationButtonStyle(color: .yellow))

                    Text("Expected: detour dismiss returns to Rainbow Detail")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)

                    Button("Present Two Nested Detours") {
                        DeepLinkHandler.simulateNestedDetourDeepLink()
                    }
                    .buttonStyle(NavigationButtonStyle(color: .orange))

                    Text("Expected: Yellow Tab appears on top of Light Yellow")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)

                    Button("Deep Link to Ocean Abyss") {
                        coordinator.navigate(to: OceanRoute.abyss)
                    }
                    .buttonStyle(NavigationButtonStyle(color: .blue))

                    Text("Expected: Blue tab → DeepBlue → modals → Ocean Abyss")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding()
                .padding(.bottom, 120)
            }
        }
        .customNavigationBar(title: "Rainbow Detail", backgroundColor: .purple)
    }
}

struct RainbowDetailModalView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.pink, .purple, .blue],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Rainbow Detail Modal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Presented from pushed grandchild")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))

                Text("Expected: medium sheet; closing returns to Rainbow Detail")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .withCloseButton()
    }
}
