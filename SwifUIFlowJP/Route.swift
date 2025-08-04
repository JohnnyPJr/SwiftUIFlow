//
//  Route.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Foundation

public protocol Route: Hashable, Identifiable {
    var identifier: String { get }
}

public extension Route {
    var id: String { identifier }
}
