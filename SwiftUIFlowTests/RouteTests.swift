//
//  RouterTests.swift
//  SwiftUIFlowTests
//
//  Created by Damian Rzeszot on 10/07/2026.
//

import SwiftUI
@testable import SwiftUIFlow
import XCTest

final class RouteTests: XCTestCase {
    func test_StringRawRepresentableRoute_UsesRawValueAsIdentifier() {
        enum TestRoute: String, Route {
            case home
            case settings
        }

        XCTAssertEqual(TestRoute.home.identifier, "home")
        XCTAssertEqual(TestRoute.settings.identifier, "settings")
        XCTAssertEqual(TestRoute.home.id, "home")
    }
}
