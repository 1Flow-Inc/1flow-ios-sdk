//
//  APIController.swift
//  Feedback
//
//  Created by Rohan Moradiya on 12/07/21.
//

import Foundation

typealias APICompletionBlock = ((Bool, Error?, Data?) -> Void)
final class FBAPIController: NSObject {
    
    private var kBaseURL: String {
        get {
           return "https://api.1flow.app/"
        }
    }
    
    private let v1 = "v1/"
    private lazy var kURLGetLocation = kBaseURL + v1 + "2021-06-15/location"
    private lazy var kURLGetSurvey = kBaseURL + v1 + "2021-06-15/survey?platform=iOS"
    private lazy var kURLSubmitSurvey = kBaseURL + v1 + "2021-06-15/survey-response"
    private lazy var kURLAddUser = kBaseURL + v1 + "2021-06-15/project_users"
    private lazy var kURLCreateSession = kBaseURL + v1 + "2021-06-15/sessions"
    private lazy var kURLUploadFile = kBaseURL + v1 + "2021-06-15/json"
    private lazy var kURLAddEvents = "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/events-bulk/incoming_webhook/insert-events"
    private lazy var kURLLogUser = kBaseURL + v1 + "2021-06-15/project_users/log_user"
    
    
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
    
    func getLocationDetailsUsingIP(_ completion: @escaping APICompletionBlock) {
        self.getAPIWith(kURLGetLocation, shouldAddHeader: false, completion: completion)
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
    
    //MARK: - While application inactivates upload all events
    
    func uploadAllPendingEvents() {
        if let eventsArray = UserDefaults.standard.value(forKey: "FBPendingEventsList") as? [[String: Any]], eventsArray.count > 0 {
            do {
                let finalDic = ["events": eventsArray, "session_id": ProjectDetailsController.shared.analytics_session_id as Any]
                let jsonData = try JSONSerialization.data(withJSONObject: finalDic, options: .prettyPrinted)
                self.uploadFile(jsonData)
                
            } catch {
                fatalError(error.localizedDescription)
            }
            
        }
    }
    
    func uploadFile(_ data: Data) {
        let uuid = NSUUID().uuidString
        let boundary = String(repeating: "-", count: 24) + uuid
        let directoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let partFilename = "events_" + ProjectDetailsController.shared.analytic_user_id! + ".json"
        let fileURL = directoryURL.appendingPathComponent(uuid)
        let filePath = fileURL.path
        FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
        let file = FileHandle(forWritingAtPath: filePath)!
        
        let newline = "\r\n"
        let partName = "file"
        let partMimeType = "application/json"
        var header = ""
        header += "--\(boundary)" + newline
        header += "Content-Disposition: form-data; name=\"\(partName)\"; filename=\"\(partFilename)\"" + newline
        header += "Content-Type: \(partMimeType)" + newline
        header += newline
        let headerData = header.data(using: String.Encoding.utf8, allowLossyConversion: false)
        // Write data
        file.write(headerData!)
        file.write(data)
        
        var footer = ""
        footer += newline
        footer += "--\(boundary)--" + newline
        footer += newline
        
        let footerData = footer.data(using: String.Encoding.utf8, allowLossyConversion: false)
        file.write(footerData!)
        file.closeFile()
        var outputRequest = URLRequest(url: URL(string: kURLUploadFile)!)
        outputRequest.httpMethod = "POST"
        let contentType = "multipart/form-data; boundary=\(boundary)"
        outputRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        upload(request: outputRequest, fileURL: fileURL)
    }
    
    
    
    func upload(request: URLRequest, fileURL: URL) {
        // Create a unique identifier for the session.
        let sessionIdentifier = NSUUID().uuidString
        UserDefaults.standard.setValue(sessionIdentifier, forKey: "BackgroundSessionId")
        let configuration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        configuration.sessionSendsLaunchEvents = false
        let session: URLSession = URLSession(
            configuration:configuration,
            delegate: self,
            delegateQueue: OperationQueue.main
        )
        let task = session.uploadTask(with: request, fromFile: fileURL)
        task.resume()
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
            

//            do {
//                if let data = data {
//                    if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
//                        OneFlowLog(json)
//                    }
//                }
//            } catch {
//                OneFlowLog("API Call: \(urlString) - JSONParser Failed: \(error.localizedDescription)")
//            }
            
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
//        do {
//            if let json = try JSONSerialization.jsonObject(with: parameters, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
//                OneFlowLog("Request: \(json)")
//            }
//        } catch {
//
//        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                OneFlowLog("API Call: \(urlString) - Failed")
                completion(false, error, nil)
                return
            }
            OneFlowLog("API Call: \(urlString) - Success")
//            do {
//                if let data = data {
//                    if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
//                        OneFlowLog(json)
//                    }
//                }
//            } catch {
//                OneFlowLog("API Call: \(urlString) - JSONParser Failed: \(error.localizedDescription)")
//            }
            
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
