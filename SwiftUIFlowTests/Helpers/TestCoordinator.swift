//
//  TestCoordinator.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Foundation
@testable import SwiftUIFlow

final class TestCoordinator: Coordinator<MockRoute> {
    var didHandleRoute = false
    
    override func handle(route: MockRoute) -> Bool {
        didHandleRoute = true
        return true
    }
}
