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

final class OFSurveyManager: NSObject {
    let apiController = OFAPIController()
    var surveyList: SurveyListResponse?
    var surveyWindow: UIWindow?
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
            OneFlowLog.writeLog("[Error]: Unable to save submitted survey: \(error.localizedDescription)")
        }
    }
    
    override init() {
        super.init()
        OneFlowLog.writeLog("OFSurveyManager: Started")
        if let data = UserDefaults.standard.value(forKey: "FBSubmittedSurveys") as? Data {
            do {
                submittedSurveyDetails = try JSONDecoder().decode([SubmittedSurvey].self, from: data)
            } catch {
                OneFlowLog.writeLog("[Error]: Decoding Submitted Survey details: \(error.localizedDescription)")
            }
            
        }
    }
    
    func setUserToSubmittedSurveyAsAnnonyous(newUserID: String) {
        if self.submittedSurveyDetails != nil {
            for index in 0..<self.submittedSurveyDetails!.count {
                self.submittedSurveyDetails![index].setNewUser(newUserID)
            }
            self.saveSubmittedSurvey()
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
        OneFlowLog.writeLog("Fetch Survey called")
        if self.surveyList != nil || self.isSurveyFetching == true {
            OneFlowLog.writeLog("Survey already Fetched")
            return
        }
        self.isSurveyFetching = true
        OneFlowLog.writeLog("Fetch Survey - Started")
        apiController.getAllSurveys { [weak self] isSuccess, error, data in
            guard let self = self else {
                return
            }
            self.isSurveyFetching = false
            if isSuccess == true, let data = data {
                do {
                    let surveyListResponse = try JSONDecoder().decode(SurveyListResponse.self, from: data)
                    self.surveyList = surveyListResponse
                } catch {
                    OneFlowLog.writeLog(error)
                }
                
            } else {
                OneFlowLog.writeLog(error?.localizedDescription ?? "NA")
            }
        }
    }

    func validateTheSurvey(_ survey: SurveyListResponse.Survey) -> Bool {
        if let submittedList = self.submittedSurveyDetails, let lastSubmission = submittedList.last(where: { $0.surveyID == survey._id && $0.submittedByUserID == OFProjectDetailsController.shared.currentLoggedUserID }) {

            if survey.survey_settings?.resurvey_option == false {
                OneFlowLog.writeLog("Resurvey option is false")
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
                    OneFlowLog.writeLog("retake_select_value is neither of minutes, hours or days")
                    return false
                }
                let currentInterval = Int(Date().timeIntervalSince1970)
                if (currentInterval - lastSubmission.submissionTime) < totalInterval {
                    return false
                }
            } else {
                OneFlowLog.writeLog("retake_survey, retake_input_value or retake_select_value not specified")
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
                    OneFlowLog.writeLog("Survey validation not passed")
                }
            }
        } else {
            OneFlowLog.writeLog("Survey not loaded yet")
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
            
            let controller = OFRatingViewController(nibName: "OFRatingViewController", bundle: OneFlowBundle.bundleForObject(self))
            controller.modalPresentationStyle = .overFullScreen
            controller.view.backgroundColor = UIColor.clear
            controller.allScreens = screens
            self.surveyWindow?.rootViewController = controller
            let startDate = Date()
            controller.completionBlock = { [weak self] surveyResponse in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.surveyWindow?.isHidden = true
                    self.surveyWindow = nil
                }

                if surveyResponse.count > 0 {
                    if self.submittedSurveyDetails == nil {
                        self.submittedSurveyDetails = [SubmittedSurvey]()
                    }
                    let submittedSurvey = SubmittedSurvey(surveyID: survey._id, submissionTime: Int(Date().timeIntervalSince1970), submittedByUserID: OFProjectDetailsController.shared.currentLoggedUserID)
                    self.submittedSurveyDetails?.append(submittedSurvey)
                    self.saveSubmittedSurvey()
                    let interval = Int(Date().timeIntervalSince(startDate))
                    let surveyResponse = SurveySubmitRequest(analytic_user_id: OFProjectDetailsController.shared.analytic_user_id, survey_id: survey._id, os: "iOS", answers: surveyResponse, session_id: OFProjectDetailsController.shared.analytics_session_id, trigger_event: eventName, tot_duration: interval)

                    if self.pendingSurveySubmission == nil {
                        self.pendingSurveySubmission = [survey._id : surveyResponse]
                    } else {
                        self.pendingSurveySubmission![survey._id] = surveyResponse
                    }
                    self.uploadPendingSurveyIfAvailable()
                }
            }
            
            controller.recordEmptyTextCompletionBlock = { [weak self] in
                guard let self = self else { return }
                if self.submittedSurveyDetails == nil {
                    self.submittedSurveyDetails = [SubmittedSurvey]()
                }
                let submittedSurvey = SubmittedSurvey(surveyID: survey._id, submissionTime: Int(Date().timeIntervalSince1970), submittedByUserID: OFProjectDetailsController.shared.currentLoggedUserID)
                self.submittedSurveyDetails?.append(submittedSurvey)
                self.saveSubmittedSurvey()
            }
            self.surveyWindow?.makeKeyAndVisible()
        }
    }
    
    private func submitTheSurveyToServer(_ surveyID: String, surveyResponse:SurveySubmitRequest) {
        
        OneFlowLog.writeLog("submitTheSurveyToServer called")
        
        if self.isNetworkReachable == false {
            OneFlowLog.writeLog("Network not reachable. Returned")
            return
        }
        
        var surveyResponseTemp = surveyResponse
        if surveyResponseTemp.analytic_user_id == nil {
            OneFlowLog.writeLog("Survey did not have user")
            guard let userID = OFProjectDetailsController.shared.analytic_user_id else {
                OneFlowLog.writeLog("user yet not initialised")
                return
            }
            surveyResponseTemp.analytic_user_id = userID
        }
        
        if surveyResponseTemp.session_id == nil {
            OneFlowLog.writeLog("Survey did not have session id")
            guard let sessionID = OFProjectDetailsController.shared.analytics_session_id else {
                OneFlowLog.writeLog("Session yet not created")
                return
            }
            surveyResponseTemp.session_id = sessionID
        }
        OneFlowLog.writeLog("Calling API to submit survey")
        apiController.submitSurveyResponse(surveyResponseTemp) { [weak self] isSuccess, error, data in
            
            guard let self = self else {
                return
            }
            if isSuccess == true, let data = data {
                self.pendingSurveySubmission?.removeValue(forKey: surveyID)
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                        OneFlowLog.writeLog(json)
                    }
                } catch {
                    OneFlowLog.writeLog("Error in response - Submit survey: \(error.localizedDescription)")
                }
            } else {
                OneFlowLog.writeLog("Error - Submit survey: \(error?.localizedDescription ?? "NA")")
            }
        }
    }
}
