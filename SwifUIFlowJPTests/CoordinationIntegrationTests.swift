//
//  CoordinationIntegrationTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 2/8/25.
//

import XCTest
@testable import SwifUIFlowJP

final class CoordinationIntegrationTests: XCTestCase {

    // MARK: - Full Navigation Flow
    
    func test_FullNavigationFlowWithTabsModalsAndDeeplinks() {
        let router = Router<MockRoute>(initial: .home)
        let mainCoordinator = TestCoordinator(router: router)
        let modalCoordinator = TestCoordinator(router: Router<MockRoute>(initial: .modal))

        // 1. Switch tab
        router.selectTab(1)
        XCTAssertEqual(router.state.selectedTab, 1, "Expected tab index to change")

        // 2. Present modal coordinator
        mainCoordinator.presentModal(modalCoordinator)
        XCTAssertTrue(mainCoordinator.modalCoordinator === modalCoordinator, "Expected modal coordinator to be presented")

        // 3. Navigate via modal coordinator
        let handledModal = modalCoordinator.navigate(to: .details)
        XCTAssertTrue(handledModal, "Expected modal coordinator to handle navigation")
        XCTAssertEqual(modalCoordinator.lastHandledRoute, .details)

        // 4. Dismiss modal
        mainCoordinator.dismissModal()
        XCTAssertNil(mainCoordinator.modalCoordinator, "Expected modal to be dismissed")

        // 5. Deeplink handled by main coordinator
        mainCoordinator.handleDeeplink(.details)
        XCTAssertTrue(mainCoordinator.didHandleRoute, "Expected deeplink to be handled by main coordinator")
        XCTAssertEqual(mainCoordinator.lastHandledRoute, .details)
    }
}

