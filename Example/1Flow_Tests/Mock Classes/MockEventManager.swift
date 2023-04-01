//
//  MockEventManager.swift
//  1Flow_Tests
//
//  Created by Rohan Moradiya on 03/05/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import _1Flow

class MockEventManager: NSObject, EventManagerProtocol {
    var eventExpectation: XCTestExpectation?
    var isNetworkReachable: Bool
    var surveyManager: SurveyManageable!
    var finalParameter: [String: Any]?
    var projectDetailsController: ProjectDetailsManageable! = MockProjectDetailsController()

    override init() {
        isNetworkReachable = true
        super.init()
        surveyManager = MockSurveyManager()
    }
    
    init(_ expectation: XCTestExpectation) {
        isNetworkReachable = true
        super.init()
        surveyManager = MockSurveyManager()
        eventExpectation = expectation
    }

    init(_ expectation: XCTestExpectation, surveyExpectation: XCTestExpectation) {
        isNetworkReachable = true
        super.init()
        surveyManager = MockSurveyManager(surveyExpectation)
        eventExpectation = expectation
    }

    func networkStatusChanged(_ isReachable: Bool) {
    }

    func finishPendingEvents() {
        eventExpectation?.fulfill()
    }

    func recordEvent(_ name: String, parameters: [String: Any]?) {
        finalParameter = parameters
        eventExpectation?.fulfill()
    }

    func recordInternalEvent(name: String, parameters: [String : Any]) {
    }

    func configure() {
        eventExpectation?.fulfill()
    }

    func setupSurveyManager() {
    }
}
