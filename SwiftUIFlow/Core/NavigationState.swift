//
//  NavigationState.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Foundation

public struct NavigationState<R: Route>: Equatable {
    public var root: R
    public var stack: [R]
    public var selectedTab: Int
    public var presented: R?
    public var detour: (any Route)?

    /// The current route being displayed (modal if presented, otherwise top of stack, or root if stack is empty)
    public var currentRoute: R {
        return presented ?? stack.last ?? root
    }

    public init(root: R) {
        self.root = root
        stack = []
        selectedTab = 0
        presented = nil
        detour = nil
    }

    public static func == (lhs: NavigationState<R>, rhs: NavigationState<R>) -> Bool {
        lhs.root == rhs.root &&
            lhs.stack == rhs.stack &&
            lhs.selectedTab == rhs.selectedTab &&
            lhs.presented == rhs.presented &&
            lhs.detour?.identifier == rhs.detour?.identifier
    }
}
