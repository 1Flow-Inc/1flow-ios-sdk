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
    var eventManager: EventManager?
    
    @objc public class func configure(_ appKey: String) {
        FBLogs("Configured called")
        
        ProjectDetailsController.shared.appKey = appKey
//        if ProjectDetailsController.shared.analytic_user_id != nil {
//            shared.eventManager.configure()
//        } else {
            FBAPIController().getLocationDetailsUsingIP { isSuccess, error, data in
                FBLogs("Location fetched")
                if isSuccess == true, let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                            FBLogs("Location data:")
                            FBLogs(json)
                            let addUserRequest = AddUserRequest(system_id: ProjectDetailsController.shared.uniqID, device: AddUserRequest.DeviceDetails(os: "iOS", unique_id: ProjectDetailsController.shared.uniqID, device_id: ProjectDetailsController.shared.deviceID), location: AddUserRequest.LocationDetails(city: json["city"] as? String ?? "", region: json["regionName"] as? String ?? "", country: json["country"] as? String ?? "", latitude: json["lat"] as? Double ?? 0.0, longitude: json["lon"] as? Double ?? 0.0))
                            
                            FBLogs("Add User Called")
                            FBAPIController().addUser(addUserRequest) { isSuccess, error, data in
                                FBLogs("Add user finished")
                                if isSuccess == true, let data = data {
                                    do {
                                        if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                                            FBLogs("Add User response:")
                                            FBLogs(json)
                                            if let result = json["result"] as? [String: Any], let userID = result["analytic_user_id"] as? String {
                                                ProjectDetailsController.shared.analytic_user_id = userID
                                                if shared.eventManager == nil {
                                                    shared.eventManager = EventManager()
                                                }
                                                shared.eventManager!.configure()
                                            }
                                        }
                                    } catch {
                                        FBLogs(error)
                                    }
                                }
                            }
                        }
                    } catch {
                        FBLogs(error)
                    }
                }
            }
//        }
    }
    
    private override init() {
        
    }
    
    @objc class public func recordEventName(_ eventName: String, parameters: [String: Any]?) {
        DispatchQueue.global().async {
            if shared.eventManager == nil {
                shared.eventManager = EventManager()
            }
            shared.eventManager!.recordEvent(eventName, parameters: parameters)
        }        
    }
}
