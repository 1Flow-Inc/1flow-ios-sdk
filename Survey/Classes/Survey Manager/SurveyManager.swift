//
//  SurveyManager.swift
//  Feedback
//
//  Created by Rohan Moradiya on 12/07/21.
//
import UIKit

class SurveyManager: NSObject {

    let apiController = FBAPIController()
    var surveyList: SurveyListResponse?
    var surveyWindow: UIWindow?
    private var temporaryEventArray: [String]?
    var isNetworkReachable = false
    private var isSurveyFetching = false
    var pendingSurveySubmission: [String: SurveySubmitRequest]? {
        set {
            if let value = newValue, value.count > 0 {
                UserDefaults.standard.set(try? PropertyListEncoder().encode(value), forKey:"pendingSurveySubmission")
            } else {
                UserDefaults.standard.removeObject(forKey: "pendingSurveySubmission")
            }
        }
        
        get {
            if let data = UserDefaults.standard.value(forKey:"pendingSurveySubmission") as? Data {
                let pendingSurvey = try? PropertyListDecoder().decode([String: SurveySubmitRequest].self, from: data)
                return pendingSurvey
            }
            return nil
        }
        
    }
    var submittedSurveyIDs: [String]? {
        didSet {
            FBLogs("submittedSurveyIDs saved")
            UserDefaults.standard.setValue(submittedSurveyIDs, forKey: "FBSubmittedSurveyIDs")
        }
    }
    
    override init() {
        super.init()
        FBLogs("SurveyManager initialized")
        if let submittedSurvey = UserDefaults.standard.value(forKey: "FBSubmittedSurveyIDs") as? [String] {
            self.submittedSurveyIDs = submittedSurvey
        }
    }
    
    func configureSurveys() {
        FBLogs("configureSurveys")
        if self.surveyList == nil && self.isNetworkReachable == true {
            self.fetchAllSurvey()
        }
        if self.isNetworkReachable == true {
            self.uploadPendingSurveyIfAvailable()
        }
    }
    
    func networkStatusChanged(_ isReachable: Bool) {
        self.isNetworkReachable = isReachable
        self.configureSurveys()
    }
    
    private func uploadPendingSurveyIfAvailable() {
        if let pendigSurveys = self.pendingSurveySubmission, pendigSurveys.count > 0 {
            pendigSurveys.forEach { (key: String, value: SurveySubmitRequest) in
                self.submitTheSurveyToServer(key, surveyResponse: value)
            }
        }
    }
    private func fetchAllSurvey() {
        FBLogs("Fetch Survey called")
        
        struct Holder { static var called = false }
            if Holder.called {
                return
            } else {
                Holder.called = true
            }
        FBLogs("Fetch Survey calling API")
        apiController.getAllSurveys { [weak self] isSuccess, error, data in
            guard let self = self else {
                return
            }
            self.isSurveyFetching = false
            if isSuccess == true, let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                        FBLogs(json)
                    }
                    
                    let surveyListResponse = try JSONDecoder().decode(SurveyListResponse.self, from: data)
                    self.surveyList = surveyListResponse
                    self.checkAfterSurveyLoadForExistingEvents()
                } catch {
                    FBLogs(error)
                }
                
            } else {
                FBLogs(error?.localizedDescription ?? "NA")
            }
        }
    }
    
    private func checkAfterSurveyLoadForExistingEvents() {
        if let eventsArray = self.temporaryEventArray {
            for eventName in eventsArray {
                if let triggeredSurvey = surveyList?.result.first(where:  {$0.trigger_event_name == eventName }) {
                    self.temporaryEventArray = nil
                    if let submittedIDs = self.submittedSurveyIDs, submittedIDs.contains(triggeredSurvey._id) {
                        FBLogs("Survey already submitted. Do nothing.")
                    } else {
                        self.startSurvey(triggeredSurvey)
                    }
                    break
                }
            }
        }
    }
    
    func newEventRecorded(_ eventName: String) {
        if let surveyList = self.surveyList {
            if let triggeredSurvey = surveyList.result.first(where: { $0.trigger_event_name == eventName }) {
                
                if let submittedIDs = self.submittedSurveyIDs, submittedIDs.contains(triggeredSurvey._id) {
                    FBLogs("Survey already submitted. Do nothing.")
                } else if let pendingSurvey = self.pendingSurveySubmission?[triggeredSurvey._id] {
                    FBLogs("Survey response alrady captured. But not submitted. Resubmit the response")
                    self.submitTheSurveyToServer(triggeredSurvey._id, surveyResponse: pendingSurvey)
                } else {
                    self.startSurvey(triggeredSurvey)
                }
            }
        } else {
            if temporaryEventArray == nil {
                self.temporaryEventArray = [String]()
            }
            self.temporaryEventArray?.append(eventName)
        }
    }
    
    private func startSurvey(_ survey: SurveyListResponse.Survey) {
        
        FeedbackController.recordEventName(kEventNameSurveyImpression, parameters: ["survey_id": survey._id])
        
        DispatchQueue.main.async {
            if self.surveyWindow == nil {
                if #available(iOS 13.0, *) {
                    if let currentWindowScene = UIApplication.shared.connectedScenes.first as?  UIWindowScene {
                        self.surveyWindow = UIWindow(windowScene: currentWindowScene)
                    }
                } else {
                    // Fallback on earlier versions
                    self.surveyWindow = UIWindow(frame: UIScreen.main.bounds)
                }
            }
            
            self.surveyWindow!.isHidden = false
            self.surveyWindow!.windowLevel = .alert
            
            let frameworkBundle = Bundle(for: self.classForCoder)
            let controller = RatingViewController(nibName: "RatingViewController", bundle: frameworkBundle)
            controller.modalPresentationStyle = .overFullScreen
            controller.view.backgroundColor = UIColor.clear
            
            self.surveyWindow!.rootViewController = controller
            self.surveyWindow!.makeKeyAndVisible()
            controller.completionBlock = { [weak self] surveyResponse in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.surveyWindow?.isHidden = true
                    self.surveyWindow = nil
                }
                
                if surveyResponse.count > 0 {
                    
                    let surveyResponse = SurveySubmitRequest(analytic_user_id: ProjectDetailsController.shared.analytic_user_id, survey_id: survey._id, os: "iOS", answers: surveyResponse, session_id: ProjectDetailsController.shared.analytics_session_id)
                    
                    if self.pendingSurveySubmission == nil {
                        self.pendingSurveySubmission = [survey._id : surveyResponse]
                    } else {
                        self.pendingSurveySubmission![survey._id] = surveyResponse
                    }
                    self.uploadPendingSurveyIfAvailable()
                }
            }
            controller.startSurveysWithScreens(survey.screens)
        }
    }
    
    private func submitTheSurveyToServer(_ surveyID: String, surveyResponse:SurveySubmitRequest) {
        
        FBLogs("submitTheSurveyToServer called")
        
        if self.isNetworkReachable == false {
            FBLogs("Network not reachable. Returned")
            return
        }
        
        var surveyResponseTemp = surveyResponse
        
        if surveyResponseTemp.analytic_user_id == nil {
            FBLogs("Survey did not have user")
            guard let userID = ProjectDetailsController.shared.analytic_user_id else {
                FBLogs("user yet not initialised")
                return
            }
            surveyResponseTemp.analytic_user_id = userID
        }
        
        if surveyResponseTemp.session_id == nil {
            FBLogs("Survey did not have session id")
            guard let sessionID = ProjectDetailsController.shared.analytics_session_id else {
                FBLogs("Session yet not created")
                return
            }
            surveyResponseTemp.session_id = sessionID
        }
        FBLogs("Calling API to submit survey")
        apiController.submitSurveyResponse(surveyResponseTemp) { [weak self] isSuccess, error, data in
            
            guard let self = self else {
                return
            }
            if isSuccess == true, let data = data {
                if self.submittedSurveyIDs == nil {
                    self.submittedSurveyIDs = [surveyID]
                } else {
                    self.submittedSurveyIDs?.append(surveyID)
                }
                self.pendingSurveySubmission?.removeValue(forKey: surveyID)
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                        FBLogs(json)
                    }
                } catch {
                    FBLogs("Submit Survey json")
                    FBLogs(error)
                }
                
            } else {
                FBLogs("Submit Survey")
                FBLogs(error?.localizedDescription ?? "NA")
            }
        }
    }
}
