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

let kPrimaryButtonEnableColor = UIColor(red: 0.18, green: 0.31, blue: 1.0, alpha: 1.0)
let kPrimaryButtonDisableColor = UIColor(red: 0.18, green: 0.31, blue: 1.0, alpha: 0.25)
let kDoneButtonColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)


let kEventNameFirstAppOpen = "first_open"
let kEventNameAppUpdate = "app_updated"
let kEventNameSessionStart = "session_start"
let kEventNameInAppPurchase = "in_app_purchase"
