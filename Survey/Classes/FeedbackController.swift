//
//  FeedbackController.swift
//  Feedback
//
//  Created by Rohan Moradiya on 16/06/21.
//

import Foundation
import UIKit


public class FeedbackController: NSObject {
    
    private static let shared = FeedbackController()
    private var networkTimer: Timer?
    let eventManager = EventManager()
    private var isSetupRunning: Bool = false
    private override init() {
    }
    let reachability = try! Reachability(hostname: "www.apple.com")
    
    @objc public class func configure(_ appKey: String) {
        FBLogs("1Flow configuration started")
        ProjectDetailsController.shared.appKey = appKey
        shared.setupOnce()
        shared.setupReachability()
    }
    
    private func setupOnce() {
        self.isSetupRunning = true
        
        let addUserRequest = AddUserRequest(system_id: ProjectDetailsController.shared.uniqID, device: AddUserRequest.DeviceDetails(os: "iOS", unique_id: ProjectDetailsController.shared.uniqID, device_id: ProjectDetailsController.shared.deviceID), location: nil)
        
        FBLogs("Adding user")
        FBAPIController().addUser(addUserRequest) { isSuccess, error, data in
            if isSuccess == true, let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any], let result = json["result"] as? [String: Any], let userID = result["analytic_user_id"] as? String {
                        FBLogs("Add user - Success")
                        ProjectDetailsController.shared.analytic_user_id = userID
//                        if FeedbackController.shared.eventManager == nil {
//                            FeedbackController.shared.eventManager = EventManager()
//                        }
                        FeedbackController.shared.eventManager.isNetworkReachable = true
                        FeedbackController.shared.eventManager.configure()
                        self.isSetupRunning = false
                    } else {
                        FBLogs("Add user - Failed")
                        self.isSetupRunning = false
                    }
                } catch {
                    FBLogs("Add user - Failed")
                    FBLogs(error)
                    self.isSetupRunning = false
                }
            } else {
                FBLogs("Add user - Failed")
                self.isSetupRunning = false
            }
        }
        
        self.fetchLocationDetails()
    }
    
    private func fetchLocationDetails() {
        FBLogs("Fetching geo location")
        FBAPIController().getLocationDetailsUsingIP { isSuccess, error, data in
            if isSuccess == true, let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                        FBLogs("Geo Location - Success")
                        ProjectDetailsController.shared.locationDetails = json
                    } else {
                        FBLogs("Geo Location - Failed")
                    }
                } catch {
                    FBLogs("Geo Location - Failed")
                    FBLogs(error)
                }
            }
        }
    }
    
    @objc func reachabilityChanged(note: Notification) {
        
        let reachability = note.object as! Reachability
        switch reachability.connection {
        case .unavailable:
            FBLogs("Network: Unreachable")
            ProjectDetailsController.shared.radioConnectivity = nil
            ProjectDetailsController.shared.isCarrierConnectivity = false
            
            if networkTimer != nil, networkTimer?.isValid == true {
                networkTimer?.invalidate()
                networkTimer = nil
            }
            networkTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(networkNotAvailable), userInfo: nil, repeats: false)
            break
        default:
            FBLogs("Network: Reachable")
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
    
    func setupReachability() {
        FBLogs("Network Objerver - Starting")
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
            try reachability.startNotifier()
            FBLogs("Network Objerver - Success")
        }catch{
            FBLogs("Network Objerver - Failed")
        }
    }
    
    
    @objc class public func recordEventName(_ eventName: String, parameters: [String: Any]?) {
        DispatchQueue.global().async {
            shared.eventManager.recordEvent(eventName, parameters: parameters)
        }        
    }
    
}
