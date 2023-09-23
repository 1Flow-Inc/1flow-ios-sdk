// Copyright 2021 1Flow, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest
@testable import _1Flow
@testable import _Flow_Example

class EventManagerTest: XCTestCase {

    func testEventManager_ApplicationDidBecomeActive_shouldStartEventTimer() {
        // Arrange
        let eventManager = OFEventManager()
        let mockProjectDetails = MockProjectDetailsController()
        mockProjectDetails.analyticUserID = "Some_id"
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
        mockProjectDetails.analyticUserID = "Some_user"
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
