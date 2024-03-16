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
    func oneFlowDidGeneratePushToken(_ pushToken: String)
    func oneFlowDidFailedToGeneratePushToken(_ error: Error)

    func oneFlowNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)

    func oneFlowNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
}

extension OneFlowObserver {

    func oneFlowSetupDidFinish() {
    }

    func oneFlowSetupDidFail() {
    }

    func oneFlowNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler(.banner)
        } else {
            completionHandler(.alert)
        }
    }
}
