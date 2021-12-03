//
//  SurveyManager.swift
//  Feedback
//
//  Created by Rohan Moradiya on 12/07/21.
//
import UIKit

final class SurveyManager: NSObject {

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
    var submittedSurveyDetails: [SubmittedSurvey]?
    
    func saveSubmittedSurvey() {
        do {
            let data = try JSONEncoder().encode(submittedSurveyDetails)
            UserDefaults.standard.setValue(data, forKey: "FBSubmittedSurveys")
        } catch {
            OneFlowLog("[Error]: Unable to save submitted survey: \(error.localizedDescription)")
        }
    }
    
    override init() {
        super.init()
        OneFlowLog("SurveyManager: Started")
        if let data = UserDefaults.standard.value(forKey: "FBSubmittedSurveys") as? Data {
            do {
                submittedSurveyDetails = try JSONDecoder().decode([SubmittedSurvey].self, from: data)
            } catch {
                OneFlowLog("[Error]: Decoding Submitted Survey details: \(error.localizedDescription)")
            }
            
        }
    }
    
    func configureSurveys() {
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
    
    func uploadPendingSurveyIfAvailable() {
        if let pendigSurveys = self.pendingSurveySubmission, pendigSurveys.count > 0 {
            pendigSurveys.forEach { (key: String, value: SurveySubmitRequest) in
                self.submitTheSurveyToServer(key, surveyResponse: value)
            }
        }
    }
    private func fetchAllSurvey() {
        OneFlowLog("Fetch Survey called")
        
//        struct Holder { static var called = false }
//            if Holder.called {
//                return
//            } else {
//                Holder.called = true
//            }
        if self.surveyList != nil || self.isSurveyFetching == true {
            OneFlowLog("Survey already Fetched")
            return
        }
        self.isSurveyFetching = true
        OneFlowLog("Fetch Survey - Started")
        apiController.getAllSurveys { [weak self] isSuccess, error, data in
            guard let self = self else {
                return
            }
            self.isSurveyFetching = false
            if isSuccess == true, let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                        OneFlowLog(json)
                    }
                    
                    let surveyListResponse = try JSONDecoder().decode(SurveyListResponse.self, from: data)
                    self.surveyList = surveyListResponse
                    self.checkAfterSurveyLoadForExistingEvents()
                } catch {
                    OneFlowLog(error)
                }
                
            } else {
                OneFlowLog(error?.localizedDescription ?? "NA")
            }
        }
    }
    
    private func checkAfterSurveyLoadForExistingEvents() {
        if let eventsArray = self.temporaryEventArray {
            for eventName in eventsArray {
                if let triggeredSurvey = surveyList?.result.first(where: { survey in
                    if let surveyEventName = survey.trigger_event_name {
                        let eventNames = surveyEventName.components(separatedBy: ",")
                        if eventNames.contains(eventName) {
                            return true
                        }
                    }
                    
                    return false
                }){
                    if self.validateTheSurvey(triggeredSurvey) == true {
                        self.startSurvey(triggeredSurvey, eventName: eventName)
                        break
                    } else {
                        OneFlowLog("Survey already submitted. Do nothing.")
                    }
                }
            }
            self.temporaryEventArray = nil
        }
    }
    
    func validateTheSurvey(_ survey: SurveyListResponse.Survey) -> Bool {
        if let submittedList = self.submittedSurveyDetails, let lastSubmission = submittedList.last(where: { $0.surveyID == survey._id }) {

            if survey.survey_settings?.resurvey_option == false {
                OneFlowLog("Resurvey option is false")
                return false
            }

            if let settings = survey.survey_settings?.retake_survey, let value = settings.retake_input_value, let unit = settings.retake_select_value {

                var totalInterval = 0
                switch unit {
                case "minutes":
                    totalInterval = value * 60
                    break
                case "hours":
                    totalInterval = value * 60 * 60
                    break
                case "days":
                    totalInterval = value * 60 * 60 * 24
                default:
                    OneFlowLog("retake_select_value is neither of minutes, hours or days")
                    return false
                }
                let currentInterval = Int(Date().timeIntervalSince1970)
                if (currentInterval - lastSubmission.submissionTime) < totalInterval {
                    return false
                }
            } else {
                OneFlowLog("retake_survey, retake_input_value or retake_select_value not specified")
                return false
            }
        }
        return true
    }
    
    func newEventRecorded(_ eventName: String) {
        if self.surveyWindow != nil {
            return
        }
        if let surveyList = self.surveyList {
            if let triggerredSurvey = surveyList.result.first(where: { survey in
                if let surveyEventName = survey.trigger_event_name {
                    let eventNames = surveyEventName.components(separatedBy: ",")
                    if eventNames.contains(eventName) {
                        return true
                    }
                }
                
                return false
            }) {
                if self.validateTheSurvey(triggerredSurvey) == true {
                    self.startSurvey(triggerredSurvey, eventName: eventName)
                } else {
                    OneFlowLog("Survey validation not passed")
                }
            }
        } else {
            if temporaryEventArray == nil {
                self.temporaryEventArray = [String]()
            }
            self.temporaryEventArray?.append(eventName)
        }
    }
    
    private func startSurvey(_ survey: SurveyListResponse.Survey, eventName: String) {
        
        if let colorHex = survey.style?.primary_color {
            let themeColor = UIColor.colorFromHex(colorHex)
            kPrimaryColor = themeColor
        }
        
        OneFlow.recordEventName(kEventNameSurveyImpression, parameters: ["survey_id": survey._id])
        guard let screens = survey.screens else { return }
        DispatchQueue.main.async {
            
            if #available(iOS 13.0, *) {
                if let currentWindowScene = UIApplication.shared.connectedScenes.first as?  UIWindowScene {
                   self.surveyWindow = UIWindow(windowScene: currentWindowScene)
                }
                if self.surveyWindow == nil {
                    if let currentWindowScene = UIApplication.shared.connectedScenes
                        .filter({$0.activationState == .foregroundActive})
                        .compactMap({$0 as? UIWindowScene})
                        .first {
                       self.surveyWindow = UIWindow(windowScene: currentWindowScene)
                    }
                }
            } else {
                // Fallback on earlier versions
                self.surveyWindow = UIWindow(frame: UIScreen.main.bounds)
            }
           
            if self.surveyWindow == nil {
                return
            }
            self.surveyWindow?.isHidden = false
            self.surveyWindow?.windowLevel = .alert
            
            let frameworkBundle = Bundle(for: self.classForCoder)
            let controller = RatingViewController(nibName: "RatingViewController", bundle: frameworkBundle)
            controller.modalPresentationStyle = .overFullScreen
            controller.view.backgroundColor = UIColor.clear
            controller.allScreens = screens
            self.surveyWindow?.rootViewController = controller
            
            controller.completionBlock = { [weak self] surveyResponse in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.surveyWindow?.isHidden = true
                    self.surveyWindow = nil
                }
                
                if surveyResponse.count > 0 {
                    
                    let surveyResponse = SurveySubmitRequest(analytic_user_id: ProjectDetailsController.shared.analytic_user_id, survey_id: survey._id, os: "iOS", answers: surveyResponse, session_id: ProjectDetailsController.shared.analytics_session_id, trigger_event: eventName)
                    
                    if self.pendingSurveySubmission == nil {
                        self.pendingSurveySubmission = [survey._id : surveyResponse]
                    } else {
                        self.pendingSurveySubmission![survey._id] = surveyResponse
                    }
                    self.uploadPendingSurveyIfAvailable()
                }
            }
            self.surveyWindow?.makeKeyAndVisible()
        }
    }
    
    private func submitTheSurveyToServer(_ surveyID: String, surveyResponse:SurveySubmitRequest) {
        
        OneFlowLog("submitTheSurveyToServer called")
        
        if self.isNetworkReachable == false {
            OneFlowLog("Network not reachable. Returned")
            return
        }
        
        var surveyResponseTemp = surveyResponse
        
        if surveyResponseTemp.analytic_user_id == nil {
            OneFlowLog("Survey did not have user")
            guard let userID = ProjectDetailsController.shared.analytic_user_id else {
                OneFlowLog("user yet not initialised")
                return
            }
            surveyResponseTemp.analytic_user_id = userID
        }
        
        if surveyResponseTemp.session_id == nil {
            OneFlowLog("Survey did not have session id")
            guard let sessionID = ProjectDetailsController.shared.analytics_session_id else {
                OneFlowLog("Session yet not created")
                return
            }
            surveyResponseTemp.session_id = sessionID
        }
        OneFlowLog("Calling API to submit survey")
        apiController.submitSurveyResponse(surveyResponseTemp) { [weak self] isSuccess, error, data in
            
            guard let self = self else {
                return
            }
            if isSuccess == true, let data = data {
                if self.submittedSurveyDetails == nil {
                    self.submittedSurveyDetails = [SubmittedSurvey]()
                }
                let submittedSurvey = SubmittedSurvey(surveyID: surveyID, submissionTime: Int(Date().timeIntervalSince1970))
                self.submittedSurveyDetails?.append(submittedSurvey)
                self.saveSubmittedSurvey()
                
//                if self.submittedSurveyIDs == nil {
//                    self.submittedSurveyIDs = [surveyID]
//                } else {
//                    self.submittedSurveyIDs?.append(surveyID)
//                }
                self.pendingSurveySubmission?.removeValue(forKey: surveyID)
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                        OneFlowLog(json)
                    }
                } catch {
                    OneFlowLog("Error in response - Submit survey: \(error.localizedDescription)")
                }
                
            } else {
                OneFlowLog("Error - Submit survey: \(error?.localizedDescription ?? "NA")")
            }
        }
    }
}
