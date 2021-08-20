//
//  APIController.swift
//  Feedback
//
//  Created by Rohan Moradiya on 12/07/21.
//

import Foundation

typealias APICompletionBlock = ((Bool, Error?, Data?) -> Void)
class FBAPIController: NSObject {
    
    private let kBaseURL = "https://1flow.app/api/"
    private let v1 = "v1/"
    
    private lazy var kURLGetLocation = kBaseURL + v1 + "2021-06-15/location"
    private lazy var kURLGetSurvey = kBaseURL + v1 + "2021-06-15/survey/"
    private lazy var kURLSubmitSurvey = kBaseURL + v1 + "2021-06-15/survey-response"
    private lazy var kURLAddUser = kBaseURL + v1 + "2021-06-15/project_users"
    private lazy var kURLCreateSession = kBaseURL + v1 + "2021-06-15/sessions"
    private lazy var kURLAddEvents = kBaseURL + v1 + "2021-06-15/events/bulk"
    private lazy var kURLUploadFile = kBaseURL + v1 + "2021-06-15/json"
    
    //MARK: - Surveys
    func getAllSurveys(_ completion: @escaping APICompletionBlock) {
        
//        let bundle = Bundle(for: self.classForCoder)
//        let filePath = bundle.path(forResource: "surveyResponse", ofType: "json")!
//        let data = try? Data(contentsOf: URL(fileURLWithPath: filePath))
//        completion(true, nil, data)
        
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
    
    //MARK: - Analytics
    
    func getLocationDetailsUsingIP(_ completion: @escaping APICompletionBlock) {
        self.getAPIWith(kURLGetLocation, shouldAddHeader: false, completion: completion)
    }
    
    func addUser(_ parameter: AddUserRequest, completion: @escaping APICompletionBlock) {
        do {
            let jsonData = try JSONEncoder().encode(parameter)
            self.postAPIWith(kURLAddUser, parameters: jsonData, completion: completion)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
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
        FBLogs("uploadAllPendingEvents called")
        if let eventsArray = UserDefaults.standard.value(forKey: "FBPendingEventsList") as? [[String: Any]], eventsArray.count > 0 {
            FBLogs("Calling upload api")
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
        
        FBLogs("Upload file called")
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
        
        FBLogs("file written on url: \(fileURL)")
        var outputRequest = URLRequest(url: URL(string: kURLUploadFile)!)
        outputRequest.httpMethod = "POST"
        let contentType = "multipart/form-data; boundary=\(boundary)"
        outputRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        upload(request: outputRequest, fileURL: fileURL)
    }
    
    
    
    func upload(request: URLRequest, fileURL: URL) {
        FBLogs("Upload request called")
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
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error, nil)
                return
            }
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
        
        FBLogs("Calling URL: \(urlString)")
        
        let sendingJson = try? JSONSerialization.jsonObject(with: parameters, options: [])
            if let sendingJson = sendingJson as? [String: Any] {
                FBLogs("Sending parameters: \(sendingJson)")
            }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error, nil)
                return
            }
            completion(true, nil, data)
            
        }.resume()
    }
}

extension FBAPIController: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        FBLogs("Task finish with error: \(error as Any)")
        if error == nil {
            if let backgroundID = UserDefaults.standard.value(forKey: "BackgroundSessionId") as? String, session.configuration.identifier == backgroundID {
            //If there is no errors then uploading is successfull. Remove all pending events.
            UserDefaults.standard.removeObject(forKey: "FBPendingEventsList")
                FBLogs("File uploaded. Removed pending events")
            }
        }
    }
}
