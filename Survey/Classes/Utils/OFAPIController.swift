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
    func addUser(_ parameter: AddUserRequest, completion: @escaping APICompletionBlock)
}

final class OFAPIController: NSObject, APIProtocol {

    let kURLGetSurvey = "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/survey/incoming_webhook/get-surveys?mode=\(OFProjectDetailsController.shared.currentEnviromment.rawValue)&platform=iOS"
    
    let kURLAppStoreDetails = "http://itunes.apple.com/lookup?bundleId="


    let kURLSubmitSurvey = "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/survey/incoming_webhook/add_survey_response"

    let kURLAddUser = "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/project-analytics-user/incoming_webhook/add-user"

    let kURLCreateSession = "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/sessions/incoming_webhook/add_sessions"

    let kURLAddEvents = "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/events-bulk/incoming_webhook/insert-events"

    let kURLLogUser = "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/Log-user/incoming_webhook/anonymous-user-api"
    
    
    //MARK: - Surveys
    func getAllSurveys(_ completion: @escaping APICompletionBlock) {
        var surveyUrl = kURLGetSurvey
        if let sessionID : String = OFProjectDetailsController.shared.analytics_session_id {
            surveyUrl = surveyUrl + "&session_id=" + sessionID
        }
        
        if let userID : String = OFProjectDetailsController.shared.analytic_user_id {
            surveyUrl = surveyUrl + "&user_id=" + userID
        }
        self.getAPIWith(surveyUrl, completion: completion)
    }
    
    func getAppStoreDetails(_ completion: @escaping APICompletionBlock) {
        if let bundleID : String = Bundle.main.bundleIdentifier {
            let appStoreDetailsUrl = kURLAppStoreDetails + bundleID
            self.getAPIWith(appStoreDetailsUrl, completion: completion)

        }
    }
    
    func submitSurveyResponse(_ response: SurveySubmitRequest, completion: @escaping APICompletionBlock) {
        do {
            let jsonData = try JSONEncoder().encode(response)
            self.postAPIWith(kURLSubmitSurvey, parameters: jsonData, completion: completion)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    //MARK: - User
    func addUser(_ parameter: AddUserRequest, completion: @escaping APICompletionBlock) {
        do {
            let jsonData = try JSONEncoder().encode(parameter)
            self.postAPIWith(kURLAddUser, parameters: jsonData, completion: completion)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func logUser(_ parameter: [String: Any], completion: @escaping APICompletionBlock) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameter, options: .prettyPrinted)
            self.postAPIWith(kURLLogUser, parameters: jsonData, completion: completion)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    //MARK: - Analytics
    
    func createSession(_ parameter: CreateSessionRequest, completion: @escaping APICompletionBlock) {
        do {
            let jsonData = try JSONEncoder().encode(parameter)
            self.postAPIWith(kURLCreateSession, parameters: jsonData, completion: completion)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func addEvents(_ parameter: [String: Any], completion: @escaping APICompletionBlock) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameter, options: .prettyPrinted)
            self.postAPIWith(kURLAddEvents, parameters: jsonData, completion: completion)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    //MARK: - Get and Post
    
    private func getAPIWith(_ urlString: String, shouldAddHeader: Bool = true, completion: @escaping APICompletionBlock) {
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"
        if let appKey = OFProjectDetailsController.shared.appKey {
            request.addValue(appKey, forHTTPHeaderField: "one_flow_key")
        }
        OneFlowLog.writeLog("API Call: \(urlString)")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                OneFlowLog.writeLog("API Call: \(urlString) - Failed")
                completion(false, error, nil)
                return
            }
            do {
                if let data = data {
                    if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                        OneFlowLog.writeLog(json, .verbose)
                    }
                }
            } catch {
            }
            OneFlowLog.writeLog("API Call: \(urlString) - Success")
            completion(true, nil, data)
            
        }.resume()
    }
    
    private func postAPIWith(_ urlString: String, parameters: Data, completion: @escaping APICompletionBlock) {
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.httpBody = parameters
        if let appKey = OFProjectDetailsController.shared.appKey {
            request.addValue(appKey, forHTTPHeaderField: "one_flow_key")
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        OneFlowLog.writeLog("API Call: \(urlString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                OneFlowLog.writeLog("API Call: \(urlString) - Failed")
                completion(false, error, nil)
                return
            }
            do {
                if let data = data {
                    if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                        OneFlowLog.writeLog(json, .verbose)
                    }
                }
            } catch {
            }
            OneFlowLog.writeLog("API Call: \(urlString) - Success")
            completion(true, nil, data)
            
        }.resume()
    }
}

extension OFAPIController: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//        FBLogs("Task finish with error: \(error as Any)")
        if error == nil {
            if let backgroundID = UserDefaults.standard.value(forKey: "BackgroundSessionId") as? String, session.configuration.identifier == backgroundID {
            //If there is no errors then uploading is successfull. Remove all pending events.
            UserDefaults.standard.removeObject(forKey: "FBPendingEventsList")
                OneFlowLog.writeLog("File uploaded. Removed pending events")
            }
        }
    }
}
