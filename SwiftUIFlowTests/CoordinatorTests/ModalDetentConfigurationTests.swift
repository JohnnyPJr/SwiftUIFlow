//
//  ModalDetentConfigurationTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 23/7/26.
//

import SwiftUI
@testable import SwiftUIFlow
import XCTest

final class ModalDetentConfigurationTests: XCTestCase {
    func test_FullscreenOnly_UsesFullScreenCover() {
        let sut = ModalDetentConfiguration(detents: [.fullscreen])

        XCTAssertTrue(sut.shouldUseFullScreenCover)
    }

    func test_FullscreenMixedWithOtherDetents_UsesSheetPresentation() {
        let sut = ModalDetentConfiguration(detents: [.medium, .fullscreen])

        XCTAssertFalse(sut.shouldUseFullScreenCover)
    }

    func test_MediumDetent_MapsToSwiftUIMediumPresentationDetent() {
        let sut = ModalDetentConfiguration(detents: [.medium])

        XCTAssertEqual(sut.toPresentationDetent(.medium), .medium)
    }

    func test_LargeDetent_MapsToFractionPresentationDetent() {
        let sut = ModalDetentConfiguration(detents: [.large])

        XCTAssertEqual(sut.toPresentationDetent(.large), .fraction(0.999))
    }

    func test_CustomDetent_UsesIdealHeightWithFallback() {
        let customHeightSUT = ModalDetentConfiguration(detents: [.custom],
                                                       idealHeight: 320)
        let fallbackSUT = ModalDetentConfiguration(detents: [.custom])

        XCTAssertEqual(customHeightSUT.toPresentationDetent(.custom), .height(320))
        XCTAssertEqual(fallbackSUT.toPresentationDetent(.custom), .height(200))
    }
}
