//
//  MemoryLeakTracking.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 5/11/25.
//

import XCTest

extension XCTestCase {
    /// Tracks an instance for memory leaks.
    ///
    /// This helper verifies that an instance is properly deallocated by the end of the test.
    /// If the instance is still alive in the teardown phase, the test fails with a clear message
    /// indicating a potential memory leak.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// func test_Coordinator_DeallocatesWhenRemoved() {
    ///     let parent = TestCoordinator()
    ///     let child = TestCoordinator()
    ///     trackForMemoryLeaks(child)  // Automatically verified in teardown
    ///
    ///     parent.addChild(child)
    ///     parent.removeChild(child)
    ///     // child should be deallocated - test will fail if it's not
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - instance: The instance to track for deallocation
    ///   - file: The file where tracking is called (auto-populated)
    ///   - line: The line where tracking is called (auto-populated)
    func trackForMemoryLeaks(_ instance: AnyObject,
                             file: StaticString = #filePath,
                             line: UInt = #line)
    {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance,
                         "Instance should have been deallocated. Potential memory leak.",
                         file: file,
                         line: line)
        }
    }
}
