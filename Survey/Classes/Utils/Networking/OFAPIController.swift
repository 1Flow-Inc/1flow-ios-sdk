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

import Foundation

typealias APICompletionBlock = ((Bool, Error?, Data?) -> Void)

protocol APIProtocol {
    func getAllSurveys(_ completion: @escaping APICompletionBlock)
    func submitSurveyResponse(_ response: SurveySubmitRequest, completion: @escaping APICompletionBlock)
    func addUser(_ parameter: AddUserRequest, completion: @escaping APICompletionBlock)
    func logUser(_ parameter: [String: Any], completion: @escaping APICompletionBlock)
    func createSession(_ parameter: CreateSessionRequest, completion: @escaping APICompletionBlock)
    func addEvents(_ parameter: [String: Any], completion: @escaping APICompletionBlock)
}

final class OFAPIController: NSObject, APIProtocol {
    var urlRequestManager: URLRequestManagerProtocol = URLRequestManager()

    //MARK: - Surveys
    func getAllSurveys(_ completion: @escaping APICompletionBlock) {
        urlRequestManager.getAPIWith(EndPoints.getSurveys, completion: completion)
    }
    
    func submitSurveyResponse(_ response: SurveySubmitRequest, completion: @escaping APICompletionBlock) {
        do {
            let jsonData = try JSONEncoder().encode(response)
            urlRequestManager.postAPIWith(EndPoints.submitSurvey, parameters: jsonData, completion: completion)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    //MARK: - User
    func addUser(_ parameter: AddUserRequest, completion: @escaping APICompletionBlock) {
        do {
            let jsonData = try JSONEncoder().encode(parameter)
            urlRequestManager.postAPIWith(EndPoints.addUser, parameters: jsonData, completion: completion)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func logUser(_ parameter: [String: Any], completion: @escaping APICompletionBlock) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameter, options: .prettyPrinted)
            urlRequestManager.postAPIWith(EndPoints.logUser, parameters: jsonData, completion: completion)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    //MARK: - Analytics
    func createSession(_ parameter: CreateSessionRequest, completion: @escaping APICompletionBlock) {
        do {
            let jsonData = try JSONEncoder().encode(parameter)
            urlRequestManager.postAPIWith(EndPoints.createSession, parameters: jsonData, completion: completion)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func addEvents(_ parameter: [String: Any], completion: @escaping APICompletionBlock) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameter, options: .prettyPrinted)
            urlRequestManager.postAPIWith(EndPoints.addEvent, parameters: jsonData, completion: completion)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func getAppStoreDetails(_ completion: @escaping APICompletionBlock) {
        urlRequestManager.getAPIWith(EndPoints.appStoreRating, completion: completion)
    }
}
