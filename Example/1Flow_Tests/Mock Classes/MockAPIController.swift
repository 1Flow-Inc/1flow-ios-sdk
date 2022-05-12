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
    func getAllSurveys(_ completion: @escaping APICompletionBlock) {
        
    }
    
    func submitSurveyResponse(_ response: SurveySubmitRequest, completion: @escaping APICompletionBlock) {
        
    }
    
    func addUser(_ parameter: AddUserRequest, completion: @escaping APICompletionBlock) {
        isAddUserCalled = true
    }
    
    func logUser(_ parameter: [String : Any], completion: @escaping APICompletionBlock) {
        
    }
    
    func createSession(_ parameter: CreateSessionRequest, completion: @escaping APICompletionBlock) {
        
    }
    
    func addEvents(_ parameter: [String : Any], completion: @escaping APICompletionBlock) {
        
    }
    
    
}
