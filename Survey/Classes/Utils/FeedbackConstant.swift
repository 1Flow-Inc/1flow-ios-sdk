//
//  FeedbackConstant.swift
//  Feedback
//
//  Created by Rohan Moradiya on 19/06/21.
//

import Foundation
import UIKit

func FBLogs(_ string: Any) {
    #if DEBUG
        print(string)
    #endif
}

var kPrimaryColor = UIColor(red: 0.36, green: 0.37, blue: 0.93, alpha: 1.0)
let kPrimaryHightlightColor = kPrimaryColor.withAlphaComponent(0.21)
let kBorderColor = UIColor(red: 0.76, green: 0.76, blue: 0.76, alpha: 1.0)

let kEventNameFirstAppOpen = "first_open"
let kEventNameAppUpdate = "app_updated"
let kEventNameSessionStart = "session_start"
let kEventNameInAppPurchase = "in_app_purchase"
let kEventNameSurveyImpression = "survey_impression"
