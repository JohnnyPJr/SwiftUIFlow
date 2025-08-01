//
//  NavigationStateTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 1/8/25.
//

import XCTest
@testable import SwiftUIFlow

final class NavigationStateTests: XCTestCase {
    func testInitialStateHasCorrectRootAndDefaults() {
        let state = NavigationState<MockRoute>(root: .login)
        
        XCTAssertEqual(state.root, .login)
        XCTAssertTrue(state.stack.isEmpty, "Stack should be empty on initialization")
        XCTAssertEqual(state.selectedTab, 0, "Default selected tab should be 0")
        XCTAssertNil(state.presented, "No modal should be presented initially")
    }
    
    func testPushAndPopUpdatesStack() {
        var state = NavigationState<MockRoute>(root: .home)
        
        state.stack.append(.details)
        XCTAssertEqual(state.stack.count, 1)
        XCTAssertEqual(state.stack.last, .details)
        
        _ = state.stack.popLast()
        XCTAssertTrue(state.stack.isEmpty)
    }
    
    func testPresentedModalCanBeSetAndDismissed() {
        var state = NavigationState<MockRoute>(root: .home)
        
        state.presented = .modal
        XCTAssertEqual(state.presented, .modal)
        
        state.presented = nil
        XCTAssertNil(state.presented)
    }
    
    func testSelectedTabCanBeChanged() {
        var state = NavigationState<MockRoute>(root: .home)
        
        state.selectedTab = 2
        XCTAssertEqual(state.selectedTab, 2)
    }
}
