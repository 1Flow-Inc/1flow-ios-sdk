//
//  EventManagerTests.swift
//  1Flow_Tests
//
//  Created by Rohan Moradiya on 15/06/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import XCTest
@testable import _1Flow
@testable import _Flow_Example

class EventManagerTest: XCTestCase {

    func testEventManager_ApplicationDidBecomeActive_shouldStartEventTimer() {
        // Arrange
        let eventManager = OFEventManager()
        let mockProjectDetails = MockProjectDetailsController()
        mockProjectDetails.analytic_user_id = "Some_id"
        eventManager.projectDetailsController = mockProjectDetails
        eventManager.isNetworkReachable = true
        // Act
        eventManager.applicationBecomeActive()
        // Assert
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            guard let timer = eventManager.uploadTimer else {
                XCTFail("It should have timer object")
                return
            }
            XCTAssertTrue(timer.isValid)
        }
    }

    func testEventManager_ApplicationEnterBackground_shouldInvalidateEventTimer() {
        // Arrange
        let eventManager = OFEventManager()
        let mockProjectDetails = MockProjectDetailsController()
        eventManager.projectDetailsController = mockProjectDetails
        eventManager.isNetworkReachable = true
        eventManager.uploadTimer = Timer.scheduledTimer(timeInterval: 60, target: eventManager, selector: #selector(eventManager.sendEventsToServer), userInfo: nil, repeats: true)
        // Act
        eventManager.applicationMovedToBackground()
        // Assert
        XCTAssertNil(eventManager.uploadTimer, "upload timer should be nil")
    }

    func testEventManager_ApplicationEnterBackground_shouldCallSendEventToServer() {
        // Arrange
        class SampleClass: OFEventManager {
            let expectation: XCTestExpectation!
            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }
            override func sendEventsToServer() {
                expectation.fulfill()
            }
        }
        let expectation = XCTestExpectation(description: "Should call send event to server")
        let eventManager = SampleClass(expectation: expectation)
        
        let mockProjectDetails = MockProjectDetailsController()
        mockProjectDetails.analytic_user_id = "Some_user"
        eventManager.projectDetailsController = mockProjectDetails
        eventManager.isNetworkReachable = true
        // Act
        eventManager.applicationMovedToBackground()
        // Assert
        let result = XCTWaiter().wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(result, .completed)
    }

    func testEventManager_networkNotAvailable_shouldInvalidateUploadTimer() {
        // Arrange
        let eventManager = OFEventManager()
        let mockProjectDetails = MockProjectDetailsController()
        eventManager.projectDetailsController = mockProjectDetails
        eventManager.isNetworkReachable = true
        eventManager.uploadTimer = Timer.scheduledTimer(timeInterval: 60, target: eventManager, selector: #selector(eventManager.sendEventsToServer), userInfo: nil, repeats: true)
        // Act
        eventManager.networkStatusChanged(false)
        // Assert
        XCTAssertNil(eventManager.uploadTimer, "upload timer should be nil")
    }

    func testEventManager_networkAvailable_shouldStartUploadTimer() {
        // Arrange
        let eventManager = OFEventManager()
        let mockProjectDetails = MockProjectDetailsController()
        eventManager.projectDetailsController = mockProjectDetails
        eventManager.isNetworkReachable = true
        eventManager.uploadTimer = nil
        // Act
        eventManager.networkStatusChanged(true)
        // Assert
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            guard let timer = eventManager.uploadTimer else {
                XCTFail("It should have timer object")
                return
            }
            XCTAssertTrue(timer.isValid)
        }
    }
}
