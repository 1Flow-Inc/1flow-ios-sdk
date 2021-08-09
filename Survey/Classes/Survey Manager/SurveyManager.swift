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
    var pendingSurveySubmission: [String: SurveySubmitRequest]?
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
        if self.surveyList == nil && self.isNetworkReachable == true {
            self.fetchAllSurvey()
        }
    }
    
    func networkStatusChanged(_ isReachable: Bool) {
        self.isNetworkReachable = isReachable
        if isReachable == true {
            self.configureSurveys()
            self.uploadPendingSurveyIfAvailable()
        }
    }
    private func uploadPendingSurveyIfAvailable() {
        if let pendigSurveys = self.pendingSurveySubmission, pendigSurveys.count > 0 {
            if ProjectDetailsController.shared.analytic_user_id != nil {
                pendigSurveys.forEach { (key: String, value: SurveySubmitRequest) in
                    self.submitTheSurveyToServer(key, surveyResponse: value)
                }
            }
        }
    }
    func fetchAllSurvey() {
        FBLogs("Fetch Survey called")
        apiController.getAllSurveys { [weak self] isSuccess, error, data in
            guard let self = self else {
                return
            }
            if isSuccess == true, let data = data {
                do {
                    
                    if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                        FBLogs(json)
                    }
                    
                    let surveyListResponse = try JSONDecoder().decode(SurveyListResponse.self, from: data)
                    self.surveyList = surveyListResponse
                    self.checkAfterSurveyLoadForExistingEvents()
                    
                    FBLogs(self.surveyList as Any)
                } catch {
                    FBLogs(error)
                }
                
            } else {
                FBLogs(error?.localizedDescription ?? "NA")
            }
        }
    }
    
    func checkAfterSurveyLoadForExistingEvents() {
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
    
    func startSurvey(_ survey: SurveyListResponse.Survey) {
        if ProjectDetailsController.shared.analytic_user_id == nil {
            return
        }
        FeedbackController.recordEventName(kEventNameSurveyImpression, parameters: ["survey_id": survey._id])
        
        var surveyAnswers = [SurveySubmitRequest.Answer]()
        let semaphore = DispatchSemaphore(value: 0)
        var shouldContinueLoop = true
        for screen in survey.screens {
            if shouldContinueLoop == false {
                break
            }
            let frameworkBundle = Bundle(for: self.classForCoder)
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
                self.surveyWindow!.rootViewController = UIViewController()
                self.surveyWindow!.makeKeyAndVisible()
                
                let controller = RatingViewController(nibName: "RatingViewController", bundle: frameworkBundle)
                controller.screen = screen
                controller.modalPresentationStyle = .overFullScreen
                controller.view.backgroundColor = UIColor.clear
                controller.view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
                controller.completionBlock = { answerValue, answerIndex, isSubmitted in
                    
                    if isSubmitted == false {
                        shouldContinueLoop = false
                    }
                    
                    if answerValue == nil, answerIndex == nil {
                        //user have canceled it. Go to next screen
                        semaphore.signal()
                        
                    } else {
                        if screen.input.input_type == "mcq" {
                            
                            if let selectedChoice = screen.input.choices?.first(where: { $0.title == answerValue }) {
                                let answer = SurveySubmitRequest.Answer(screen_id: screen._id, answer_value: answerValue, answer_index: selectedChoice._id)
                                surveyAnswers.append(answer)
                            }
                        } else {
                            let answer = SurveySubmitRequest.Answer(screen_id: screen._id, answer_value: answerValue, answer_index: (answerIndex == nil) ? nil : "\(answerIndex!)")
                            surveyAnswers.append(answer)
                        }
                        semaphore.signal()
                    }
                }
                
                if var topController = self.surveyWindow?.rootViewController {
                    while let presentedViewController = topController.presentedViewController {
                        topController = presentedViewController
                    }
                    topController.present(controller, animated: false, completion: {
                        controller.animateRatingView()
                    })
                }
            }
            semaphore.wait()
        }
        
        DispatchQueue.main.async {
            self.surveyWindow?.isHidden = true
        }
        
        //Change condition according to business logic. If User have given feedback for some screen but then cancelled the survey. Then what is expected behaviour.
        //Here if surveyAnswers count > 0 then user have given feedback for atlease one screen.
        //Here if shouldContinueLoop == false then user have cancelled the survey.
        
        //Right now, If user have submitted response for some screens, but cancel the thank_you screen, then it will submit the response.
        if surveyAnswers.count == 0 {
            return
        }
        
        //Uncomment below code for If user have cancelled in any screen then it will not submit the response to server.
//        if shouldContinueLoop == false {
//            return
//        }
        
        let surveyResponse = SurveySubmitRequest(analytic_user_id: ProjectDetailsController.shared.analytic_user_id, survey_id: survey._id, os: "iOS", answers: surveyAnswers)
        if self.isNetworkReachable == false {
            if self.pendingSurveySubmission == nil {
                self.pendingSurveySubmission = [survey._id : surveyResponse]
            } else {
                self.pendingSurveySubmission![survey._id] = surveyResponse
            }
            return
        } else {
            self.submitTheSurveyToServer(survey._id, surveyResponse: surveyResponse)
        }
    }
    
    func submitTheSurveyToServer(_ surveyID: String, surveyResponse:SurveySubmitRequest) {
        
        apiController.submitSurveyResponse(surveyResponse) { [weak self] isSuccess, error, data in
            
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
                    FBLogs(error)
                }
                
            } else {
                FBLogs(error?.localizedDescription ?? "NA")
            }
        }
    }
}
