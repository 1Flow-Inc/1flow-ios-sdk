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

struct EventStore {
    let eventName: String
    let timeInterval: Int
}

let kPendingSurveyRuleInterval: Int = 3

public let SurveyFinishNotification = Notification.Name("survey_finished")

protocol SurveyManageable {
    var isNetworkReachable: Bool { get  set }
    var projectDetailsController: ProjectDetailsManageable! { get set }

    func uploadPendingSurveyIfAvailable()
    func networkStatusChanged(_ isReachable: Bool)
    func cleanUpSurveyArray()
    func configureSurveys()
    func newEventRecorded(_ eventName: String)
    func setUserToSubmittedSurveyAsAnnonyous(newUserID: String)
}

class OFSurveyManager: NSObject, SurveyManageable {
    var apiController: APIProtocol = OFAPIController()
    var surveyList: SurveyListResponse?
    var surveyWindow: UIWindow?
    var isNetworkReachable = false
    private var isSurveyFetching = false
    var projectDetailsController: ProjectDetailsManageable! = OFProjectDetailsController.shared
    
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
    var temporaryEventArray: [EventStore]?
    
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

    func cleanUpSurveyArray() {
        self.surveyList = nil
        self.apiController = OFAPIController()
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
                    self.checkAfterSurveyLoadForExistingEvents()
                } catch {
                    OneFlowLog.writeLog(error)
                }
                
            } else {
                OneFlowLog.writeLog(error?.localizedDescription ?? "NA")
            }
        }
    }

    func checkAfterSurveyLoadForExistingEvents() {
        if let eventsArray = self.temporaryEventArray {
            let timeInterval = Int(Date().timeIntervalSince1970)
            let eventsToConsider = eventsArray.filter({ timeInterval - $0.timeInterval <= kPendingSurveyRuleInterval })
            for event in eventsToConsider {
                if let triggeredSurvey = surveyList?.result.first(where: { survey in
                    if let surveyEventName = survey.trigger_event_name {
                        let eventNames = surveyEventName.components(separatedBy: ",")
                        if eventNames.contains(event.eventName) {
                            return true
                        }
                    }
                    
                    return false
                }){
                    if self.validateTheSurvey(triggeredSurvey) == true {
                        self.startSurvey(triggeredSurvey, eventName: event.eventName)
                        break
                    } else {
                        OneFlowLog.writeLog("Survey already submitted. Do nothing.")
                    }
                }
            }
            self.temporaryEventArray = nil
        }
    }
    

    func validateTheSurvey(_ survey: SurveyListResponse.Survey) -> Bool {
        if let submittedList = self.submittedSurveyDetails, let lastSubmission = submittedList.last(where: { $0.surveyID == survey._id && $0.submittedByUserID == projectDetailsController.currentLoggedUserID }) {

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
            let triggerredSruvey = surveyList.result.filter({ survey in
                if let surveyEventName = survey.trigger_event_name {
                    let eventNames = surveyEventName.components(separatedBy: ",")
                    if eventNames.contains(eventName) {
                        return true
                    }
                }
                return false
            })
            for survey in triggerredSruvey {
                if self.validateTheSurvey(survey) == true {
                    self.startSurvey(survey, eventName: eventName)
                    break
                } else {
                    OneFlowLog.writeLog("Survey validation not passed. Looking for next survey")
                }
            }
        } else {
            OneFlowLog.writeLog("Survey not loaded yet")
            if temporaryEventArray == nil {
                self.temporaryEventArray = [EventStore]()
            }
            let eventObj = EventStore(eventName: eventName, timeInterval: Int(Date().timeIntervalSince1970))
            self.temporaryEventArray?.append(eventObj)
        }
    }
    
    func startSurvey(_ survey: SurveyListResponse.Survey, eventName: String) {
        
        if let colorHex = survey.style?.primary_color {
            let themeColor = UIColor.colorFromHex(colorHex)
            kBrandColor = themeColor
        }

        if let colorHex = survey.survey_settings?.sdk_theme?.text_color {
            let color = UIColor.colorFromHex(colorHex)
            kPrimaryTitleColor = color
        } else {
            kPrimaryTitleColor = UIColor.black
        }
        
        kSecondaryTitleColor = kPrimaryTitleColor.withAlphaComponent(0.8)
        kFooterColor = kPrimaryTitleColor.withAlphaComponent(0.6)
        kOptionBackgroundColor = kPrimaryTitleColor.withAlphaComponent(0.05)
        kOptionBackgroundColorHightlighted = kPrimaryTitleColor.withAlphaComponent(0.05)
        kWatermarkColor = kPrimaryTitleColor.withAlphaComponent(0.6)
        kWatermarkColorHightlighted = kPrimaryTitleColor.withAlphaComponent(0.05)
        kCloseButtonColor = kPrimaryTitleColor.withAlphaComponent(0.6)
        kSubmitButtonColorDisable = kBrandColor.withAlphaComponent(0.5)

        if let backgroundColor = survey.survey_settings?.sdk_theme?.background_color {
            kBackgroundColor = UIColor.colorFromHex(backgroundColor)
        } else {
            kBackgroundColor = UIColor.white
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
            controller.shouldRemoveWatermark = survey.survey_settings?.sdk_theme?.remove_watermark ?? false
            controller.shouldShowCloseButton = survey.survey_settings?.sdk_theme?.close_button ?? true
            controller.shouldShowDarkOverlay = survey.survey_settings?.sdk_theme?.dark_overlay ?? true
            controller.shouldShowProgressBar = survey.survey_settings?.sdk_theme?.progress_bar ?? true

            controller.modalPresentationStyle = .overFullScreen
            controller.view.backgroundColor = UIColor.clear
            controller.allScreens = screens
            if let widgetPosition = survey.survey_settings?.sdk_theme?.widget_position {
                controller.widgetPosition = widgetPosition
                controller.setupWidgetPosition()

            }
            self.surveyWindow?.rootViewController = controller
            let startDate = Date()
            var callBackParameter = [String: Any]()
            callBackParameter["survey_id"] = survey._id
            callBackParameter["survey_name"] = survey.name
            callBackParameter["trigger_event_name"] = eventName
            callBackParameter["status"] = "NA"
            
            controller.completionBlock = { [weak self] surveyResponse, isCompleted in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.surveyWindow?.isHidden = true
                    self.surveyWindow = nil
                }
                var callBackResponse = [[String: Any]]()
                if surveyResponse.count > 0 {
                    if self.submittedSurveyDetails == nil {
                        self.submittedSurveyDetails = [SubmittedSurvey]()
                    }
                    let submittedSurvey = SubmittedSurvey(surveyID: survey._id, submissionTime: Int(Date().timeIntervalSince1970), submittedByUserID: self.projectDetailsController.currentLoggedUserID)
                    self.submittedSurveyDetails?.append(submittedSurvey)
                    self.saveSubmittedSurvey()
                    let interval = Int(Date().timeIntervalSince(startDate))
                    let surveyResponseNew = SurveySubmitRequest(analytic_user_id: self.projectDetailsController.analytic_user_id, survey_id: survey._id, os: "iOS", answers: surveyResponse, session_id: self.projectDetailsController.analytics_session_id, trigger_event: eventName, tot_duration: interval)

                    if self.pendingSurveySubmission == nil {
                        self.pendingSurveySubmission = [survey._id : surveyResponseNew]
                    } else {
                        self.pendingSurveySubmission![survey._id] = surveyResponseNew
                    }
                    self.uploadPendingSurveyIfAvailable()
                    if isCompleted {
                        callBackParameter["status"] = "finished"
                    } else {
                        callBackParameter["status"] = "closed"
                    }
                    for res in surveyResponse {
                        var innerDic = [String: Any]()
                        innerDic["screen_id"] = res.screen_id
                        if let screen = screens.first(where: { $0._id == res.screen_id }) {
                            innerDic["question_title"] = screen.title
                            innerDic["question_type"] = screen.input?.input_type
                            var question_ans = [[String: String]]()
                            
                            if screen.input?.input_type == "checkbox" {
                                if let givenAnswer = res.answer_index?.components(separatedBy: ",") {
                                    for answerID in givenAnswer {
                                        var newDic = [String: String]()
                                        if screen.input?.other_option_id == answerID {
                                            if let otherOption = res.answer_value {
                                                newDic["other_value"] = otherOption
                                            }
                                        }
                                        if let selectedTitle = screen.input?.choices?.first(where: { $0._id == answerID })?.title {
                                            newDic["answer_value"] = selectedTitle
                                        }
                                        question_ans.append(newDic)
                                    }
                                }
                            } else if screen.input?.input_type == "mcq" {
                                var newDic = [String: String]()
                                if let otherOption = res.answer_value {
                                    newDic["other_value"] = otherOption
                                }
                                if let a_value = res.answer_index {
                                    if let selectedTitle = screen.input?.choices?.first(where: { $0._id == a_value })?.title {
                                        newDic["answer_value"] = selectedTitle
                                    }
                                }
                                question_ans.append(newDic)
                            } else {
                                if let a_value = res.answer_value {
                                    let newDic = ["answer_value": a_value]
                                    question_ans.append(newDic)
                                }
                            }
                            innerDic["question_ans"] = question_ans
                        }
                        callBackResponse.append(innerDic)
                    }
                    callBackParameter["screens"] = callBackResponse
                } else {
                    OneFlow.recordEventName(kEventNameFlowClosed, parameters: ["survey_id": survey._id])
                    if survey.survey_settings?.closed_as_finished == true {
                        if self.submittedSurveyDetails == nil {
                            self.submittedSurveyDetails = [SubmittedSurvey]()
                        }
                        let submittedSurvey = SubmittedSurvey(surveyID: survey._id, submissionTime: Int(Date().timeIntervalSince1970), submittedByUserID: self.projectDetailsController.currentLoggedUserID)
                        self.submittedSurveyDetails?.append(submittedSurvey)
                        self.saveSubmittedSurvey()
                    }
                    callBackParameter["status"] = "skipped"
                }
                NotificationCenter.default.post(name: SurveyFinishNotification, object: nil, userInfo: callBackParameter)
            }
            
            controller.recordEmptyTextCompletionBlock = { [weak self] in
                guard let self = self else { return }
                if self.submittedSurveyDetails == nil {
                    self.submittedSurveyDetails = [SubmittedSurvey]()
                }
                let submittedSurvey = SubmittedSurvey(surveyID: survey._id, submissionTime: Int(Date().timeIntervalSince1970), submittedByUserID: self.projectDetailsController.currentLoggedUserID)
                self.submittedSurveyDetails?.append(submittedSurvey)
                self.saveSubmittedSurvey()
                callBackParameter["status"] = "skipped"
                NotificationCenter.default.post(name: SurveyFinishNotification, object: nil, userInfo: callBackParameter)
            }
            self.surveyWindow?.makeKeyAndVisible()
        }
    }
    
    private func submitTheSurveyToServer(_ surveyID: String, surveyResponse:SurveySubmitRequest) {
        
        OneFlowLog.writeLog("submitSurveyToServer called")
        
        if self.isNetworkReachable == false {
            OneFlowLog.writeLog("Network not reachable. Returned")
            return
        }
        
        var surveyResponseTemp = surveyResponse
        if surveyResponseTemp.analytic_user_id == nil {
            OneFlowLog.writeLog("Survey did not have user")
            guard let userID = projectDetailsController.analytic_user_id else {
                OneFlowLog.writeLog("user yet not initialised")
                return
            }
            surveyResponseTemp.analytic_user_id = userID
        }
        
        if surveyResponseTemp.session_id == nil {
            OneFlowLog.writeLog("Survey did not have session id")
            guard let sessionID = projectDetailsController.analytics_session_id else {
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
