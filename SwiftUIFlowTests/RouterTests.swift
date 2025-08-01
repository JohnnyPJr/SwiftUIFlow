//
//  RouterTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 1/8/25.
//

import XCTest
@testable import SwiftUIFlow

final class RouterTests: XCTestCase {
    func testInitializesWithRootState() {
        let router = Router<MockRoute>(initial: .home)
        XCTAssertEqual(router.state.root, .home)
        XCTAssertTrue(router.state.stack.isEmpty)
    }
    
    func testPushAddsRouteToStack() {
        let router = Router<MockRoute>(initial: .home)
        router.push(.details)
        XCTAssertEqual(router.state.stack, [.details])
    }
    
    func testPopRemovesLastRoute() {
        let router = Router<MockRoute>(initial: .home)
        router.push(.details)
        router.pop()
        XCTAssertTrue(router.state.stack.isEmpty)
    }
    
    func testSetRootChangesRootAndClearsStack() {
        let router = Router<MockRoute>(initial: .home)
        router.push(.details)
        router.setRoot(.login)
        XCTAssertEqual(router.state.root, .login)
        XCTAssertTrue(router.state.stack.isEmpty)
    }
    
    func testPresentAndDismissModal() {
        let router = Router<MockRoute>(initial: .home)
        router.present(.modal)
        XCTAssertEqual(router.state.presented, .modal)
        
        router.dismissModal()
        XCTAssertNil(router.state.presented)
    }
}
