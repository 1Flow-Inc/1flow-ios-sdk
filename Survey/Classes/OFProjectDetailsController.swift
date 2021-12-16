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

final class OFProjectDetailsController: NSObject {
    static let shared = OFProjectDetailsController()
    
    var currentEnviromment: OneFlowEnvironment = .dev
    var appKey: String! {
        didSet {
            if let oldAppKey = UserDefaults.standard.value(forKey: "OldAppKey") as? String {
                if oldAppKey != appKey {
                    self.resetUserData()
                }
            }
        }
    }

    var isSuveryEnabled: Bool = true

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
    
    var currentLoggedUserID: String? {
        get {
            return UserDefaults.standard.value(forKey: "FBCurrentLoggedUser") as? String
        }

        set {
            if let value = newValue {
                UserDefaults.standard.setValue(value, forKey: "FBCurrentLoggedUser")
            } else {
                UserDefaults.standard.removeObject(forKey: "FBCurrentLoggedUser")
            }
        }
    }
    
    var radioConnectivity: String?
    var isCarrierConnectivity: Bool = false
    
    var newUserID: String?
    var newUserData: [String: Any]?
    
    private func resetUserData() {
        UserDefaults.standard.removeObject(forKey: "analytic_user_id")
        UserDefaults.standard.removeObject(forKey: "uniqIDString")
    }
    
    private override init() {
        super.init()
    }
    
    func logNewUserDetails(_ completion: @escaping (Bool) -> Void) {
        guard let analyticsID = self.analytic_user_id, let sessionID = self.analytics_session_id, let newUserID = self.newUserID else {
            completion(false)
            return
        }
        var finalParameter = [String: Any]()
        finalParameter["anonymous_user_id"] = analyticsID
        finalParameter["session_id"] = sessionID
        finalParameter["system_id"] = newUserID
        finalParameter["mode"] = currentEnviromment.rawValue
        if let details = self.newUserData {
            finalParameter["parameters"] =  details
        }
        OneFlowLog("Calling loguser")
        OFAPIController().logUser(finalParameter) { isSuccess, error, data in
            if isSuccess == true, let data = data {
                do {
                    let loggedUser = try JSONDecoder().decode(LogUserResponse.self, from: data)
                    if loggedUser.success == 200, let user_id = loggedUser.result?.analytic_user_id, let session_id = loggedUser.result?.session_id {
                        self.currentLoggedUserID = newUserID
                        self.analytic_user_id = user_id
                        self.analytics_session_id = session_id
                        self.newUserID = nil
                        self.newUserData = nil
                        completion(true)
                    } else {
                        completion(false)
                    }
                } catch {
                    OneFlowLog("LogUser error: \(error)")
                    completion(false)
                }
            } else {
                OneFlowLog("LogUser Failed: Error: \(error as Any)")
                completion(false)
            }
        }
    }
}
