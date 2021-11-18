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
    let eventManager = EventManager()
    private var isSetupRunning: Bool = false
    private override init() {
    }
    let reachability = try! Reachability(hostname: "www.apple.com")
    
    @objc public static var enableSurveys: Bool = true {
        didSet {
            ProjectDetailsController.shared.isSuveryEnabled = enableSurveys
        }
    }
    
    @objc public class func configure(_ appKey: String) {
        OneFlowLog("1Flow configuration started")
        ProjectDetailsController.shared.currentEnviromment = .prod
        if ProjectDetailsController.shared.appKey == nil {
            ProjectDetailsController.shared.appKey = appKey
            shared.setupOnce()
            shared.setupReachability()
        } else {
            OneFlowLog("1Flow already setup.")
        }
        
    }
    
    private func setupOnce() {
        let addUserRequest = AddUserRequest(system_id: ProjectDetailsController.shared.systemID, device: AddUserRequest.DeviceDetails(os: "iOS", unique_id: ProjectDetailsController.shared.uniqID, device_id: ProjectDetailsController.shared.deviceID), location: nil)
        OneFlowLog("Adding user")
        self.isSetupRunning = true
        FBAPIController().addUser(addUserRequest) { isSuccess, error, data in
            if isSuccess == true, let data = data {
                do {
                    
                    let surveyListResponse = try JSONDecoder().decode(AddUserResponse.self, from: data)
                    
                    if surveyListResponse.success == 200, let userID = surveyListResponse.result?.analytic_user_id {
                        
                        OneFlowLog("Add user - Success")
                        ProjectDetailsController.shared.analytic_user_id = userID
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
        self.fetchLocationDetails()
    }
    
    private func fetchLocationDetails() {
        OneFlowLog("Fetching geo location")
        FBAPIController().getLocationDetailsUsingIP { isSuccess, error, data in
            if isSuccess == true, let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                        OneFlowLog("Geo Location - Success")
                        ProjectDetailsController.shared.locationDetails = json
                    } else {
                        OneFlowLog("Geo Location - Failed")
                    }
                } catch {
                    OneFlowLog("Geo Location - Failed")
                    OneFlowLog(error)
                }
            }
        }
    }
    
    @objc func reachabilityChanged(note: Notification) {
        
        let reachability = note.object as! Reachability
        switch reachability.connection {
        case .unavailable:
            OneFlowLog("Network: Unreachable")
            ProjectDetailsController.shared.radioConnectivity = nil
            ProjectDetailsController.shared.isCarrierConnectivity = false
            
            if networkTimer != nil, networkTimer?.isValid == true {
                networkTimer?.invalidate()
                networkTimer = nil
            }
            networkTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(networkNotAvailable), userInfo: nil, repeats: false)
            break
        default:
            OneFlowLog("Network: Reachable")
            if reachability.connection.description.lowercased() == "wifi" {
                ProjectDetailsController.shared.radioConnectivity = "wireless"
            } else {
                ProjectDetailsController.shared.isCarrierConnectivity = true
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
        if ProjectDetailsController.shared.analytic_user_id == nil {
            if isSetupRunning == false {
                self.setupOnce()
            }
        }
        self.eventManager.networkStatusChanged(true)
    }
    
    private func setupReachability() {
        OneFlowLog("Network Objerver - Starting")
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
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
        ProjectDetailsController.shared.newUserID = userID
        ProjectDetailsController.shared.newUserData = userDetails
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1) {
            ProjectDetailsController.shared.logNewUserDetails()
        }
    }
    
}
