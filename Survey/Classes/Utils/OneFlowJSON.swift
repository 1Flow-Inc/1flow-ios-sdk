//
//  OneFlowJSON.swift
//  1Flow-SurveySDK
//
//  Created by Rohan Moradiya on 11/03/24.
//

import Foundation

class OneFlowJSON {
    
    static func getSerialisedString(_ value: Any) -> Any? {
        if let valueDate = value as? Date {
            let interval = Int(valueDate.timeIntervalSince1970)
            return interval
        } else if let valueUrl = value as? URL {
            return valueUrl.absoluteString
        }
        return nil
    }

    static func removeUnsupportedKeys(_ userDetails: [String: Any]?) ->  [String: Any]? {
        guard var userDetailsDic: [String: Any?] = userDetails else {return nil}
        for (key, value) in userDetailsDic {
            if value == nil {
                userDetailsDic.removeValue(forKey: key)
                continue
            }
            if !JSONSerialization.isValidJSONObject([key: value]) {
                if let dicValue: [String: Any] = value as? [String: Any] {
                    if let newDic: [String: Any] = OneFlowJSON.removeUnsupportedKeys(dicValue) {
                        userDetailsDic.updateValue(newDic, forKey: key)
                    }
                } else if let arrayValue: [Any?] = value as? [Any] {
                    var newArray: [Any?] = []
                    for arrayObj in arrayValue {
                        if arrayObj == nil {
                           continue
                        }
                        if JSONSerialization.isValidJSONObject(["key": arrayObj]) {
                            newArray.append(arrayObj)
                        } else if let newValue = OneFlowJSON.getSerialisedString(arrayObj as Any) {
                            newArray.append(newValue)
                        }
                    }
                    userDetailsDic.updateValue(newArray, forKey: key)
                } else if let newValue = OneFlowJSON.getSerialisedString(value as Any) {
                    userDetailsDic.updateValue(newValue, forKey: key)
                } else {
                    userDetailsDic.removeValue(forKey: key)
                }
            }
        }
        return userDetailsDic as [String: Any]
    }
}
