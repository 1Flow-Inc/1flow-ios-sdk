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

import UIKit
import CoreTelephony

protocol EventManagerProtocol {
    func recordEvent(_ name: String, parameters: [String: Any]?)
    func configure()
    func setupSurveyManager()
    var isNetworkReachable: Bool { get set }
    func networkStatusChanged(_ isReachable: Bool)
    func finishPendingEvents()
    var surveyManager: SurveyManageable! { get set }
    var projectDetailsController: ProjectDetailsManageable! { get set }
}

class OFEventManager: NSObject, EventManagerProtocol {
    
    var surveyManager: SurveyManageable!
    private let inAppController = OFInAppPurchaseEventsController()
    private var eventsArray = [[String: Any]]()
    var uploadTimer: Timer?
    var eventSaveTimer: Timer?
    let eventModificationQueue = DispatchQueue(label: "1flow-thread-safe-queue", attributes: .concurrent)
    var isNetworkReachable = false
    var projectDetailsController: ProjectDetailsManageable! = OFProjectDetailsController.shared

    override init() {
        super.init()
        OneFlowLog.writeLog("Event manager init")
    }
    
    func configure() {
        OneFlowLog.writeLog("Event Manager configure")
        self.createAnalyticsSession()
    }
    
    func finishPendingEvents() {
        if projectDetailsController.analytic_user_id != nil, projectDetailsController.analytics_session_id != nil {
            sendEventsToServer()
            if let surveyManagerObj = self.surveyManager {
                surveyManagerObj.uploadPendingSurveyIfAvailable()
            }
        }
    }
    
    @objc func applicationBecomeActive() {
        if projectDetailsController.analytics_session_id != nil && self.isNetworkReachable == true {
            self.startUploadTimer()
        }
    }
    
    @objc func applicationMovedToBackground() {
        if projectDetailsController.analytics_session_id != nil, self.isNetworkReachable == true {
            self.sendEventsToServer()
        }
        self.uploadTimer?.invalidate()
        self.uploadTimer = nil
    }
    
    func networkStatusChanged(_ isReachable: Bool) {
        self.isNetworkReachable = isReachable
        if let surveyManagerObj = self.surveyManager {
            surveyManagerObj.networkStatusChanged(isReachable)
        }
        if isReachable == true {
            if projectDetailsController.analytics_session_id != nil {
                self.startUploadTimer()
            }
        } else {
            self.uploadTimer?.invalidate()
            self.uploadTimer = nil
        }
    }
    
    private func createAnalyticsSession() {
        if projectDetailsController.analytics_session_id == nil {
            let networkInfo = CTTelephonyNetworkInfo()
            let carrier = networkInfo.subscriberCellularProvider
            let carrierName = carrier?.carrierName
            let osVersion = UIDevice.current.systemVersion
            let width = Int(UIScreen.main.bounds.size.width)
            let height = Int(UIScreen.main.bounds.size.height)
            var libraryVersion: String?
            
            if let bundle = Bundle.allFrameworks.first(where: { $0.bundleIdentifier?.contains("1Flow") ?? false } ) {
                libraryVersion = bundle.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String
            }
            
            let deviceDetails = CreateSessionRequest.DeviceDetails(os: "iOS", unique_id: projectDetailsController.uniqID, device_id: projectDetailsController.deviceID, carrier: carrierName, manufacturer: "apple", model: self.machineName(), os_ver: osVersion, screen_width: width, screen_height: height)
            let connectivity = CreateSessionRequest.Connectivity(carrier: (OFProjectDetailsController.shared.isCarrierConnectivity == true) ? carrierName : nil, radio: OFProjectDetailsController.shared.radioConnectivity)
            
            let sessionRequest: CreateSessionRequest = CreateSessionRequest(analytic_user_id: projectDetailsController.analytic_user_id ?? "", system_id: projectDetailsController.systemID, device: deviceDetails, connectivity: connectivity, app_version: self.getAppVersion(), app_build_number: self.getAppBuildNumber(), library_version: libraryVersion)
            OneFlowLog.writeLog("OFEventManager - Create Session")
            OFAPIController().createSession(sessionRequest) { [weak self] isSuccess, error, data in
                guard let self = self else {
                    return
                }
                if isSuccess == true, let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                            OneFlowLog.writeLog("OFEventManager - Create Session - Success")
                            if let result = json["result"] as? [String: Any], let _id = result["_id"] as? String {
                                self.projectDetailsController.analytics_session_id = _id
                                if let logUserInfo : [String : Any] =  UserDefaults.standard.object(forKey: "OFlogUserInfo") as? [String : Any] {
                                    if let userID : String = logUserInfo["UserID"] as? String, let userDetails : [String : Any] =  logUserInfo["userDetails"] as? [String : Any] {
                                        self.projectDetailsController.newUserID = userID
                                        self.projectDetailsController.newUserData = userDetails
                                    }
                                }
                                self.projectDetailsController.logUserRetryCount = 0
                                self.projectDetailsController.logNewUserDetails { isLogUserSuccess in
                                    if isSuccess == true {
                                        if isLogUserSuccess {
                                            UserDefaults.standard.removeObject(forKey: "OFlogUserInfo")
                                        }
                                        self.setupSurveyManager()
                                    }
                                }
                                self.startEventManager()
                            } else {
                                OneFlowLog.writeLog("OFEventManager - Create Session - Failed", .error)
                            }
                        }
                    } catch {
                        OneFlowLog.writeLog("OFEventManager - Create Session - Failed: \(error)", .error)
                    }
                }
            }
        } else {
            self.startEventManager()
        }
    }
    
    func setupSurveyManager() {
        if self.surveyManager == nil {
            self.surveyManager = OFSurveyManager()
        } else {
            self.surveyManager.cleanUpSurveyArray()
        }
        self.surveyManager.isNetworkReachable = true
        self.surveyManager.configureSurveys()
    }
    
    private func startEventManager() {
        if let eventsArray = UserDefaults.standard.value(forKey: "FBPendingEventsList") as? [[String: Any]] {
            eventModificationQueue.sync {
                self.eventsArray = eventsArray
            }
            
            UserDefaults.standard.removeObject(forKey: "FBPendingEventsList")
            self.sendEventsToServer()
        }
        self.recordEvent(kEventNameSessionStart, parameters: nil)
        self.startUploadTimer()
        self.setupDefaultEventsObservers()
    }
    
    private func setupDefaultEventsObservers() {
        
        DispatchQueue.main.async { [self] in
            NotificationCenter.default.addObserver(self, selector: #selector(applicationMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(applicationBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        }
        
        let appVersion = self.getAppVersion()
        
        //App Launch first time
        let temp = UserDefaults.standard.bool(forKey: "FBIsAppOpened")
        if temp == false {
            self.recordEvent(kEventNameFirstAppOpen, parameters: ["app_version" : appVersion])
            UserDefaults.standard.set(true, forKey: "FBIsAppOpened")
        }
        
        //App updated
        if let previousVersion = UserDefaults.standard.value(forKey: "FBPreviousAppVersion") as? String {
            if previousVersion != appVersion {
                self.recordEvent(kEventNameAppUpdate, parameters: ["app_version_current" : appVersion, "app_version_previous": previousVersion])
                UserDefaults.standard.set(appVersion, forKey: "FBPreviousAppVersion")
            }
        }
        
        //In App Purchase
        self.inAppController.delegate = self
        self.inAppController.startObserver()
        
        //Screen Tracking
//        self.screenTrackingController.startTacking()
        
    }
    
    private func startUploadTimer() {
        OneFlowLog.writeLog("OFEventManager: Timer start")
        DispatchQueue.main.async { [self] in
            if self.uploadTimer != nil, self.uploadTimer?.isValid == true {
                self.uploadTimer?.invalidate()
                self.uploadTimer = nil
            }
            self.uploadTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(sendEventsToServer), userInfo: nil, repeats: true)
        }
    }
    
    func recordEvent(_ name: String, parameters: [String: Any]?) {
        OneFlowLog.writeLog("OFEventManager: Record Event- name:\(name), parameters: \(parameters as Any)")
        
        /// barrier is used to handle bulk events e.g. log events with loops
        eventModificationQueue.async(flags: .barrier) {
            if let parameters = parameters {
                let newEventDic = ["name": name, "time": Int(Date().timeIntervalSince1970), "parameters": parameters as Any, "plt": "i"] as [String : Any]
                self.eventsArray.append(newEventDic)
            } else {
                let newEventDic = ["name": name, "time": Int(Date().timeIntervalSince1970), "plt": "i"] as [String : Any]
                self.eventsArray.append(newEventDic)
            }
            
            /// event SaveTimer is used to handle multiple simulteneuos calls of this methods
            DispatchQueue.main.async { [self] in
                if let timer = eventSaveTimer, timer.isValid {
                    timer.invalidate()
                }
                self.eventSaveTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(saveEventArray), userInfo: nil, repeats: false)
            }
        }
        
        if name == kEventNameSurveyImpression {
            self.sendEventsToServer()
        } else {
            /// if Survey is enabled, then pass this event to survey manager to check if survey available or not
            if OFProjectDetailsController.shared.isSuveryEnabled == true {
                if let surveyManagerObj = self.surveyManager {
                    surveyManagerObj.newEventRecorded(name)
                } else {
                    self.surveyManager = OFSurveyManager()
                    self.surveyManager.newEventRecorded(name)
                }
            }
        }
    }
    
    @objc func saveEventArray() {
        OneFlowLog.writeLog("OFEventManager: Save Events")
        UserDefaults.standard.setValue(self.eventsArray, forKey: "FBPendingEventsList")
    }
    
    @objc func sendEventsToServer() {
        OneFlowLog.writeLog("OFEventManager: sendEventsToServer")
        guard let sessionID = projectDetailsController.analytics_session_id else {
            OneFlowLog.writeLog("OFEventManager: Session is not created", .info)
            return
        }
        var eventsCount = 0
        eventModificationQueue.sync {
            eventsCount = self.eventsArray.count
        }
        if eventsCount > 0 {
            OneFlowLog.writeLog("OFEventManager: Sending events to server: \(self.eventsArray.count)")
            let uploadedEvents = eventsCount
            let finalParameters = ["events": self.eventsArray, "session_id": sessionID, "mode": projectDetailsController.currentEnviromment.rawValue] as [String : Any]
            
            OFAPIController().addEvents(finalParameters) { [weak self] isSuccess, error, data in
                if isSuccess == true, let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                            OneFlowLog.writeLog("OFEventManager: sendEventsToServer - Success")
                            OneFlowLog.writeLog("OFEventManager: Response: \(json)")
                            if let status = json["success"] as? Int, status == 200 {
                                guard let self = self else { return }
                                self.eventModificationQueue.sync {
                                    let totalCount = self.eventsArray.count
                                    if (totalCount - uploadedEvents) > 0 {
                                        self.eventsArray = self.eventsArray.suffix(totalCount - uploadedEvents)
                                    } else { //if (totalCount - uploadedEvents) == 0 {
                                        self.eventsArray.removeAll()
                                    }
                                    self.saveEventArray()
                                }
                            }
                        } else {
                            OneFlowLog.writeLog("OFEventManager: sendEventsToServer - Failed", .error)
                        }
                    } catch {
                        OneFlowLog.writeLog("OFEventManager: sendEventsToServer - Failed: \(error)", .error)
                    }
                }
            }
        } else {
            OneFlowLog.writeLog("EventManger: No Events to send")
        }
    }
    
    private func getAppVersion() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        return appVersion
    }
    
    private func getAppBuildNumber() -> String {
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
        return buildNumber
    }
    
    private func machineName() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        return modelCode
    }
}

extension OFEventManager: OFInAppPurchaseEventsDelegate {
    func newIAPEventRecorded(_ event: OFIAPEvent) {
        do {
            let temp = try JSONSerialization.jsonObject(with: JSONEncoder().encode(event)) as? [String: Any]
            self.recordEvent(kEventNameInAppPurchase, parameters: temp)
        } catch {
            OneFlowLog.writeLog("\(#function): \(error)", .error)
        }
        
    }
}
