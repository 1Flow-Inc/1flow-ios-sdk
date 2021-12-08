//
//  OneFlow.swift
//  Feedback
//
//  Created by Rohan Moradiya on 16/06/21.
//

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
    
    @objc public static var enableSurveys: Bool = true {
        didSet {
            OFProjectDetailsController.shared.isSuveryEnabled = enableSurveys
        }
    }
    
    @objc public class func configure(_ appKey: String) {
        OneFlowLog("1Flow configuration started")
        if OFProjectDetailsController.shared.appKey == nil {
            OFProjectDetailsController.shared.appKey = appKey
            shared.setupOnce()
            shared.setupReachability()
        } else {
            OneFlowLog("1Flow already setup.")
        }
    }
    
    private func setupOnce() {
        let addUserRequest = AddUserRequest(system_id: OFProjectDetailsController.shared.systemID, device: AddUserRequest.DeviceDetails(os: "iOS", unique_id: OFProjectDetailsController.shared.uniqID, device_id: OFProjectDetailsController.shared.deviceID), location: nil)
        OneFlowLog("Adding user")
        self.isSetupRunning = true
        OFAPIController().addUser(addUserRequest) { isSuccess, error, data in
            if isSuccess == true, let data = data {
                do {
                    
                    let surveyListResponse = try JSONDecoder().decode(AddUserResponse.self, from: data)
                    
                    if surveyListResponse.success == 200, let userID = surveyListResponse.result?.analytic_user_id {
                        
                        OneFlowLog("Add user - Success")
                        OFProjectDetailsController.shared.analytic_user_id = userID
                        OneFlow.shared.eventManager.isNetworkReachable = true
                        OneFlow.shared.eventManager.configure()
                        
                    } else {
                        OneFlowLog("Add user - Failed")
                    }
                } catch {
                    OneFlowLog("Add user - Failed")
                    OneFlowLog(error)
                }
            } else {
                OneFlowLog("Add user - Failed")
            }
            self.isSetupRunning = false
        }
    }

    @objc func reachabilityChanged(note: Notification) {
        
        let reachability = note.object as! OFReachability
        switch reachability.connection {
        case .unavailable:
            OneFlowLog("Network: Unreachable")
            OFProjectDetailsController.shared.radioConnectivity = nil
            OFProjectDetailsController.shared.isCarrierConnectivity = false
            
            if networkTimer != nil, networkTimer?.isValid == true {
                networkTimer?.invalidate()
                networkTimer = nil
            }
            networkTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(networkNotAvailable), userInfo: nil, repeats: false)
            break
        default:
            OneFlowLog("Network: Reachable")
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
        OneFlowLog("Network Objerver - Starting")
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .OFreachabilityChanged, object: reachability)
        do{
            try reachability.startNotifier()
            OneFlowLog("Network Objerver - Success")
        }catch{
            OneFlowLog("Network Objerver - Failed")
        }
    }
    
    
    @objc class public func recordEventName(_ eventName: String, parameters: [String: Any]?) {
        DispatchQueue.global().async {
            shared.eventManager.recordEvent(eventName, parameters: parameters)
        }        
    }
    
    @objc class public func logUser(_ userID: String, userDetails: [String: Any]?) {
        OneFlowLog("Log new user")
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
