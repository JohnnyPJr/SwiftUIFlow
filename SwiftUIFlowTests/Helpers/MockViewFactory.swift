//
//  MockViewFactory.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 7/8/25.
//

import Foundation
import SwiftUI

@testable import SwiftUIFlow

final class MockViewFactory: ViewFactory<MockRoute> {
    override func buildView(for route: MockRoute) -> AnyView? {
        switch route {
        case .home: return AnyView(Text("Home"))
        case .details: return AnyView(Text("Details"))
        case .login: return AnyView(Text("Login"))
        case .modal: return AnyView(Text("Modal"))
        }
    }
}
