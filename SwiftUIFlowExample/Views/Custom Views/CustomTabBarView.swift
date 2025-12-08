//
//  CustomTabBarView.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI
import SwiftUIFlow

/// A completely custom tab bar implementation that demonstrates how clients can
/// replace TabCoordinatorView with their own UI by observing the TabCoordinator's state directly.
struct CustomTabBarView: View {
    let coordinator: MainTabCoordinator
    @ObservedObject private var router: Router<AppRoute>

    // Map colors to each tab
    private let tabColors: [Color] = [.red, .green, .blue, .yellow, .purple]

    init(coordinator: MainTabCoordinator) {
        self.coordinator = coordinator
        router = coordinator.router
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content area - render the selected tab's coordinator
            if router.state.selectedTab < coordinator.children.count {
                let selectedChild = coordinator.children[router.state.selectedTab]
                let coordinatorView = selectedChild.buildCoordinatorView()
                eraseToAnyView(coordinatorView)
                    .ignoresSafeArea(edges: .bottom)
            }

            // Custom tab bar at the bottom
            customTabBar
                .frame(height: 80)
                .background(.ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
        }
        .withTabCoordinatorModals(coordinator: coordinator)
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(coordinator.children.enumerated()), id: \.offset) { index, child in
                if let item = child.tabItem {
                    tabButton(for: item, at: index, color: tabColors[safe: index] ?? .gray)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    private func tabButton(for item: (text: String, image: String), at index: Int, color: Color) -> some View {
        let isSelected = router.state.selectedTab == index

        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                coordinator.switchToTab(index)
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: item.image)
                    .font(.system(size: isSelected ? 26 : 22))
                    .foregroundColor(isSelected ? .black : color)
                    .symbolEffect(.bounce, value: isSelected)

                Text(item.text)
                    .font(.system(size: isSelected ? 12 : 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .black : color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color.opacity(0.15))
                    : nil
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// Helper for safe array access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Helper to erase type
func eraseToAnyView(_ value: Any) -> AnyView {
    if let view = value as? AnyView {
        return view
    } else if let view = value as? any View {
        return AnyView(view)
    } else {
        return AnyView(EmptyView())
    }
}
