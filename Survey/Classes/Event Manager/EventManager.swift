//
//  EventManager.swift
//  Feedback
//
//  Created by Rohan Moradiya on 12/07/21.
//

import UIKit
import CoreTelephony

class EventManager: NSObject {

    let surveyManager = SurveyManager()
    private let inAppController = InAppPurchaseEventsController()
    private var eventsArray = [[String: Any]]()
    var uploadTimer: Timer?
//    let screenTrackingController = ScreenTrackingController()
    var eventSaveTimer: Timer?
    
    var isNetworkReachable = false
    override init() {
        super.init()
        FBLogs("Event manager init")
    }
    
    func configure() {
        FBLogs("Event Manager configure")
        self.createAnalyticsSession()
        self.surveyManager.isNetworkReachable = true
        self.surveyManager.configureSurveys()
    }
    
    @objc func applicationBecomeActive() {
        if ProjectDetailsController.shared.analytics_session_id != nil && self.isNetworkReachable == true {
            self.startUploadTimer()
        }
    }
    
    @objc func applicationMovedToBackground() {
        if ProjectDetailsController.shared.analytics_session_id != nil, self.isNetworkReachable == true {
            FBAPIController().uploadAllPendingEvents()
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
            var sessionRequest: CreateSessionRequest?
            
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
            
            if let json = ProjectDetailsController.shared.locationDetails {
                sessionRequest = CreateSessionRequest(analytic_user_id: ProjectDetailsController.shared.analytic_user_id ?? "", system_id: ProjectDetailsController.shared.uniqID, device: deviceDetails, location: CreateSessionRequest.LocationDetails(city: json["city"] as? String ?? "", region: json["regionName"] as? String ?? "", country: json["country"] as? String ?? "", latitude: json["lat"] as? Double ?? 0.0, longitude: json["lon"] as? Double ?? 0.0), connectivity: connectivity, location_check: false, app_version: self.getAppVersion(), app_build_number: self.getAppBuildNumber(), library_version: libraryVersion)
            } else {
                sessionRequest = CreateSessionRequest(analytic_user_id: ProjectDetailsController.shared.analytic_user_id ?? "", system_id: ProjectDetailsController.shared.uniqID, device: deviceDetails, location: nil, connectivity: connectivity, location_check: true, app_version: self.getAppVersion(), app_build_number: self.getAppBuildNumber(), library_version: libraryVersion)
            }
            FBLogs("EventManager - Create Session")
            FBAPIController().createSession(sessionRequest!) { [weak self] isSuccess, error, data in
                if isSuccess == true, let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                            FBLogs("EventManager - Create Session - Success")
                            if let result = json["result"] as? [String: Any], let _id = result["_id"] as? String {
                                ProjectDetailsController.shared.analytics_session_id = _id
                                guard let self = self else { return }
                                self.startEventManager()
                            } else {
                                FBLogs("EventManager - Create Session - Failed")
                            }
                        }
                    } catch {
                        FBLogs("EventManager - Create Session - Failed")
                        FBLogs(error)
                    }
                }
            }
        } else {
            self.startEventManager()
        }
    }
    
    private func startEventManager() {
        if let eventsArray = UserDefaults.standard.value(forKey: "FBPendingEventsList") as? [[String: Any]] {
            self.eventsArray = eventsArray
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
        FBLogs("EventManager: Timer start")
        DispatchQueue.main.async { [self] in
            if self.uploadTimer != nil, self.uploadTimer?.isValid == true {
                self.uploadTimer?.invalidate()
                self.uploadTimer = nil
            }
            self.uploadTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(sendEventsToServer), userInfo: nil, repeats: true)
        }
    }
    
    func recordEvent(_ name: String, parameters: [String: Any]?) {
        FBLogs("EventManager: Record Event- name:\(name), parameters: \(parameters as Any)")
        if let parameters = parameters {
            let newEventDic = ["name": name, "time": Int(Date().timeIntervalSince1970), "parameters": parameters as Any] as [String : Any]
            self.eventsArray.append(newEventDic)
        } else {
            let newEventDic = ["name": name, "time": Int(Date().timeIntervalSince1970)] as [String : Any]
            self.eventsArray.append(newEventDic)
        }
        
        DispatchQueue.main.async { [self] in
            if let timer = eventSaveTimer, timer.isValid {
                timer.invalidate()
            }
            self.eventSaveTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(saveEventArray), userInfo: nil, repeats: false)
        }
        
        self.surveyManager.newEventRecorded(name)
    }
    
    @objc func saveEventArray() {
        FBLogs("EventManager: Save Events")
        UserDefaults.standard.setValue(self.eventsArray, forKey: "FBPendingEventsList")
    }
    
    @objc func sendEventsToServer() {
        FBLogs("EventManager: sendEventsToServer")
        if self.eventsArray.count > 0 {
            FBLogs("EventManager: Sending events to server: \(self.eventsArray.count)")
            let uploadedEvents = self.eventsArray.count
            let finalParameters = ["events": self.eventsArray, "session_id": ProjectDetailsController.shared.analytic_user_id as Any] as [String : Any]
            
            FBAPIController().addEvents(finalParameters) { [weak self] isSuccess, error, data in
                if isSuccess == true, let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                            FBLogs("EventManager: sendEventsToServer - Success")
                            if let status = json["success"] as? Int, status == 200 {
                                guard let self = self else { return }
                                let totalCount = self.eventsArray.count
                                if (totalCount - uploadedEvents) > 0 {
                                    self.eventsArray = self.eventsArray.suffix(totalCount - uploadedEvents)
                                } else { //if (totalCount - uploadedEvents) == 0 {
                                    self.eventsArray.removeAll()
                                }
                                
                                UserDefaults.standard.setValue(self.eventsArray, forKey: "FBPendingEventsList")
                            }
                        } else {
                            FBLogs("EventManager: sendEventsToServer - Failed")
                        }
                    } catch {
                        FBLogs("EventManager: sendEventsToServer - Failed")
                        FBLogs(error)
                    }
                }
            }
        } else {
            FBLogs("EventManger: No Events to send")
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
            FBLogs(error)
        }
        
    }
}
