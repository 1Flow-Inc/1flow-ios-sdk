//
//  APIController.swift
//  Feedback
//
//  Created by Rohan Moradiya on 12/07/21.
//

import Foundation

typealias APICompletionBlock = ((Bool, Error?, Data?) -> Void)
final class FBAPIController: NSObject {

    let kURLGetSurvey = "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/survey/incoming_webhook/get-surveys?mode=\(ProjectDetailsController.shared.currentEnviromment.rawValue)&platform=iOS"

    let kURLSubmitSurvey = "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/survey/incoming_webhook/add_survey_response"

    let kURLAddUser = "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/project-analytics-user/incoming_webhook/add-user"

    let kURLCreateSession = "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/sessions/incoming_webhook/add_sessions"

    let kURLAddEvents = "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/events-bulk/incoming_webhook/insert-events"

    let kURLLogUser = "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/Log-user/incoming_webhook/anonymous-user-api"
    
    
    //MARK: - Surveys
    func getAllSurveys(_ completion: @escaping APICompletionBlock) {
        self.getAPIWith(kURLGetSurvey, completion: completion)
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
        if let appKey = ProjectDetailsController.shared.appKey {
            request.addValue(appKey, forHTTPHeaderField: "one_flow_key")
        }
        OneFlowLog("API Call: \(urlString)")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                OneFlowLog("API Call: \(urlString) - Failed")
                completion(false, error, nil)
                return
            }
            
            OneFlowLog("API Call: \(urlString) - Success")
            completion(true, nil, data)
            
        }.resume()
    }
    
    private func postAPIWith(_ urlString: String, parameters: Data, completion: @escaping APICompletionBlock) {
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.httpBody = parameters
        if let appKey = ProjectDetailsController.shared.appKey {
            request.addValue(appKey, forHTTPHeaderField: "one_flow_key")
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        OneFlowLog("API Call: \(urlString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                OneFlowLog("API Call: \(urlString) - Failed")
                completion(false, error, nil)
                return
            }
            OneFlowLog("API Call: \(urlString) - Success")
            do {
                if let data = data {
                    if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                        OneFlowLog(json)
                    }
                }
            } catch {
                OneFlowLog("API Call: \(urlString) - JSONParser Failed: \(error.localizedDescription)")
            }
            
            completion(true, nil, data)
            
        }.resume()
    }
}

extension FBAPIController: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//        FBLogs("Task finish with error: \(error as Any)")
        if error == nil {
            if let backgroundID = UserDefaults.standard.value(forKey: "BackgroundSessionId") as? String, session.configuration.identifier == backgroundID {
            //If there is no errors then uploading is successfull. Remove all pending events.
            UserDefaults.standard.removeObject(forKey: "FBPendingEventsList")
                OneFlowLog("File uploaded. Removed pending events")
            }
        }
    }
}
