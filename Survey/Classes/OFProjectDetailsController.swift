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

protocol ProjectDetailsProtocol {
    var currentEnviromment: OneFlowEnvironment { get set }
    var currentLogLevel: OneFlowLogLevel { get set }
    var appKey: String! { get set }
    var isSuveryEnabled: Bool { get set }
    var deviceID: String! { get }
    var uniqID: String! { get }
    var systemID: String! { get set }
    var analytic_user_id: String? { get set }
    var analytics_session_id: String? { get set }
    var currentLoggedUserID: String? { get set }
    var radioConnectivity: String? { get set }
    var isCarrierConnectivity: Bool { get set }
    var newUserID: String? { get set }
    var newUserData: [String: Any]? { get set }
    
    func setLoglevel(_ newLogLevel : OneFlowLogLevel)
    func logNewUserDetails(_ completion: @escaping (Bool) -> Void)
    func getLocalisedLanguageName() -> String
}

final class OFProjectDetailsController: NSObject, ProjectDetailsProtocol {

    static let shared = OFProjectDetailsController()
    
    var currentEnviromment: OneFlowEnvironment = .prod
    var currentLogLevel: OneFlowLogLevel = .none

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
        set {
            UserDefaults.standard.set(newValue, forKey: "systemID")
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
    
    func setLoglevel(_ newLogLevel : OneFlowLogLevel) {
        currentLogLevel = newLogLevel
    }
    
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
        OneFlowLog.writeLog("Calling loguser")
        OFAPIController().logUser(finalParameter) { isSuccess, error, data in
            if isSuccess == true, let data = data {
                do {
                    let loggedUser = try JSONDecoder().decode(LogUserResponse.self, from: data)
                    if loggedUser.success == 200, let user_id = loggedUser.result?.analytic_user_id, let session_id = loggedUser.result?.session_id {
                        self.currentLoggedUserID = newUserID
                        self.analytic_user_id = user_id
                        self.analytics_session_id = session_id
                        self.systemID = newUserID
                        self.newUserID = nil
                        self.newUserData = nil
                        completion(true)
                    } else {
                        completion(false)
                    }
                } catch {
                    OneFlowLog.writeLog("LogUser error: \(error)")
                    completion(false)
                }
            } else {
                OneFlowLog.writeLog("LogUser Failed: Error: \(error as Any)")
                completion(false)
            }
        }
    }
    
    func getLocalisedLanguageName() -> String {
        if let preferredLanguage = Locale.preferredLanguages.first {
            let usLocale = Locale(identifier: "en-US")
            if let languageString = usLocale.localizedString(forLanguageCode: preferredLanguage) {
                OneFlowLog.writeLog("preferredLanguage English Text = \(languageString)")
                return languageString
            }
        }
        OneFlowLog.writeLog("Default Language returned")
        return "English"
    }
}
