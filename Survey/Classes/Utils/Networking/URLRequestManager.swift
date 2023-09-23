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
        URLSession.shared.dataTask(with: request) { data, _, error in
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

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                OneFlowLog.writeLog("API Call: \(endPoint.url) - Failed: \(error.localizedDescription)", .error)
                completion(false, error, nil)
                return
            }
            do {
                if let data = data {
                    if let json = try JSONSerialization.jsonObject(
                        with: data,
                        options: JSONSerialization.ReadingOptions.fragmentsAllowed
                    ) as? [String: Any] {
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
