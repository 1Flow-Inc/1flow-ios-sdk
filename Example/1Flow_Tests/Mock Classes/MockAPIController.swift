//
//  MockAPIController.swift
//  1Flow_Tests
//
//  Created by Rohan Moradiya on 30/04/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//
@testable import _1Flow
@testable import _Flow_Example
import Foundation

final class MockAPIController: APIProtocol {

    var isAddUserCalled = false
    var dataToRespond: Data?
    
    func getAllSurveys(_ completion: @escaping APICompletionBlock) {
        completion(true, nil, dataToRespond)
    }
    
    func submitSurveyResponse(_ response: SurveySubmitRequest, completion: @escaping APICompletionBlock) {
        
    }
    
    func addUser(_ parameter: AddUserRequest, completion: @escaping APICompletionBlock) {
        isAddUserCalled = true
        completion(true, nil, dataToRespond)
    }
    
    func logUser(_ parameter: [String : Any], completion: @escaping APICompletionBlock) {
        
    }
    
    func createSession(_ parameter: CreateSessionRequest, completion: @escaping APICompletionBlock) {
        
    }
    
    func addEvents(_ parameter: [String : Any], completion: @escaping APICompletionBlock) {
        
    }

    func fetchSurvey(_ flowID: String, completion: @escaping APICompletionBlock) {
        completion(true, nil, dataToRespond)
    }
    
}
