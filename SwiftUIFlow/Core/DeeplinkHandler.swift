//
//  DeeplinkHandler.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 2/8/25.
//

public protocol DeeplinkHandler {
    associatedtype R: Route
    func canHandle(_ route: R) -> Bool
    func handleDeeplink(_ route: R)
}
