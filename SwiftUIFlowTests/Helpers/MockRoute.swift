//
//  MockRoute.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 1/8/25.
//

import Foundation
@testable import SwiftUIFlow

enum MockRoute: String, Route {
    case login
    case home
    case details
    case modal

    var identifier: String { rawValue }
}
