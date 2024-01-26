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
    func refreshAnnouncements()
    func newEventRecorded(_ eventName: String, parameter: [String: Any]?)
    func setUserToSubmittedSurveyAsAnnonyous(newUserID: String)
    func startFlow(with flowID: String)
}

class OFSurveyManager: NSObject, SurveyManageable {
    var apiController: APIProtocol = OFAPIController.shared
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
    let myGroup = DispatchGroup()

    var pendingSurveySubmission: [String: SurveySubmitRequest]? {
        get {
            if let data = UserDefaults.standard.value(forKey: "pendingSurveySubmission") as? Data {
                let pendingSurvey = try? PropertyListDecoder().decode([String: SurveySubmitRequest].self, from: data)
                return pendingSurvey
            }
            return nil
        }

        set {
            if let value = newValue, value.count > 0 {
                UserDefaults.standard.set(try? PropertyListEncoder().encode(value), forKey: "pendingSurveySubmission")
            } else {
                UserDefaults.standard.removeObject(forKey: "pendingSurveySubmission")
            }
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
        isNetworkReachable = isReachable
        configureSurveys()
        refreshAnnouncements()
    }

    func uploadPendingSurveyIfAvailable() {
        if let pendigSurveys = self.pendingSurveySubmission, pendigSurveys.count > 0 {
            pendigSurveys.forEach { (key: String, value: SurveySubmitRequest) in
                self.submitSurveyToServer(key, surveyResponse: value)
            }
        }
    }

    func refreshAnnouncements() {
        OneFlowLog.writeLog("refreshAnnouncements called")
        AnnouncementManager.shared.loadAnnouncements()
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
            OneFlowLog.writeLog("Fetch Survey - Returned", .info)
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
        if let eventsArray = self.temporaryEventArray {
            for event in eventsArray {
                myGroup.enter()
                var previousEvent = ["name": event.eventName] as [String: Any]
                if let param = event.parameters {
                    previousEvent["parameters"] = param
                }
                SurveyScriptValidator.shared.validateSurvey(event: previousEvent, completion: { [weak self] survey in
                    guard let self = self else {
                        return
                    }
                    defer {
                        self.myGroup.leave()
                    }
                    guard let survey = survey else {
                        return
                    }
                    OneFlowLog.writeLog("Survey validator returns: \(survey as Any)", .info)
                    if self.validateTheSurvey(survey) == true {
                        if
                            survey.surveyTimeInterval?.type == "show_after",
                            let delay = survey.surveyTimeInterval?.value {
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
                
                self.myGroup.wait()
            }
            self.temporaryEventArray = nil
        }
    }

    func validateTheSurvey(_ survey: SurveyListResponse.Survey) -> Bool {
        if
            let submittedList = self.submittedSurveyDetails,
            let lastSubmission = submittedList.last(
                where: { $0.surveyID == survey.identifier
                    && $0.submittedByUserID == projectDetailsController.currentLoggedUserID }
            ) {
            if survey.surveySettings?.resurveyOption == false {
                OneFlowLog.writeLog("\(#function)Resurvey option is false", .info)
                return false
            }
            if
                let settings = survey.surveySettings?.retakeSurvey,
                let value = settings.retakeInputValue,
                let unit = settings.retakeSelectValue {
                var totalInterval = 0
                switch unit {
                case "minutes":
                    totalInterval = value * 60
                case "hours":
                    totalInterval = value * 60 * 60
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
                OneFlowLog.writeLog("retake_select_value not specified", .info)
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
            AnnouncementManager.shared.newEventRecorded(eventName, parameter: parameter, completion: { isTriggered in
                guard isTriggered == false else {
                    OneFlowLog.writeLog("Announcement is triggered. Dont trigger survey")
                    return
                }
                let filters = allSurveys.result.filter({ self.validateTheSurvey($0)})
                SurveyScriptValidator.shared.setup(with: filters)
                DispatchQueue.main.async {
                    var event = ["name": eventName] as [String: Any]
                    if let param = parameter {
                        event["parameters"] = param
                    }
                    SurveyScriptValidator.shared.validateSurvey(event: event, completion: { [weak self] survey in
                        guard let self = self else {
                            return
                        }
                        guard let survey = survey else {
                            return
                        }
                        OneFlowLog.writeLog("Survey validator returns: \(survey as Any)", .info)
                        if
                            survey.surveyTimeInterval?.type == "show_after",
                            let delay = survey.surveyTimeInterval?.value {
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(delay), execute: {
                                self.startSurvey(survey, eventName: eventName)
                            })
                        } else {
                            self.startSurvey(survey, eventName: eventName)
                        }
                    })
                }
            })
        } else {
            AnnouncementManager.shared.newEventRecorded(eventName, parameter: parameter) { isTriggered in
            }
            OneFlowLog.writeLog("Survey not loaded yet", .info)
            if self.temporaryEventArray == nil {
                self.temporaryEventArray = [EventStore]()
            }
            let eventObj = EventStore(
                eventName: eventName,
                timeInterval: Int(Date().timeIntervalSince1970),
                parameters: parameter
            )
            self.temporaryEventArray?.append(eventObj)
        }
    }

    func validateSurveyThrottling(survey: SurveyListResponse.Survey) -> Bool {
        OneFlowLog.writeLog("Validating Survey Throttling", .info)
        if survey.surveySettings?.overrideGlobalThrottling == true {
            return true
        } else if isThrottlingActivated == true {
            guard let activatedBySurveyID = activatedBySurveyID else {
                // if somehow backend return activated true but not return activatedBySurveyID
                // then return true. otherwise it will never show the survey.
                return true
            }
            if activatedBySurveyID == survey.identifier {
                guard
                    let lastSubmitted = submittedSurveyDetails?.last,
                    let throttlingActivatedTime = throttlingActivatedTime else {
                    return true
                }
                if lastSubmitted.surveyID == survey.identifier {
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

    private func submitSurveyToServer(_ surveyID: String, surveyResponse: SurveySubmitRequest) {
        OneFlowLog.writeLog("submitSurveyToServer called")
        if self.isNetworkReachable == false {
            OneFlowLog.writeLog("Network not reachable. Returned", .info)
            return
        }
        var surveyResponseTemp = surveyResponse
        if surveyResponseTemp.analyticUserID == nil {
            OneFlowLog.writeLog("Survey did not have user", .info)
            guard let userID = projectDetailsController.analyticUserID else {
                OneFlowLog.writeLog("user yet not initialised", .info)
                return
            }
            surveyResponseTemp.analyticUserID = userID
        }
        OneFlowLog.writeLog("Calling API to submit survey")
        apiController.submitSurveyResponse(surveyResponseTemp) { [weak self] isSuccess, error, data in
            guard let self = self else {
                return
            }
            if isSuccess == true, let data = data {
                self.pendingSurveySubmission?.removeValue(forKey: surveyID)
                do {
                    if let json = try JSONSerialization.jsonObject(
                        with: data,
                        options: JSONSerialization.ReadingOptions.fragmentsAllowed
                    ) as? [String: Any] {
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
