//
//  ProjectDetailsController.swift
//  Feedback
//
//  Created by Rohan Moradiya on 12/07/21.
//

import Foundation
import UIKit

class ProjectDetailsController: NSObject {
    static let shared = ProjectDetailsController()
    
    var appKey: String! {
        didSet {
            if let oldAppKey = UserDefaults.standard.value(forKey: "OldAppKey") as? String {
                if oldAppKey != appKey {
                    self.resetUserData()
                }
            }
        }
    }
    
    var deviceID: String! {
        get {
            return UIDevice.current.identifierForVendor?.uuidString
        }
    }
    
    var uniqID: String! {
        get {
            if let str = UserDefaults.standard.value(forKey: "uniqIDString") as? String {
                return str
            } else {
                let str = UUID().uuidString
                UserDefaults.standard.set(str, forKey: "uniqIDString")
                return str
            }
        }
    }
    
    var analytic_user_id: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: "analytic_user_id")
        }
        get {
            return UserDefaults.standard.value(forKey: "analytic_user_id") as? String
        }
    }
    
    var analytics_session_id: String?
    
    private func resetUserData() {
        UserDefaults.standard.removeObject(forKey: "analytic_user_id")
        UserDefaults.standard.removeObject(forKey: "uniqIDString")
    }
    
    private override init() {
        super.init()
    }
}
