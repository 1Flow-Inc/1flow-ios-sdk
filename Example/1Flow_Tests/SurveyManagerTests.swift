//
//  SurveyManagerTests.swift
//  1Flow_Tests
//
//  Created by Rohan Moradiya on 14/06/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import XCTest
@testable import _1Flow
@testable import _Flow_Example

class SurveyManagerTest: XCTestCase {
    
    func testSurveyValidation_shouldReturnTrue_whenNoSavedSurvey() {
        guard let data = MockResponseProvider.getDataForSurveyResponse() else {
            return
        }
        do {
            let surveyListResponse = try JSONDecoder().decode(SurveyListResponse.self, from: data)
            guard let surveyToValidate = surveyListResponse.result.first else {
                return
            }
            let surveyManager = OFSurveyManager()
            let projectDetails = MockProjectDetailsController()
            projectDetails.currentLoggedUserID = "iOS_user_2"
            surveyManager.projectDetailsController = projectDetails
            surveyManager.submittedSurveyDetails = nil
            let result = surveyManager.validateTheSurvey(surveyToValidate)
            XCTAssertTrue(result, "Survey should be successfully validate")
        } catch {
            
        }
    }

    func testSurveyValidation_shouldReturnFalse_forSingleUseSurvey_whenSurveyIsAlreadySubmitted() {
        guard let data = MockResponseProvider.getDataForSurveyResponse() else {
            return
        }
        
        guard let submittedSurveyData = MockResponseProvider.getDataForSavedSurvey() else {
            return
        }
        
        do {
            let submittedSurveyDetails = try JSONDecoder().decode([SubmittedSurvey].self, from: submittedSurveyData)
            
            let surveyListResponse = try JSONDecoder().decode(SurveyListResponse.self, from: data)
            guard var surveyToValidate = surveyListResponse.result.first else {
                return
            }
            surveyToValidate.survey_settings?.resurvey_option = false
            let surveyManager = OFSurveyManager()
            surveyManager.submittedSurveyDetails = submittedSurveyDetails
            let projectDetails = MockProjectDetailsController()
            projectDetails.currentLoggedUserID = "iOS_user_2"
            surveyManager.projectDetailsController = projectDetails
            let result = surveyManager.validateTheSurvey(surveyToValidate)
            XCTAssertFalse(result, "Survey should not be validated")
        } catch {
            
        }
    }

    func testSurveyValidation_shouldReturnTrue_forRecurringSurvey_whenSurveyIsAlreadySubmittedBefore2Minutes() {
        guard let data = MockResponseProvider.getDataForSurveyResponse() else {
            return
        }
        
        guard let submittedSurveyData = MockResponseProvider.getDataForSavedSurvey() else {
            return
        }
        
        do {
            let submittedSurveyDetails = try JSONDecoder().decode([SubmittedSurvey].self, from: submittedSurveyData)
            
            let surveyListResponse = try JSONDecoder().decode(SurveyListResponse.self, from: data)
            guard var surveyToValidate = surveyListResponse.result.first else {
                return
            }
            surveyToValidate.survey_settings?.resurvey_option = true
            surveyToValidate.survey_settings?.retake_survey?.retake_input_value = 2
            surveyToValidate.survey_settings?.retake_survey?.retake_select_value = "minutes"
            
            let timeIntervalBefore2Mins = Int(Date().timeIntervalSince1970) - 121
            var firstSubmiited = submittedSurveyDetails.first!
            firstSubmiited.submissionTime = timeIntervalBefore2Mins
            
            let surveyManager = OFSurveyManager()
            let projectDetails = MockProjectDetailsController()
            projectDetails.currentLoggedUserID = "iOS_user_2"
            surveyManager.projectDetailsController = projectDetails
            surveyManager.submittedSurveyDetails = [firstSubmiited]
            let result = surveyManager.validateTheSurvey(surveyToValidate)
            XCTAssertTrue(result, "Survey should be validated")
        } catch {
            
        }
    }

    func testSurveyValidation_shouldReturnFalse_forRecurringSurvey_whenSurveyIsAlreadySubmittedIn2Minute() {
        guard let data = MockResponseProvider.getDataForSurveyResponse() else {
            return
        }
        
        guard let submittedSurveyData = MockResponseProvider.getDataForSavedSurvey() else {
            return
        }
        
        do {
            let submittedSurveyDetails = try JSONDecoder().decode([SubmittedSurvey].self, from: submittedSurveyData)
            
            let surveyListResponse = try JSONDecoder().decode(SurveyListResponse.self, from: data)
            guard var surveyToValidate = surveyListResponse.result.first else {
                return
            }
            surveyToValidate.survey_settings?.resurvey_option = true
            surveyToValidate.survey_settings?.retake_survey?.retake_input_value = 2
            surveyToValidate.survey_settings?.retake_survey?.retake_select_value = "minutes"
            
            let timeIntervalBefore2Mins = Int(Date().timeIntervalSince1970) - 115
            var firstSubmiited = submittedSurveyDetails.first!
            firstSubmiited.submissionTime = timeIntervalBefore2Mins
            
            let surveyManager = OFSurveyManager()
            let projectDetails = MockProjectDetailsController()
            projectDetails.currentLoggedUserID = "iOS_user_2"
            surveyManager.projectDetailsController = projectDetails
            surveyManager.submittedSurveyDetails = [firstSubmiited]
            let result = surveyManager.validateTheSurvey(surveyToValidate)
            XCTAssertFalse(result, "Survey should be not validated")
        } catch {
            
        }
    }

    func testSurveyValidation_shouldReturnTrue_forRecurringSurvey_whenSurveyIsAlreadySubmittedBefore2Hours() {
        guard let data = MockResponseProvider.getDataForSurveyResponse() else {
            return
        }
        
        guard let submittedSurveyData = MockResponseProvider.getDataForSavedSurvey() else {
            return
        }
        
        do {
            let submittedSurveyDetails = try JSONDecoder().decode([SubmittedSurvey].self, from: submittedSurveyData)
            
            let surveyListResponse = try JSONDecoder().decode(SurveyListResponse.self, from: data)
            guard var surveyToValidate = surveyListResponse.result.first else {
                return
            }
            surveyToValidate.survey_settings?.resurvey_option = true
            surveyToValidate.survey_settings?.retake_survey?.retake_input_value = 2
            surveyToValidate.survey_settings?.retake_survey?.retake_select_value = "hours"
            
            let timeIntervalBefore2Hours = Int(Date().timeIntervalSince1970) - 7201
            var firstSubmiited = submittedSurveyDetails.first!
            firstSubmiited.submissionTime = timeIntervalBefore2Hours
            
            let surveyManager = OFSurveyManager()
            let projectDetails = MockProjectDetailsController()
            projectDetails.currentLoggedUserID = "iOS_user_2"
            surveyManager.projectDetailsController = projectDetails
            surveyManager.submittedSurveyDetails = [firstSubmiited]
            let result = surveyManager.validateTheSurvey(surveyToValidate)
            XCTAssertTrue(result, "Survey should be validated")
        } catch {
            
        }
    }

    func testSurveyValidation_shouldReturnFalse_forRecurringSurvey_whenSurveyIsAlreadySubmittedIn2Hours() {
        guard let data = MockResponseProvider.getDataForSurveyResponse() else {
            return
        }
        
        guard let submittedSurveyData = MockResponseProvider.getDataForSavedSurvey() else {
            return
        }
        
        do {
            let submittedSurveyDetails = try JSONDecoder().decode([SubmittedSurvey].self, from: submittedSurveyData)
            
            let surveyListResponse = try JSONDecoder().decode(SurveyListResponse.self, from: data)
            guard var surveyToValidate = surveyListResponse.result.first else {
                return
            }
            surveyToValidate.survey_settings?.resurvey_option = true
            surveyToValidate.survey_settings?.retake_survey?.retake_input_value = 2
            surveyToValidate.survey_settings?.retake_survey?.retake_select_value = "hours"
            
            let timeIntervalBefore2Hours = Int(Date().timeIntervalSince1970) - 7195
            var firstSubmiited = submittedSurveyDetails.first!
            firstSubmiited.submissionTime = timeIntervalBefore2Hours
            
            let surveyManager = OFSurveyManager()
            let projectDetails = MockProjectDetailsController()
            projectDetails.currentLoggedUserID = "iOS_user_2"
            surveyManager.projectDetailsController = projectDetails
            surveyManager.submittedSurveyDetails = [firstSubmiited]
            let result = surveyManager.validateTheSurvey(surveyToValidate)
            XCTAssertFalse(result, "Survey should be not validated")
        } catch {
            
        }
    }

    func testSurveyValidation_shouldReturnTrue_forRecurringSurvey_whenSurveyIsAlreadySubmittedBefore2Days() {
        guard let data = MockResponseProvider.getDataForSurveyResponse() else {
            return
        }
        
        guard let submittedSurveyData = MockResponseProvider.getDataForSavedSurvey() else {
            return
        }
        
        do {
            let submittedSurveyDetails = try JSONDecoder().decode([SubmittedSurvey].self, from: submittedSurveyData)
            
            let surveyListResponse = try JSONDecoder().decode(SurveyListResponse.self, from: data)
            guard var surveyToValidate = surveyListResponse.result.first else {
                return
            }
            surveyToValidate.survey_settings?.resurvey_option = true
            surveyToValidate.survey_settings?.retake_survey?.retake_input_value = 2
            surveyToValidate.survey_settings?.retake_survey?.retake_select_value = "days"
            
            let timeIntervalBefore2Days = Int(Date().timeIntervalSince1970) - 172801
            var firstSubmiited = submittedSurveyDetails.first!
            firstSubmiited.submissionTime = timeIntervalBefore2Days
            
            let surveyManager = OFSurveyManager()
            let projectDetails = MockProjectDetailsController()
            projectDetails.currentLoggedUserID = "iOS_user_2"
            surveyManager.projectDetailsController = projectDetails
            surveyManager.submittedSurveyDetails = [firstSubmiited]
            let result = surveyManager.validateTheSurvey(surveyToValidate)
            XCTAssertTrue(result, "Survey should be validated")
        } catch {
            
        }
    }

    func testSurveyValidation_shouldReturnFalse_forRecurringSurvey_whenSurveyIsAlreadySubmittedIn2Days() {
        guard let data = MockResponseProvider.getDataForSurveyResponse() else {
            return
        }
        
        guard let submittedSurveyData = MockResponseProvider.getDataForSavedSurvey() else {
            return
        }
        
        do {
            let submittedSurveyDetails = try JSONDecoder().decode([SubmittedSurvey].self, from: submittedSurveyData)
            
            let surveyListResponse = try JSONDecoder().decode(SurveyListResponse.self, from: data)
            guard var surveyToValidate = surveyListResponse.result.first else {
                return
            }
            surveyToValidate.survey_settings?.resurvey_option = true
            surveyToValidate.survey_settings?.retake_survey?.retake_input_value = 2
            surveyToValidate.survey_settings?.retake_survey?.retake_select_value = "days"
            
            let timeIntervalBefore2Days = Int(Date().timeIntervalSince1970) - 172775
            var firstSubmiited = submittedSurveyDetails.first!
            firstSubmiited.submissionTime = timeIntervalBefore2Days
            
            let surveyManager = OFSurveyManager()
            let projectDetails = MockProjectDetailsController()
            projectDetails.currentLoggedUserID = "iOS_user_2"
            surveyManager.projectDetailsController = projectDetails
            surveyManager.submittedSurveyDetails = [firstSubmiited]
            let result = surveyManager.validateTheSurvey(surveyToValidate)
            XCTAssertFalse(result, "Survey should be not validated")
        } catch {
            
        }
    }

    func testRecordNewEvent_ifSurveyIsNotLoaded_ShouldBeStoredInTemporaryArray() {
        let surveyManager = OFSurveyManager()
        surveyManager.temporaryEventArray = [EventStore]()
        surveyManager.newEventRecorded("event_name")
        XCTAssertEqual(surveyManager.temporaryEventArray?.count, 1)
    }

    func testRecordNewEvent_ifSurveyIsLoaded_ShouldNotBeStoredInTemporaryArray() {
        let surveyManager = OFSurveyManager()
        guard let data = MockResponseProvider.getDataForSurveyResponse() else {
            return
        }
        
        do {
            let surveyListResponse = try JSONDecoder().decode(SurveyListResponse.self, from: data)
            surveyManager.surveyList = surveyListResponse
            surveyManager.temporaryEventArray = [EventStore]()
            surveyManager.newEventRecorded("event_name")
            XCTAssertEqual(surveyManager.temporaryEventArray?.count, 0)
        } catch {
            
        }
    }

    func testAfterSurveyFetch_SurveyLoadForExistingEventCalled() {
        class NewSurveyManager: OFSurveyManager {
            var isAfterSurveyCalled = false
            override func checkAfterSurveyLoadForExistingEvents() {
                isAfterSurveyCalled = true
            }
        }
        guard let data = MockResponseProvider.getDataForSurveyResponse() else {
            return
        }
        
        let sut = NewSurveyManager()
        sut.isNetworkReachable = true
        let mockAPIController = MockAPIController()
        mockAPIController.dataToRespond = data
        sut.apiController = mockAPIController
        sut.configureSurveys()
        XCTAssertTrue(sut.isAfterSurveyCalled, "It should call after survey load existing event method")
    }

    func testAfterSurveyFetch_SurveyLoadForExistingEvent_ShouldStartSurveyIfEventFound() {
        
        class NewSurveyManager: OFSurveyManager {
            let expectation: XCTestExpectation!
            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }
            override func startSurvey(_ survey: SurveyListResponse.Survey, eventName: String) {
                expectation.fulfill()
            }
        }
        guard let data = MockResponseProvider.getDataForSurveyResponse() else {
            return
        }
        
        let expectation = XCTestExpectation(description: "should call start survey if event is already reacorded")
        let sut = NewSurveyManager(expectation: expectation)
        sut.newEventRecorded("Trigger_event")
        sut.isNetworkReachable = true
        let mockAPIController = MockAPIController()
        mockAPIController.dataToRespond = data
        sut.apiController = mockAPIController
        sut.configureSurveys()
        let result = XCTWaiter.wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(result, .completed, "it should call start survey")
    }

    func testAfterSurveyFetch_SurveyLoadForExistingEvent_ShouldNotStartSurveyIfEventNotFound() {
        
        class NewSurveyManager: OFSurveyManager {
            let expectation: XCTestExpectation!
            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }
            override func startSurvey(_ survey: SurveyListResponse.Survey, eventName: String) {
                expectation.fulfill()
            }
        }
        guard let data = MockResponseProvider.getDataForSurveyResponse() else {
            return
        }
        
        let expectation = XCTestExpectation(description: "should call not call start survey if event not reacorded")
        expectation.isInverted = true
        let sut = NewSurveyManager(expectation: expectation)
        sut.newEventRecorded("abc")
        sut.isNetworkReachable = true
        let mockAPIController = MockAPIController()
        mockAPIController.dataToRespond = data
        sut.apiController = mockAPIController
        sut.configureSurveys()
        let result = XCTWaiter().wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(result, .completed, "Expected")
    }
}
