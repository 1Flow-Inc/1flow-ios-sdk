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
    let parameters: [String: Any]?
}

public let SurveyFinishNotification = Notification.Name("survey_finished")

protocol SurveyManageable {
    var isNetworkReachable: Bool { get  set }
    var projectDetailsController: ProjectDetailsManageable! { get set }

    func uploadPendingSurveyIfAvailable()
    func networkStatusChanged(_ isReachable: Bool)
    func cleanUpSurveyArray()
    func configureSurveys()
    func newEventRecorded(_ eventName: String, parameter: [String: Any]?)
    func setUserToSubmittedSurveyAsAnnonyous(newUserID: String)
    func startFlow(with flowID: String)
}

class OFSurveyManager: NSObject, SurveyManageable {
    var apiController: APIProtocol = OFAPIController()
    var surveyList: SurveyListResponse?
    var surveyWindow: UIWindow?
    var isNetworkReachable = false
    private var isSurveyFetching = false
    var projectDetailsController: ProjectDetailsManageable! = OFProjectDetailsController.shared
    var isThrottlingActivated: Bool? = false
    var globalTime: Int?
    var activatedBySurveyID: String?
    var throttlingActivatedTime: Int?
    var deactivateItem: DispatchWorkItem?
//    var surveyValidator: SurveyScriptValidator?
    
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
            OneFlowLog.writeLog("[Error]: Unable to save submitted survey: \(error.localizedDescription)", .error)
        }
    }
    
    override init() {
        super.init()
        OneFlowLog.writeLog("OFSurveyManager: Started")
        if let data = UserDefaults.standard.value(forKey: "FBSubmittedSurveys") as? Data {
            do {
                submittedSurveyDetails = try JSONDecoder().decode([SubmittedSurvey].self, from: data)
            } catch {
                OneFlowLog.writeLog("[Error]: Decoding Submitted Survey details: \(error.localizedDescription)", .error)
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
            OneFlowLog.writeLog("Survey already Fetched", .info)
            return
        }
        self.isSurveyFetching = true
        OneFlowLog.writeLog("Fetch Survey - Started", .info)
        apiController.getAllSurveys { [weak self] isSuccess, error, data in
            guard let self = self else {
                return
            }
            self.isSurveyFetching = false
            if isSuccess == true, let data = data {
                do {
                    let surveyListResponse = try JSONDecoder().decode(SurveyListResponse.self, from: data)
                    self.surveyList = surveyListResponse
                    self.activatedBySurveyID = surveyListResponse.throttlingMobileSDKConfig?.activatedBySurveyID
                    self.isThrottlingActivated = surveyListResponse.throttlingMobileSDKConfig?.isThrottlingActivated
                    self.globalTime = surveyListResponse.throttlingMobileSDKConfig?.globalTime
                    self.throttlingActivatedTime = surveyListResponse.throttlingMobileSDKConfig?.throttlingActivatedTime
                    
                    let filteredSurvey = surveyListResponse.result.filter({self.validateTheSurvey($0)})
                    SurveyScriptValidator.shared.setup(with: filteredSurvey)
                    self.setupGlobalTimerToDeactivateThrottling()
                    self.checkAfterSurveyLoadForExistingEvents()
                } catch {
                    OneFlowLog.writeLog("\(#function) error: \(error)", .error)
                }
                
            } else {
                OneFlowLog.writeLog("\(#function) \(error?.localizedDescription ?? "NA")", .error)
            }
        }
    }

    func checkAfterSurveyLoadForExistingEvents() {
        let semaphore = DispatchSemaphore(value: 1)

        if let eventsArray = self.temporaryEventArray {
            for event in eventsArray {
                semaphore.wait()
                var previousEvent = ["name": event.eventName] as [String : Any]
                if let param = event.parameters {
                    previousEvent["parameters"] = param
                }
                SurveyScriptValidator.shared.validateSurvey(event: previousEvent, completion: { survey in
                    defer {
                        semaphore.signal()
                    }
                    guard let survey = survey else {
                        return
                    }
                    print("Survey validator returns: \(survey as Any)")
                    if self.validateTheSurvey(survey) == true {
                        if
                            survey.survey_time_interval?.type == "show_after",
                            let delay = survey.survey_time_interval?.value {
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(delay), execute: {
                                self.startSurvey(survey, eventName: event.eventName)
                            })
                        } else {
                            self.startSurvey(survey, eventName: event.eventName)
                        }
                    } else {
                        OneFlowLog.writeLog("Survey validation not passed. Looking for next survey", .info)
                    }
                })
            }
            self.temporaryEventArray = nil
        }
    }
    

    func validateTheSurvey(_ survey: SurveyListResponse.Survey) -> Bool {
        if let submittedList = self.submittedSurveyDetails, let lastSubmission = submittedList.last(where: { $0.surveyID == survey._id && $0.submittedByUserID == projectDetailsController.currentLoggedUserID }) {

            if survey.survey_settings?.resurvey_option == false {
                OneFlowLog.writeLog("\(#function)Resurvey option is false", .info)
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
                    OneFlowLog.writeLog("\(#function) retake_select_value is neither of minutes, hours or days", .info)
                    return false
                }
                let currentInterval = Int(Date().timeIntervalSince1970)
                if (currentInterval - lastSubmission.submissionTime) < totalInterval {
                    return false
                }
            } else {
                OneFlowLog.writeLog("\(#function) retake_survey, retake_input_value or retake_select_value not specified", .info)
                return false
            }
        }
        return true
    }

    func newEventRecorded(_ eventName: String, parameter: [String: Any]? = nil) {
        if self.surveyWindow != nil {
            return
        }
        if let allSurveys = self.surveyList {
            let filters = allSurveys.result.filter({ self.validateTheSurvey($0)})
            SurveyScriptValidator.shared.setup(with: filters)
            DispatchQueue.main.async {
                var event = ["name": eventName] as [String : Any]
                if let param = parameter {
                    event["parameters"] = param
                }
                SurveyScriptValidator.shared.validateSurvey(event: event, completion: { survey in
                    guard let survey = survey else {
                        return
                    }
                    print("Survey validator returns: \(survey as Any)")
                    if
                        survey.survey_time_interval?.type == "show_after",
                        let delay = survey.survey_time_interval?.value {
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(delay), execute: {
                            self.startSurvey(survey, eventName: eventName)
                        })
                    } else {
                        self.startSurvey(survey, eventName: eventName)
                    }
                })
            }
        } else {
            OneFlowLog.writeLog("Survey not loaded yet", .info)
            if temporaryEventArray == nil {
                self.temporaryEventArray = [EventStore]()
            }
            let eventObj = EventStore(eventName: eventName, timeInterval: Int(Date().timeIntervalSince1970), parameters: parameter)
            self.temporaryEventArray?.append(eventObj)
        }
    }

    func validateSurveyThrottling(survey: SurveyListResponse.Survey) -> Bool {
        OneFlowLog.writeLog("Validating Survey Throttling", .info)
        if survey.survey_settings?.override_global_throttling == true {
            return true
        } else if isThrottlingActivated == true {
            guard let activatedBySurveyID = activatedBySurveyID else {
                // if somehow backend return activated true but not return activatedBySurveyID then return true. otherwise it will never show the survey.
                return true
            }
            if activatedBySurveyID == survey._id {
                guard let lastSubmitted = submittedSurveyDetails?.last, let throttlingActivatedTime = throttlingActivatedTime else {
                    return true
                }
                if lastSubmitted.surveyID == survey._id {
                    if lastSubmitted.submissionTime < throttlingActivatedTime {
                        return true
                    } else {
                        return false
                    }
                } else {
                    return true
                }
            } else {
                return false
            }
        } else {
            return true
        }
    }

    func setupGlobalTimerToDeactivateThrottling() {
        guard let globalTime = globalTime, globalTime > 0 else {
            OneFlowLog.writeLog("Global throttling time not available. Throttling stopped", .verbose)
            isThrottlingActivated = false
            activatedBySurveyID = nil
            deactivateItem?.cancel()
            return
        }
        if isThrottlingActivated == true {
            let currentTime = Int(Date().timeIntervalSince1970)
            let timeRemains =  Double((throttlingActivatedTime ?? currentTime) - currentTime + globalTime)
            deactivateItem?.cancel()
            OneFlowLog.writeLog("Scheduling throttling for: \(timeRemains) seconds", .verbose)
            deactivateItem = DispatchWorkItem {
                OneFlowLog.writeLog("Throttling stopped", .verbose)
                self.isThrottlingActivated = false
                self.activatedBySurveyID = nil
            }
            if let deactivateItem = deactivateItem {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeRemains, execute: deactivateItem)
            }
        } else {
            OneFlowLog.writeLog("Throttling not activated yet", .verbose)
        }
    }

    func startSurvey(_ survey: SurveyListResponse.Survey, eventName: String) {
        if self.surveyWindow != nil {
            return
        }
        if validateSurveyThrottling(survey: survey) == false {
            OneFlowLog.writeLog("Survey Throttling validation not passed", .info)
            return
        }
        OneFlowLog.writeLog("Survey Throttling validation passed", .info)
        isThrottlingActivated = true
        activatedBySurveyID = survey._id
        throttlingActivatedTime = Int(Date().timeIntervalSince1970)
        setupGlobalTimerToDeactivateThrottling()
        
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
        let uniqueID = OFProjectDetailsController.objectId()
        
        OneFlow.recordEventName(kEventNameSurveyImpression, parameters: ["survey_id": survey._id])
        OneFlow.shared.eventManager.recordInternalEvent(
            name: InternalEvent.flowStarted,
            parameters: [InternalKey.flowId : survey._id]
        )
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
            self.surveyWindow?.windowLevel = .normal
            
            let controller = OFRatingViewController(nibName: "OFRatingViewController", bundle: OneFlowBundle.bundleForObject(self))
            controller.shouldRemoveWatermark = survey.survey_settings?.sdk_theme?.remove_watermark ?? false
            controller.shouldShowCloseButton = survey.survey_settings?.sdk_theme?.close_button ?? true
            controller.shouldShowDarkOverlay = survey.survey_settings?.sdk_theme?.dark_overlay ?? true
            controller.shouldShowProgressBar = survey.survey_settings?.sdk_theme?.progress_bar ?? true

            controller.modalPresentationStyle = .overFullScreen
            controller.view.backgroundColor = UIColor.clear
            controller.allScreens = screens
            controller.surveyID = survey._id
            controller.surveyName = survey.name
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
                    let surveyResponseNew = SurveySubmitRequest(analytic_user_id: self.projectDetailsController.analytic_user_id, survey_id: survey._id, os: "iOS", answers: surveyResponse, trigger_event: eventName, tot_duration: interval, _id: uniqueID)

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
                    if survey.survey_settings?.closed_as_finished == true || isCompleted {
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
            }
            self.surveyWindow?.makeKeyAndVisible()
        }
    }
    
    private func submitTheSurveyToServer(_ surveyID: String, surveyResponse:SurveySubmitRequest) {
        
        OneFlowLog.writeLog("submitSurveyToServer called")
        
        if self.isNetworkReachable == false {
            OneFlowLog.writeLog("Network not reachable. Returned", .info)
            return
        }
        
        var surveyResponseTemp = surveyResponse
        if surveyResponseTemp.analytic_user_id == nil {
            OneFlowLog.writeLog("Survey did not have user", .info)
            guard let userID = projectDetailsController.analytic_user_id else {
                OneFlowLog.writeLog("user yet not initialised", .info)
                return
            }
            surveyResponseTemp.analytic_user_id = userID
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
                    OneFlowLog.writeLog("Error in response - Submit survey: \(error.localizedDescription)", .error)
                }
            } else {
                OneFlowLog.writeLog("Error - Submit survey: \(error?.localizedDescription ?? "NA")", .error)
            }
        }
    }

    func startFlow(with flowID: String) {
        apiController.fetchSurvey(flowID) { [weak self] isSuccess, error, data in
            guard let self = self else {
                return
            }
            if isSuccess == true, let data = data {
                do {
                    let flow = try JSONDecoder().decode(FetchFlow.self, from: data)
                    guard let surveyToTrigger = flow.result else {
                        return
                    }
                    self.startSurvey(surveyToTrigger, eventName: kEventNameManualTrigger)
                    
                } catch {
                    OneFlowLog.writeLog("\(#function) error: \(error)", .error)
                }
                
            } else {
                OneFlowLog.writeLog("\(#function) \(error?.localizedDescription ?? "NA")", .error)
            }
        }
    }
}
