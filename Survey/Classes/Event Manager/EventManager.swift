//
//  EventManager.swift
//  Feedback
//
//  Created by Rohan Moradiya on 12/07/21.
//

import UIKit
import CoreTelephony

final class EventManager: NSObject {

    let surveyManager = SurveyManager()
    private let inAppController = InAppPurchaseEventsController()
    private var eventsArray = [[String: Any]]()
    var uploadTimer: Timer?
    var eventSaveTimer: Timer?
    let eventModificationQueue = DispatchQueue(label: "1flow-thread-safe-queue", attributes: .concurrent)
    var isNetworkReachable = false
    override init() {
        super.init()
        OneFlowLog("Event manager init")
    }
    
    func configure() {
        OneFlowLog("Event Manager configure")
        self.createAnalyticsSession()
        self.surveyManager.isNetworkReachable = true
        self.surveyManager.configureSurveys()
    }
    
    func finishPendingEvents() {
        if ProjectDetailsController.shared.analytic_user_id != nil, ProjectDetailsController.shared.analytics_session_id != nil {
            sendEventsToServer()
            surveyManager.uploadPendingSurveyIfAvailable()
        }
    }
    
    @objc func applicationBecomeActive() {
        if ProjectDetailsController.shared.analytics_session_id != nil && self.isNetworkReachable == true {
            self.startUploadTimer()
        }
    }
    
    @objc func applicationMovedToBackground() {
        if ProjectDetailsController.shared.analytics_session_id != nil, self.isNetworkReachable == true {
            self.sendEventsToServer()
        }
        self.uploadTimer?.invalidate()
        self.uploadTimer = nil
    }
    
    func networkStatusChanged(_ isReachable: Bool) {
        self.isNetworkReachable = isReachable
        self.surveyManager.networkStatusChanged(isReachable)
        if isReachable == true {
            if ProjectDetailsController.shared.analytics_session_id != nil {
                self.startUploadTimer()
            }
        } else {
            self.uploadTimer?.invalidate()
            self.uploadTimer = nil
        }
    }
    
    private func createAnalyticsSession() {
        if ProjectDetailsController.shared.analytics_session_id == nil {
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
            
            let deviceDetails = CreateSessionRequest.DeviceDetails(os: "iOS", unique_id: ProjectDetailsController.shared.uniqID, device_id: ProjectDetailsController.shared.deviceID, carrier: carrierName, manufacturer: "apple", model: self.machineName(), os_ver: osVersion, screen_width: width, screen_height: height)
            let connectivity = CreateSessionRequest.Connectivity(carrier: (ProjectDetailsController.shared.isCarrierConnectivity == true) ? carrierName : nil, radio: ProjectDetailsController.shared.radioConnectivity)
            
            let sessionRequest: CreateSessionRequest = CreateSessionRequest(analytic_user_id: ProjectDetailsController.shared.analytic_user_id ?? "", system_id: ProjectDetailsController.shared.systemID, device: deviceDetails, location: nil, connectivity: connectivity, location_check: true, app_version: self.getAppVersion(), app_build_number: self.getAppBuildNumber(), library_version: libraryVersion)
            OneFlowLog("EventManager - Create Session")
            FBAPIController().createSession(sessionRequest) { [weak self] isSuccess, error, data in
                if isSuccess == true, let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                            OneFlowLog("EventManager - Create Session - Success")
                            if let result = json["result"] as? [String: Any], let _id = result["_id"] as? String {
                                ProjectDetailsController.shared.analytics_session_id = _id
                                ProjectDetailsController.shared.logNewUserDetails { _ in
                                    
                                }
                                guard let self = self else { return }
                                self.startEventManager()
                            } else {
                                OneFlowLog("EventManager - Create Session - Failed")
                            }
                        }
                    } catch {
                        OneFlowLog("EventManager - Create Session - Failed")
                        OneFlowLog(error)
                    }
                }
            }
        } else {
            self.startEventManager()
        }
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
    }
    
    private func startUploadTimer() {
        OneFlowLog("EventManager: Timer start")
        DispatchQueue.main.async { [self] in
            if self.uploadTimer != nil, self.uploadTimer?.isValid == true {
                self.uploadTimer?.invalidate()
                self.uploadTimer = nil
            }
            self.uploadTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(sendEventsToServer), userInfo: nil, repeats: true)
        }
    }
    
    func recordEvent(_ name: String, parameters: [String: Any]?) {
        OneFlowLog("EventManager: Record Event- name:\(name), parameters: \(parameters as Any)")
        
        /// barrier is used to handle bulk events e.g. log events with loops
        eventModificationQueue.async(flags: .barrier) {
            if let parameters = parameters {
                let newEventDic = ["name": name, "time": Int(Date().timeIntervalSince1970), "parameters": parameters as Any] as [String : Any]
                self.eventsArray.append(newEventDic)
            } else {
                let newEventDic = ["name": name, "time": Int(Date().timeIntervalSince1970)] as [String : Any]
                self.eventsArray.append(newEventDic)
            }
            
            /// event SaveTimer is used to handle multiple simulteneuos calls of this methods
            DispatchQueue.main.async { [self] in
                if let timer = eventSaveTimer, timer.isValid {
                    timer.invalidate()
                }
                self.eventSaveTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(saveEventArray), userInfo: nil, repeats: false)
            }
            
            /// if Survey is enabled, then pass this event to survey manager to check if survey available or not
            if ProjectDetailsController.shared.isSuveryEnabled == true {
                self.surveyManager.newEventRecorded(name)
            }
        }
    }
    
    @objc func saveEventArray() {
        OneFlowLog("EventManager: Save Events")
        UserDefaults.standard.setValue(self.eventsArray, forKey: "FBPendingEventsList")
    }
    
    @objc func sendEventsToServer() {
        OneFlowLog("EventManager: sendEventsToServer")
        var eventsCount = 0
        eventModificationQueue.sync {
            eventsCount = self.eventsArray.count
        }
        if eventsCount > 0 {
            OneFlowLog("EventManager: Sending events to server: \(self.eventsArray.count)")
            let uploadedEvents = eventsCount
            let finalParameters = ["events": self.eventsArray, "session_id": ProjectDetailsController.shared.analytics_session_id as Any, "mode": ProjectDetailsController.shared.currentEnviromment.rawValue] as [String : Any]
            
            FBAPIController().addEvents(finalParameters) { [weak self] isSuccess, error, data in
                if isSuccess == true, let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                            OneFlowLog("EventManager: sendEventsToServer - Success")
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
                            OneFlowLog("EventManager: sendEventsToServer - Failed")
                        }
                    } catch {
                        OneFlowLog("EventManager: sendEventsToServer - Failed")
                        OneFlowLog(error)
                    }
                }
            }
        } else {
            OneFlowLog("EventManger: No Events to send")
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

extension EventManager: InAppPurchaseEventsDelegate {
    func newIAPEventRecorded(_ event: IAPEvent) {
        do {
            let temp = try JSONSerialization.jsonObject(with: JSONEncoder().encode(event)) as? [String: Any]
            self.recordEvent(kEventNameInAppPurchase, parameters: temp)
        } catch {
            OneFlowLog(error)
        }
        
    }
}
