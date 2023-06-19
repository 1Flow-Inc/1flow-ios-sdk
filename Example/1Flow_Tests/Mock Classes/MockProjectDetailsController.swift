//
//  MockProjectDetailsController.swift
//  1Flow_Tests
//
//  Created by Rohan Moradiya on 30/04/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

@testable import _1Flow
@testable import _Flow_Example
import Foundation

class MockProjectDetailsController: ProjectDetailsManageable {
    var appVersion: String = "NA"
    
    var buildVersion: String = "NA"
    
    var modelName: String? = "NA"
    
    var libraryVersion: String = "2023.06.21"
    
    var osVersion: String = "NA"
    
    var screenWidth: Int = 100
    
    var screenHeight: Int = 100
    
    var isWifiConnection: Bool = true
    
    var careerName: String?
    
    let oneFlowSDKVersion: String = "Mock_version"

    var logUserRetryCount: Int = 1

    var currentEnviromment: OneFlowEnvironment = .dev
    
    var currentLogLevel: OneFlowLogLevel = .none
    
    var appKey: String! = nil
    
    var isSuveryEnabled: Bool = false
    
    var systemID: String! = "mock_system_id"
    
    var analytic_user_id: String?
    
    var currentLoggedUserID: String?
    
    var radioConnectivity: String?
    
    var isCarrierConnectivity: Bool = false
    
    var newUserID: String?
    
    var newUserData: [String : Any]?
    
    func setLoglevel(_ newLogLevel: OneFlowLogLevel) {
        currentLogLevel = newLogLevel
    }
    
    func logNewUserDetails(_ completion: @escaping (Bool) -> Void) {
        
    }
    
    func getLocalisedLanguageName() -> String {
        return "English"
    }
    
    
}
    

