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
