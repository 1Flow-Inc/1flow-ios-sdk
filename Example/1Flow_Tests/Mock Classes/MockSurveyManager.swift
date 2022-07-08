//
//  MockSurveyManager.swift
//  1Flow_Tests
//
//  Created by Rohan Moradiya on 14/06/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import _1Flow

class MockSurveyManager: NSObject, SurveyManageable {
    var isNetworkReachable: Bool = true
    var surveyExpectation: XCTestExpectation?
    var projectDetailsController: ProjectDetailsManageable! = MockProjectDetailsController()
    
    override init() {
        isNetworkReachable = true
        super.init()
    }
    
    init(_ expectation: XCTestExpectation) {
        super.init()
        surveyExpectation = expectation
    }
    
    func uploadPendingSurveyIfAvailable() {
        surveyExpectation?.fulfill()
    }
    
    func networkStatusChanged(_ isReachable: Bool) {
        isNetworkReachable = isReachable
    }
    
    func cleanUpSurveyArray() {
        
    }
    
    func configureSurveys() {
        
    }
    
    func newEventRecorded(_ eventName: String) {
        
    }
    
    func setUserToSubmittedSurveyAsAnnonyous(newUserID: String) {
        
    }
    
    
}
