//
//  CoordinationIntegrationTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 2/8/25.
//

import XCTest
@testable import SwiftUIFlow

final class CoordinationIntegrationTests: XCTestCase {

    func testFullNavigationFlowWithTabsModalsAndDeeplinks() {
        let router = Router<MockRoute>(initial: .home)
        let main = TestCoordinator(router: router)
        let modal = TestCoordinator(router: Router<MockRoute>(initial: .modal))

        // 1. Switch tab
        router.selectTab(1)
        XCTAssertEqual(router.state.selectedTab, 1, "Expected tab index to change")

        // 2. Present modal coordinator
        main.presentModal(modal)
        XCTAssertTrue(main.modalCoordinator === modal, "Expected modal coordinator to be presented")

        // 3. Navigate via modal coordinator
        let handledModal = modal.navigate(to: .details)
        XCTAssertTrue(handledModal, "Expected modal coordinator to handle navigation")
        XCTAssertEqual(modal.lastHandledRoute, .details)

        // 4. Dismiss modal
        main.dismissModal()
        XCTAssertNil(main.modalCoordinator, "Expected modal to be dismissed")

        // 5. Deeplink handled by main coordinator
        main.handleDeeplink(.details)
        XCTAssertTrue(main.didHandleRoute, "Expected deeplink to be handled by main coordinator")
        XCTAssertEqual(main.lastHandledRoute, .details)
    }
}
