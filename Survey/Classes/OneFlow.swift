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
    static let shared = OneFlow()
    private var networkTimer: Timer?
    var eventManager: EventManagerProtocol = OFEventManager()
    private var isSetupRunning: Bool = false
    static var retryCount = 0
    var identifyCallPending = false
    private override init() {
    }
    let reachability = try! OFReachability(hostname: "www.apple.com")
    static var fontConfiguration: SurveyFontConfigurable? = SurveyFontConfiguration()
    var apiController : APIProtocol = OFAPIController()
    var projectDetailsController: ProjectDetailsManageable = OFProjectDetailsController.shared
    
    @objc public static var enableSurveys: Bool = true {
        didSet {
            OneFlow.shared.projectDetailsController.isSuveryEnabled = enableSurveys
        }
    }
    
    @objc public class func configure(_ appKey: String) {
        OneFlowLog.writeLog("1Flow configuration started")
        if OneFlow.shared.projectDetailsController.appKey == nil {
            shared.setupReachability()
            shared.projectDetailsController.appKey = appKey
            shared.projectDetailsController.setLoglevel(.info)
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 3, execute: {
                if OFProjectDetailsController.shared.analytic_user_id == nil {
                    if shared.isSetupRunning == false {
                        shared.setupOnce()
                    }
                }
            })
        } else {
            OneFlowLog.writeLog("Error: 1Flow already setup.", .info)
        }
    }

    @objc public class func useFont(fontFamily: String?) {
        OneFlow.fontConfiguration = SurveyFontConfiguration(fontName: fontFamily)
    }

    private func setupOnce() {

        let context = AddUserRequest.Context(
            app: AddUserRequest.Context.AppDetails(
                version: projectDetailsController.appVersion,
                build: projectDetailsController.buildVersion
            ),
            device: AddUserRequest.Context.DeviceDetails(
                manufacturer: "apple",
                model: projectDetailsController.modelName
            ),
            library: AddUserRequest.Context.LibraryDetails(
                version: projectDetailsController.libraryVersion,
                name: "iOS"
            ),
            network: AddUserRequest.Context.NetworkDetails(
                carrier: projectDetailsController.careerName,
                wifi: projectDetailsController.isWifiConnection
            ),
            os: AddUserRequest.Context.OSDetails(
                name: "iOS",
                version: projectDetailsController.osVersion
            ),
            screen: AddUserRequest.Context.ScreenDetails(
                width: projectDetailsController.screenWidth,
                height: projectDetailsController.screenHeight,
                type: "mobile"
            )
        )
        let addUserRequest = AddUserRequest(
            user_id: OneFlow.shared.projectDetailsController.systemID,
            context: context
        )
        OneFlowLog.writeLog("Adding user")
        self.isSetupRunning = true
        self.apiController.addUser(addUserRequest, completion: { isSuccess, error, data in
            if isSuccess == true, let data = data {
                do {
                    let addUserResponse = try JSONDecoder().decode(AddUserResponse.self, from: data)
                    if addUserResponse.success == 200, let userID = addUserResponse.result?.analytic_user_id {
                        
                        OneFlowLog.writeLog("Add user - Success")
                        OneFlow.shared.projectDetailsController.analytic_user_id = userID
                        if OneFlow.shared.identifyCallPending {
                            OneFlowLog.writeLog("Calling pending log user", .info)
                            OneFlow.shared.identifyCallPending = false
                            OneFlow.shared.projectDetailsController.logNewUserDetails { isSuccess in
                                if isSuccess == true {
                                    OneFlow.shared.eventManager.isNetworkReachable = true
                                    OneFlow.shared.eventManager.configure()
                                    OneFlow.shared.eventManager.surveyManager.setUserToSubmittedSurveyAsAnnonyous(newUserID: userID)
                                }
                            }
                        } else {
                            OneFlowLog.writeLog("No pending log user", .info)
                            OneFlow.shared.eventManager.isNetworkReachable = true
                            OneFlow.shared.eventManager.configure()
                        }
                    } else {
                        OneFlowLog.writeLog("Add user - Failed", .error)
                    }
                } catch {
                    OneFlowLog.writeLog("Add user - Failed", .error)
                    OneFlowLog.writeLog(error.localizedDescription)
                }
            } else {
                OneFlowLog.writeLog("Add user - Failed", .error)
            }
            self.isSetupRunning = false
        })
        
    }

    @objc func reachabilityChanged(note: Notification) {
        let reachability = note.object as! OFReachability
        switch reachability.connection {
        case .unavailable:
            OneFlowLog.writeLog("Network: Unreachable")
            OneFlow.shared.projectDetailsController.isWifiConnection = false
            
            if networkTimer != nil, networkTimer?.isValid == true {
                networkTimer?.invalidate()
                networkTimer = nil
            }
            networkTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(networkNotAvailable), userInfo: nil, repeats: false)
            break
        default:
            OneFlowLog.writeLog("Network: Reachable")
            if reachability.connection.description.lowercased() == "wifi" {
                OneFlow.shared.projectDetailsController.isWifiConnection = true
            } else {
                OneFlow.shared.projectDetailsController.isWifiConnection = false
            }
            
            if networkTimer != nil, networkTimer?.isValid == true {
                networkTimer?.invalidate()
                networkTimer = nil
            }
            networkTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(networkAvailable), userInfo: nil, repeats: false)
            
            break
        }
        self.setupOnce()
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
        OneFlowLog.writeLog("Network Observer - Starting")
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .OFreachabilityChanged, object: reachability)
        do {
            try reachability.startNotifier()
            OneFlowLog.writeLog("Network Observer - Success")
        } catch {
            OneFlowLog.writeLog("Network Observer - Failed", .error)
        }
    }

    @objc class public func startFlow(_ flowId: String) {
        shared.eventManager.surveyManager.startFlow(with: flowId)
    }

    @objc class public func recordEventName(_ eventName: String, parameters: [String: Any]?) {
        guard !eventName.isEmpty else {
            OneFlowLog.writeLog("Empty event logged. returned", .warnings)
            return
        }
        var parameterDic : [String : Any]? = nil
        if let updatedParameterDic : [String : Any] = OneFlow.removeUnsupportedKeys(parameters) {
            parameterDic = updatedParameterDic
        }
        DispatchQueue.global().async {
            shared.eventManager.recordEvent(eventName, parameters: parameterDic)
        }
    }
    
    @objc class public func logUser(_ userID: String, userDetails: [String: Any]?) {

        let userID = userID.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if userID.isEmpty {
            OneFlowLog.writeLog("User id must not be empty to log user", .info)
            return
        }
        
        if let userDetailsDic : [String : Any] = OneFlow.removeUnsupportedKeys(userDetails) {
            let logUserInfo = ["UserID":userID, "userDetails": userDetailsDic] as [String : Any]
            UserDefaults.standard.set(logUserInfo, forKey: "OFlogUserInfo")
            shared.projectDetailsController.newUserData = userDetailsDic
        } else {
            OneFlow.shared.projectDetailsController.newUserData = nil
        }
        guard shared.projectDetailsController.analytic_user_id != nil else {
            OneFlowLog.writeLog("Analytics user id yet not generated.", .info)
            shared.projectDetailsController.newUserID = userID
            OneFlow.shared.identifyCallPending = true
            return
        }
        OneFlowLog.writeLog("Data can be Serialized")
        OneFlowLog.writeLog("Log new user")
        shared.eventManager.finishPendingEvents()
        shared.projectDetailsController.newUserID = userID
        shared.projectDetailsController.logUserRetryCount = 0
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1) {
            OneFlow.shared.projectDetailsController.logNewUserDetails { isSuccess in
                if isSuccess == true {
                    UserDefaults.standard.removeObject(forKey: "OFlogUserInfo")
                    shared.eventManager.surveyManager.setUserToSubmittedSurveyAsAnnonyous(newUserID: userID)
                    shared.eventManager.setupSurveyManager()
                }
            }
        }
    }
    
    @objc class private func getSerialisedString(_ value : Any) -> Any? {
        if let valueDate = value as? Date {
            let interval = Int(valueDate.timeIntervalSince1970)
            return interval
        }
        else if let valueUrl = value as? URL {
            return valueUrl.absoluteString
        }
        return nil
    }
    
    @objc class private func removeUnsupportedKeys(_ userDetails: [String: Any]?) ->  [String: Any]? {
        guard var userDetailsDic : [String : Any?] = userDetails else {return nil}
        for (key, value) in userDetailsDic {
            if value == nil {
                userDetailsDic.removeValue(forKey: key)
                continue
            }
            if !JSONSerialization.isValidJSONObject([key:value]) {
                if let dicValue : [String : Any] = value as? [String : Any] {
                    if let newDic : [String : Any] = self.removeUnsupportedKeys(dicValue) {
                        userDetailsDic.updateValue(newDic, forKey: key)
                    }
                }
                else if let arrayValue : [Any?]  = value as? [Any] {
                    var newArray : [Any?] = []
                    for arrayObj in arrayValue {
                        if arrayObj == nil {
                           continue
                        }
                        if (JSONSerialization.isValidJSONObject(["key":arrayObj])) {
                            newArray.append(arrayObj)
                        }
                        else if let newValue = OneFlow.getSerialisedString(arrayObj as Any) {
                            newArray.append(newValue)
                        }
                    }
                    userDetailsDic.updateValue(newArray, forKey: key)
                    
                }
                else if let newValue = OneFlow.getSerialisedString(value as Any) {
                    userDetailsDic.updateValue(newValue, forKey: key)
                }
                else {
                    userDetailsDic.removeValue(forKey: key)
                }
            }
        }
        return userDetailsDic as [String : Any]
    }
    
}
