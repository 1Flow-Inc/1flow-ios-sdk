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

class OneFlowProductionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCurrentEnvironmentMode() {
        // This is an example of a functional test case.
        let appdel : AppDelegate =  UIApplication.shared.delegate as! AppDelegate
        XCTAssertNotNil(appdel)
        appdel.setupOneFlow()
        XCTAssertTrue(OFProjectDetailsController.shared.currentEnviromment == .prod)
        
    }
    
    func testCurrentProjectKey() {
        // This is an example of a functional test case.
        let appdel : AppDelegate =  UIApplication.shared.delegate as! AppDelegate
        XCTAssertNotNil(appdel)
        appdel.setupOneFlow()
        XCTAssertEqual(OFProjectDetailsController.shared.appKey, "YOUR_1FLOW_PROJECT_KEY")
        
    }
    
    func testCurrentlogLevel() {
        // This is an example of a functional test case.
        let appdel : AppDelegate =  UIApplication.shared.delegate as! AppDelegate
        XCTAssertNotNil(appdel)
        appdel.setupOneFlow()
        XCTAssertTrue(OFProjectDetailsController.shared.currentLogLevel == .none)
        
    }
    
}


final class MockAPIController: NSObject, APIProtocol {
    func addUser(_ parameter: AddUserRequest, completion: @escaping APICompletionBlock) {
        print("MockAPIController addUser")
    }
    
    
}