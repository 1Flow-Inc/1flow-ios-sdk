//
//  ProjectDetailsController.swift
//  Feedback
//
//  Created by Rohan Moradiya on 12/07/21.
//

import Foundation
import UIKit

enum OneFlowEnvironment: String {
    case dev
    case prod
    
    var rawValue: String {
        get {
            switch self {
            case .dev:
                return "dev"
            case .prod:
                return "prod"
            }
        }
    }
}

final class ProjectDetailsController: NSObject {
    static let shared = ProjectDetailsController()
    
    var currentEnviromment: OneFlowEnvironment = .prod
    
    var isSuveryEnabled: Bool = true
    
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
    
    var systemID: String! {
        get {
            if let str = UserDefaults.standard.value(forKey: "systemID") as? String {
                return str
            } else {
                let str = UUID().uuidString
                UserDefaults.standard.set(str, forKey: "systemID")
                return str
            }
        }
    }
    
    var analytic_user_id: String?
    var analytics_session_id: String?
    var locationDetails: [String: Any]?
    
    private func resetUserData() {
        UserDefaults.standard.removeObject(forKey: "analytic_user_id")
        UserDefaults.standard.removeObject(forKey: "uniqIDString")
    }
    
    private override init() {
        super.init()
    }
    var radioConnectivity: String?
    var isCarrierConnectivity: Bool = false
    
    var newUserID: String?
    var newUserData: [String: Any]?
    
    func logNewUserDetails() {
        
        guard let analyticsID = self.analytic_user_id, let sessionID = self.analytics_session_id, let newUserID = self.newUserID else { return }
        
        var finalParameter = [String: Any]()
        finalParameter["anonymous_user_id"] = analyticsID
        finalParameter["session_id"] = sessionID
        finalParameter["system_id"] = newUserID
        if let details = self.newUserData {
            finalParameter["parameters"] =  details
        }
        
        self.newUserID = nil
        self.newUserData = nil
        OneFlowLog("Calling log user")
        FBAPIController().logUser(finalParameter) { isSuccess, error, data in
            if isSuccess == true, let data = data {
                do {
                    let loggedUser = try JSONDecoder().decode(LogUserResponse.self, from: data)
                    if loggedUser.success == 200, let user_id = loggedUser.result?.analytic_user_id, let session_id = loggedUser.result?.session_id {
                        self.analytic_user_id = user_id
                        self.analytics_session_id = session_id
                    }
                } catch {
                    OneFlowLog("LogUser error: \(error)")
                }
                
            } else {
                OneFlowLog("LogUser Failed: Error: \(error as Any)")
            }
        }
    }
    
}
