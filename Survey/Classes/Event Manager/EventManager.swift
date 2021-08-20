//
//  EventManager.swift
//  Feedback
//
//  Created by Rohan Moradiya on 12/07/21.
//

import UIKit

class EventManager: NSObject {

    let surveyManager = SurveyManager()
    private let inAppController = InAppPurchaseEventsController()
    private var eventsArray = [[String: Any]]()
    var uploadTimer: Timer?
//    let screenTrackingController = ScreenTrackingController()
    var isNetworkReachable = false
    override init() {
        super.init()
        FBLogs("Event manager initialized")
    }
    
    func configure() {
        FBLogs("Event Manager configure called")
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
            
            if let json = ProjectDetailsController.shared.locationDetails {
                sessionRequest = CreateSessionRequest(analytic_user_id: ProjectDetailsController.shared.analytic_user_id ?? "", system_id: ProjectDetailsController.shared.uniqID, device: CreateSessionRequest.DeviceDetails(os: "iOS", unique_id: ProjectDetailsController.shared.uniqID, device_id: ProjectDetailsController.shared.deviceID), location: CreateSessionRequest.LocationDetails(city: json["city"] as? String ?? "", region: json["regionName"] as? String ?? "", country: json["country"] as? String ?? "", latitude: json["lat"] as? Double ?? 0.0, longitude: json["lon"] as? Double ?? 0.0), location_check: false)
            } else {
                sessionRequest = CreateSessionRequest(analytic_user_id: ProjectDetailsController.shared.analytic_user_id ?? "", system_id: ProjectDetailsController.shared.uniqID, device: CreateSessionRequest.DeviceDetails(os: "iOS", unique_id: ProjectDetailsController.shared.uniqID, device_id: ProjectDetailsController.shared.deviceID), location: nil, location_check: true)
            }
            
            FBAPIController().createSession(sessionRequest!) { [weak self] isSuccess, error, data in
                if isSuccess == true, let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                            FBLogs(json)
                            if let result = json["result"] as? [String: Any], let _id = result["_id"] as? String {
                                ProjectDetailsController.shared.analytics_session_id = _id
                                guard let self = self else { return }
                                self.startEventManager()
                            }
                        }
                    } catch {
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
        FBLogs("Timer start")
        DispatchQueue.main.async { [self] in
            if self.uploadTimer != nil, self.uploadTimer?.isValid == true {
                self.uploadTimer?.invalidate()
                self.uploadTimer = nil
            }
            self.uploadTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(sendEventsToServer), userInfo: nil, repeats: true)
        }
    }
    
    func recordEvent(_ name: String, parameters: [String: Any]?) {
        FBLogs("Record Event- name:\(name), parameters: \(parameters as Any)")
        if let parameters = parameters {
            let newEventDic = ["name": name, "time": Int(Date().timeIntervalSince1970), "parameters": parameters as Any] as [String : Any]
            self.eventsArray.append(newEventDic)
        } else {
            let newEventDic = ["name": name, "time": Int(Date().timeIntervalSince1970)] as [String : Any]
            self.eventsArray.append(newEventDic)
        }
        
        UserDefaults.standard.setValue(self.eventsArray, forKey: "FBPendingEventsList")
        self.surveyManager.newEventRecorded(name)
    }
    
    
    @objc func sendEventsToServer() {
        FBLogs("sendEventsToServer called")
        if self.eventsArray.count > 0 {
            FBLogs("Sending events to server: \(self.eventsArray)")
            let uploadedEvents = self.eventsArray.count
            let finalParameters = ["events": self.eventsArray, "session_id": ProjectDetailsController.shared.analytic_user_id as Any] as [String : Any]
            
            FBAPIController().addEvents(finalParameters) { [weak self] isSuccess, error, data in
                if isSuccess == true, let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                            FBLogs("Event send API done")
                            FBLogs(json)
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
                        }
                    } catch {
                        FBLogs("sendEventsToServer")
                        FBLogs(error)
                    }
                }
            }
            
        }
    }
    
    func getAppVersion() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        return appVersion
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
