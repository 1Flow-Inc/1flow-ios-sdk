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
import UIKit

public final class OneFlow: NSObject {
    private static let shared = OneFlow()
    private var networkTimer: Timer?
    private let eventManager = OFEventManager()
    private var isSetupRunning: Bool = false
    private override init() {
    }
    let reachability = try! OFReachability(hostname: "www.apple.com")
    
    var apiController : APIProtocol = OFAPIController()
    
    @objc public static var enableSurveys: Bool = true {
        didSet {
            OFProjectDetailsController.shared.isSuveryEnabled = enableSurveys
        }
    }
    
    @objc public class func configure(_ appKey: String) {
        OneFlowLog.writeLog("1Flow configuration started")
        if OFProjectDetailsController.shared.appKey == nil {
            OFProjectDetailsController.shared.appKey = appKey
            OFProjectDetailsController.shared.setLoglevel(.none)
            shared.setupOnce()
            shared.setupReachability()
        } else {
            OneFlowLog.writeLog("1Flow already setup.")
        }
    }
    
    private func setupOnce() {
        let addUserRequest = AddUserRequest(system_id: OFProjectDetailsController.shared.systemID, device: AddUserRequest.DeviceDetails(os: "iOS", unique_id: OFProjectDetailsController.shared.uniqID, device_id: OFProjectDetailsController.shared.deviceID), location: nil)
        OneFlowLog.writeLog("Adding user")
        self.isSetupRunning = true
        self.apiController.addUser(addUserRequest, completion: { isSuccess, error, data in
            if isSuccess == true, let data = data {
                do {
                    let surveyListResponse = try JSONDecoder().decode(AddUserResponse.self, from: data)
                    if surveyListResponse.success == 200, let userID = surveyListResponse.result?.analytic_user_id {
                        
                        OneFlowLog.writeLog("Add user - Success")
                        OFProjectDetailsController.shared.analytic_user_id = userID
                        OneFlow.shared.eventManager.isNetworkReachable = true
                        OneFlow.shared.eventManager.configure()
                        
                    } else {
                        OneFlowLog.writeLog("Add user - Failed")
                    }
                } catch {
                    OneFlowLog.writeLog("Add user - Failed")
                    OneFlowLog.writeLog(error.localizedDescription)
                }
            } else {
                OneFlowLog.writeLog("Add user - Failed")
            }
            self.isSetupRunning = false
        })
        
    }

    @objc func reachabilityChanged(note: Notification) {
        
        let reachability = note.object as! OFReachability
        switch reachability.connection {
        case .unavailable:
            OneFlowLog.writeLog("Network: Unreachable")
            OFProjectDetailsController.shared.radioConnectivity = nil
            OFProjectDetailsController.shared.isCarrierConnectivity = false
            
            if networkTimer != nil, networkTimer?.isValid == true {
                networkTimer?.invalidate()
                networkTimer = nil
            }
            networkTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(networkNotAvailable), userInfo: nil, repeats: false)
            break
        default:
            OneFlowLog.writeLog("Network: Reachable")
            if reachability.connection.description.lowercased() == "wifi" {
                OFProjectDetailsController.shared.radioConnectivity = "wireless"
            } else {
                OFProjectDetailsController.shared.isCarrierConnectivity = true
            }
            
            if networkTimer != nil, networkTimer?.isValid == true {
                networkTimer?.invalidate()
                networkTimer = nil
            }
            networkTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(networkAvailable), userInfo: nil, repeats: false)
            
            break
        }
    }
    
    @objc private func networkNotAvailable() {
        self.eventManager.networkStatusChanged(false)
    }
    
    @objc private func networkAvailable() {
        if OFProjectDetailsController.shared.analytic_user_id == nil {
            if isSetupRunning == false {
                self.setupOnce()
            }
        }
        self.eventManager.networkStatusChanged(true)
    }
    
    private func setupReachability() {
        OneFlowLog.writeLog("Network Objerver - Starting")
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .OFreachabilityChanged, object: reachability)
        do {
            try reachability.startNotifier()
            OneFlowLog.writeLog("Network Objerver - Success")
        } catch {
            OneFlowLog.writeLog("Network Objerver - Failed")
        }
    }
    
    @objc class public func recordEventName(_ eventName: String, parameters: [String: Any]?) {
        DispatchQueue.global().async {
            shared.eventManager.recordEvent(eventName, parameters: parameters)
        }        
    }
    
    @objc class public func logUser(_ userID: String, userDetails: [String: Any]?) {
        OneFlowLog.writeLog("Log new user")
        shared.eventManager.finishPendingEvents()
        OFProjectDetailsController.shared.newUserID = userID
        OFProjectDetailsController.shared.newUserData = userDetails
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1) {
            OFProjectDetailsController.shared.logNewUserDetails { isSuccess in
                if isSuccess == true {
                    shared.eventManager.surveyManager.setUserToSubmittedSurveyAsAnnonyous(newUserID: userID)
                }
            }
        }
    } 
}
