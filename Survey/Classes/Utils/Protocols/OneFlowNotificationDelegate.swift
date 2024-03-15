//
//  OneFlowNotificationDelegate.swift
//  1Flow-SurveySDK
//
//  Created by Rohan Moradiya on 11/03/24.
//

import Foundation

@objc 
public protocol OneFlowNotificationDelegate: AnyObject {
    func oneFlowDidGeneratePushToken(_ pushToken: String)
    func oneFlowDidFailedToGeneratePushToken(_ error: Error)

    func oneFlowNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)

    func oneFlowNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
}

extension OneFlowNotificationDelegate {
    func oneFlowNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler(.noData)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler(.banner)
        } else {
            completionHandler(.alert)
        }
    }
}
