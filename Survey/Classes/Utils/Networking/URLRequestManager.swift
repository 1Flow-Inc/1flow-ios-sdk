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
                OneFlowLog.writeLog("API Call: \(endPoint.url) - Failed")
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
            OneFlowLog.writeLog("API Call: \(endPoint.url) - Success")
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

        do {
            if let json = try JSONSerialization.jsonObject(with: parameters, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String : Any] {
                OneFlowLog.writeLog("Request Param", .verbose)
                OneFlowLog.writeLog(json, .verbose)
            }
        } catch {
        }

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        OneFlowLog.writeLog("API Call: \(endPoint.url)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                OneFlowLog.writeLog("API Call: \(endPoint.url) - Failed")
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
            OneFlowLog.writeLog("API Call: \(endPoint.url) - Success")
            completion(true, nil, data)
            
        }.resume()
    }
}
