//
//  AnyCoordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 8/8/25.
//

import Foundation

public protocol AnyCoordinator: AnyObject {
    var parent: AnyCoordinator? { get set }

    func navigate(to route: any Route) -> Bool
    func canHandle(_ route: any Route) -> Bool
    func handleDeeplink(_ route: any Route)
}
