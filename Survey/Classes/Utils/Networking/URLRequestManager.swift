//
//  URLRequestManager.swift
//  1Flow
//
//  Created by Rohan Moradiya on 30/04/22.
//

import Foundation

protocol URLRequestManagerProtocol {
    func getAPIWith(_ endPoint: EndPoints, completion: @escaping APICompletionBlock)
    func postAPIWith(_ endPoint: EndPoints, parameters: Data, completion: @escaping APICompletionBlock)
}

class URLRequestManager: URLRequestManagerProtocol {

    func getAPIWith(_ endPoint: EndPoints, completion: @escaping APICompletionBlock) {
        var request = URLRequest(url: URL(string: endPoint.url)!)
        request.httpMethod = "GET"
        if let appKey = OFProjectDetailsController.shared.appKey {
            request.addValue(appKey, forHTTPHeaderField: "one_flow_key")
        }
        OneFlowLog.writeLog("API Call: \(endPoint.url)")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                OneFlowLog.writeLog("API Call: \(endPoint.url) - Failed: \(error.localizedDescription)", .error)
                completion(false, error, nil)
                return
            }
            if let data = data {
                if let JSONString = String(data: data, encoding: String.Encoding.utf8) {
                    OneFlowLog.writeLog(JSONString, .verbose)
                }
            }
            completion(true, nil, data)
            
        }.resume()
    }
    
    func postAPIWith(_ endPoint: EndPoints, parameters: Data, completion: @escaping APICompletionBlock) {
        var request = URLRequest(url: URL(string: endPoint.url)!)
        request.httpMethod = "POST"
        request.httpBody = parameters
        if let appKey = OFProjectDetailsController.shared.appKey {
            request.addValue(appKey, forHTTPHeaderField: "one_flow_key")
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        OneFlowLog.writeLog("API Call: \(endPoint.url)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                OneFlowLog.writeLog("API Call: \(endPoint.url) - Failed: \(error.localizedDescription)", .error)
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
                OneFlowLog.writeLog("API Call: \(endPoint.url) - Deconding Error \(error.localizedDescription)", .error)
            }
            completion(true, nil, data)
            
        }.resume()
    }
}
