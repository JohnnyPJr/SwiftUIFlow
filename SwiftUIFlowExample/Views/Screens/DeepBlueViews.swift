//
//  DeepBlueViews.swift
//  SwiftUIFlowExample
//
//  Created for testing complex nested navigation:
//  Blue → DeepBlue (pushed child, 3 levels) → Modal → Ocean (pushed child in modal)
//

import SwiftUI

// MARK: - DeepBlue Level 1 (Pushed Child Root)

struct DeepBlueLevel1View: View {
    let coordinator: DeepBlueCoordinator

    var body: some View {
        ZStack {
            Color.cyan.opacity(0.3).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Deep Blue - Level 1")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("You are in a pushed child coordinator")
                    .foregroundColor(.secondary)

                Button("Navigate to Level 2") {
                    coordinator.navigate(to: DeepBlueRoute.level2)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .customNavigationBar(title: "Deep Blue L1", backgroundColor: .cyan.opacity(0.8))
    }
}

// MARK: - DeepBlue Level 2

struct DeepBlueLevel2View: View {
    let coordinator: DeepBlueCoordinator

    var body: some View {
        ZStack {
            Color.cyan.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Deep Blue - Level 2")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("One more push to reach level 3")
                    .foregroundColor(.secondary)

                Button("Navigate to Level 3") {
                    coordinator.navigate(to: DeepBlueRoute.level3)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .customNavigationBar(title: "Deep Blue L2", backgroundColor: .cyan.opacity(0.8))
    }
}

// MARK: - DeepBlue Level 3 (Can present modal)

struct DeepBlueLevel3View: View {
    let coordinator: DeepBlueCoordinator

    var body: some View {
        ZStack {
            Color.cyan.opacity(0.7).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Deep Blue - Level 3")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("This level can present a modal!")
                        .foregroundColor(.secondary)

                    Text("The modal contains Ocean coordinator as a pushed child")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()

                    Button("Present Level 3 Modal") {
                        coordinator.navigate(to: DeepBlueRoute.level3Modal)
                    }
                    .buttonStyle(.borderedProminent)

                    Divider()
                        .padding(.vertical, 20)

                    // Deep Link Testing Section
                    VStack(spacing: 15) {
                        Text("🔗 Deep Link Test")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("You are deep in navigation:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Blue Tab → DeepBlue (pushed child) → Level 1 → Level 2 → Level 3")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Spacer().frame(height: 10)

                        Button("📲 Simulate NAVIGATE Deep Link") {
                            DeepLinkHandler.simulateNavigateDeepLink()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)

                        Text("(Dismisses modals, cleans stack, goes to Purple)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Spacer().frame(height: 20)

                        Button("🎯 Simulate DETOUR Deep Link") {
                            DeepLinkHandler.simulateDetourDeepLink()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)

                        Text("(Preserves context, tap back to return here)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                .padding()
            }
        }
        .customNavigationBar(title: "Deep Blue L3", backgroundColor: .cyan.opacity(0.8))
    }
}

// MARK: - DeepBlue Level 3 Modal View (first modal)

struct DeepBlueLevel3ModalView: View {
    let coordinator: DeepBlueLevel3ModalCoordinator

    var body: some View {
        ZStack {
            Color.cyan.opacity(0.2).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Level 3 Modal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("This is the first modal")
                    .foregroundColor(.secondary)

                Text("Press the button to present another modal on top!")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()

                Button("Present Nested Modal") {
                    coordinator.navigate(to: DeepBlueRoute.level3NestedModal)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .withCloseButton()
    }
}

// MARK: - DeepBlue Nested Modal View (second modal with Ocean as pushed child)

struct DeepBlueNestedModalView: View {
    let coordinator: DeepBlueNestedModalCoordinator

    var body: some View {
        ZStack {
            Color.indigo.opacity(0.2).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Nested Modal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("This is a modal on top of a modal!")
                    .foregroundColor(.secondary)

                Text("From here you can push Ocean views")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()

                VStack(spacing: 12) {
                    Button("Push Ocean Surface") {
                        coordinator.navigate(to: OceanRoute.surface)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                }
            }
        }
        .withCloseButton()
    }
}
