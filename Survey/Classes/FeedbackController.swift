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
        FBLogs("Configured called")
        ProjectDetailsController.shared.appKey = appKey
        shared.setupOnce()
        shared.setupReachability()
    }
    
    private func setupOnce() {
        self.isSetupRunning = true
        
        let addUserRequest = AddUserRequest(system_id: ProjectDetailsController.shared.uniqID, device: AddUserRequest.DeviceDetails(os: "iOS", unique_id: ProjectDetailsController.shared.uniqID, device_id: ProjectDetailsController.shared.deviceID), location: nil)
        
        FBLogs("Add User Called")
        FBAPIController().addUser(addUserRequest) { isSuccess, error, data in
            FBLogs("Add user finished")
            if isSuccess == true, let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any], let result = json["result"] as? [String: Any], let userID = result["analytic_user_id"] as? String {
                        FBLogs(json)
                        ProjectDetailsController.shared.analytic_user_id = userID
//                        if FeedbackController.shared.eventManager == nil {
//                            FeedbackController.shared.eventManager = EventManager()
//                        }
                        FeedbackController.shared.eventManager.isNetworkReachable = true
                        FeedbackController.shared.eventManager.configure()
                        self.isSetupRunning = false
                    } else {
                        self.isSetupRunning = false
                    }
                } catch {
                    FBLogs("User Registration")
                    FBLogs(error)
                    self.isSetupRunning = false
                }
            } else {
                self.isSetupRunning = false
            }
        }
        
        self.fetchLocationDetails()
    }
    
    private func fetchLocationDetails() {
        
        FBAPIController().getLocationDetailsUsingIP { isSuccess, error, data in
            if isSuccess == true, let data = data {
                FBLogs("Location fetched")
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                        FBLogs("Location data:")
                        FBLogs(json)
                        ProjectDetailsController.shared.locationDetails = json
                    }
                } catch {
                    FBLogs("Location fetch API")
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
        if networkTimer != nil, networkTimer?.isValid == true {
            networkTimer?.invalidate()
            networkTimer = nil
        }
        networkTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(networkNotAvailable), userInfo: nil, repeats: false)
        break
      default:
        FBLogs("Reachable")
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
        FBLogs("Reachablity started")
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
            try reachability.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
    }
    
    
    @objc class public func recordEventName(_ eventName: String, parameters: [String: Any]?) {
        DispatchQueue.global().async {
            shared.eventManager.recordEvent(eventName, parameters: parameters)
        }        
    }
    
}
