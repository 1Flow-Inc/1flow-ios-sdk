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
    var eventExpectation: XCTestExpectation!
    var isNetworkReachable: Bool
    var surveyManager: OFSurveyManager!
    var finalParameter: [String: Any]?

    override init() {
        isNetworkReachable = true
        super.init()
        surveyManager = OFSurveyManager()
        eventExpectation = XCTestExpectation()
    }
    
    init(_ expectation: XCTestExpectation) {
        
        isNetworkReachable = true
        super.init()
        surveyManager = OFSurveyManager()
        eventExpectation = expectation
    }

    func networkStatusChanged(_ isReachable: Bool) {
        
    }

    func finishPendingEvents() {
        
    }

    func recordEvent(_ name: String, parameters: [String: Any]?) {
        finalParameter = parameters
        eventExpectation.fulfill()
    }

    func configure() {
        
    }

    func setupSurveyManager() {
        
    }
}
