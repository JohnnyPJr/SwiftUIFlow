//
//  NavigationStateTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 1/8/25.
//

import XCTest
@testable import SwifUIFlowJP

final class NavigationStateTests: XCTestCase {

    // MARK: - Initialization
    
    func test_InitialStateHasEmptyStackAndDefaultTab() {
        let state = NavigationState(root: MockRoute.home)
        XCTAssertEqual(state.root, .home)
        XCTAssertTrue(state.stack.isEmpty)
        XCTAssertEqual(state.selectedTab, 0)
        XCTAssertNil(state.presented)
    }

    // MARK: - Stack Management
    
    func test_CanPushRouteOntoStack() {
        var state = NavigationState(root: MockRoute.home)
        state.stack.append(.details)
        XCTAssertEqual(state.stack, [.details])
    }
    
    func test_CanPopRouteFromStack() {
        var state = NavigationState(root: MockRoute.home)
        state.stack.append(.details)
        _ = state.stack.popLast()
        XCTAssertTrue(state.stack.isEmpty)
    }

    // MARK: - Modal Handling
    
    func test_CanPresentAndDismissModal() {
        var state = NavigationState(root: MockRoute.home)
        state.presented = .modal
        XCTAssertEqual(state.presented, .modal)

        state.presented = nil
        XCTAssertNil(state.presented)
    }

    // MARK: - Tab Selection
    
    func test_CanChangeSelectedTab() {
        var state = NavigationState(root: MockRoute.home)
        state.selectedTab = 2
        XCTAssertEqual(state.selectedTab, 2)
    }
}

