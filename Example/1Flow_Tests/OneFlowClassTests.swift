//
//  OneFlowClassTests.swift
//  1Flow_Tests
//
//  Created by Rohan Moradiya on 30/04/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import XCTest
@testable import _1Flow
@testable import _Flow_Example

class OneFlowTests: XCTestCase {
    var apiController = MockAPIController()
    var projectDetailsControoler = MockProjectDetailsController()

    override func setUp() {
        super.setUp()
        OneFlow.shared.apiController = apiController
        OneFlow.shared.projectDetailsController = projectDetailsControoler
//        apiController = MockAPIController()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testConfigureOneFlow_CallingMultipleTimeOnlyCallAddUserOnce() {
        OneFlow.configure("MyKey")
        XCTAssertTrue(apiController.isAddUserCalled, "Add user not called when calling configure")
        apiController.isAddUserCalled = false
        OneFlow.configure("MyKey2")
        XCTAssertFalse(apiController.isAddUserCalled, "Calling configure multiple times should not call add user again")
    }

    func testRecordEvent_shouldCall_EventManagerRecordEvent() {
        let expectation = XCTestExpectation()
        let eventManager = MockEventManager(expectation)
        OneFlow.shared.eventManager = eventManager
        OneFlow.recordEventName("Event", parameters: nil)
        self.wait(for: [expectation], timeout: 1.0)
    }

    func testRecordEvent_IfDatePassedInParams_itShouldConvertToTimeInterval() {
        let expectation = XCTestExpectation()
        let date = Date()
        let expectedInterval = Int(date.timeIntervalSince1970)
        let params = ["date": date]
        let eventManager = MockEventManager(expectation)
        OneFlow.shared.eventManager = eventManager
        OneFlow.recordEventName("Event", parameters: params)
        self.wait(for: [expectation], timeout: 1.0)
        guard let receivedParams = eventManager.finalParameter else {
            XCTFail("Event manager should receive parameter")
            return
        }
        guard let receivedDate = receivedParams["date"] as? Int else {
            XCTFail("Date should be interger value in final params")
            return
        }
        XCTAssertEqual(expectedInterval, receivedDate, "Interval should match")
    }
}
