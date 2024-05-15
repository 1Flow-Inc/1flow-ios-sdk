//
//  OneFlowObserver.swift
//  1Flow-SurveySDK
//
//  Created by Rohan Moradiya on 11/03/24.
//

import Foundation
import UserNotifications

/// get call back when SDK configuration failed and succeeded
@objc 
public protocol OneFlowObserver {
    func oneFlowSetupDidFinish()
    func oneFlowSetupDidFail()
}

extension OneFlowObserver {

    func oneFlowSetupDidFinish() {
    }
    func oneFlowSetupDidFail() {
    }
}

