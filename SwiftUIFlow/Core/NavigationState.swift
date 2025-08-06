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

    public init(root: R) {
        self.root = root
        stack = []
        selectedTab = 0
        presented = nil
    }
}
