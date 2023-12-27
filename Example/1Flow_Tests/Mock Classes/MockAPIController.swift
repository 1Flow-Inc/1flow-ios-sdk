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

    func fetchUpdatedValidationScript(_ completion: @escaping APICompletionBlock) {
        completion(true, nil, dataToRespond)
    }

    func getAnnouncements(_ completion: @escaping _1Flow.APICompletionBlock) {
        completion(true, nil, dataToRespond)
    }

    func getAnnouncementsDetails(_ ids: String, completion: @escaping APICompletionBlock) {
        completion(true, nil, dataToRespond)
    }
}
