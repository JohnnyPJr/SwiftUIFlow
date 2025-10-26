//
//  AnyCoordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 8/8/25.
//

import Foundation

public protocol AnyCoordinator: AnyObject {
    var parent: AnyCoordinator? { get set }

    func navigationType(for route: any Route) -> NavigationType
    func navigate(to route: any Route, from caller: AnyCoordinator?) -> Bool
    func canHandle(_ route: any Route) -> Bool
    func canNavigate(to route: any Route) -> Bool
    func resetToCleanState()
}
