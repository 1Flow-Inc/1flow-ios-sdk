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

import UIKit
import _1Flow

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let kOneProjectKey = "YOUR_1FLOW_PROJECT_KEY"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        setupOneFlow()
        NotificationCenter.default.addObserver(self, selector: #selector(surveyDidFinished(notification:)), name: SurveyFinishNotification, object: nil)
        OneFlow.appDidLaunchedWith(launchOptions)
        return true
    }
     
    @objc func surveyDidFinished(notification: Notification) {
        
        if let userInfo = notification.userInfo {
            print("Notification userInfo: \(userInfo)")
        }
    }

    func setupOneFlow() {
        OneFlow.observer = self
        OneFlow.configure(kOneProjectKey)
        OneFlow.useFont(fontFamily: "Avenir Next")
        OneFlow.setupAnnouncementPushNotification([.alert, .badge, .sound], fromClass: AppDelegate.self)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("In app delegate: didRegisterForRemoteNotificationsWithDeviceToken")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("In app delegate: didFailToRegisterForRemoteNotificationsWithError")
    }
}

extension AppDelegate: OneFlowObserver {
    func oneFlowDidGeneratePushToken(_ pushToken: String) {
        print("App delegate oneflow call back: \(pushToken)")
    }
    
    func oneFlowDidFailedToGeneratePushToken(_ error: Error) {
        print("App delegate oneflow call back oneFlowDidFailedToGeneratePushToken: \(error)")
    }
    
    func oneFlowNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func oneFlowNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler(.banner)
        } else {
            // Fallback on earlier versions
            completionHandler(.alert)
        }
    }
    
    func oneFlowSetupDidFail() {
        print("OneFlow did failed setup")
    }

    func oneFlowSetupDidFinish() {
        print("OneFlow did finish setup")
    }
}

