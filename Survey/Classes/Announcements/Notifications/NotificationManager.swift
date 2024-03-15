//
//  NotificationManager.swift
//  1Flow-SurveySDK
//
//  Created by Rohan Moradiya on 14/02/24.
//

import Foundation

public class NotificationManager: NSObject {
    static let shared = NotificationManager()
    let keyDelivered = "DeliveredAnnouncements"
    let keyClicked = "ClickedAnnouncements"
    var delegate: OneFlowNotificationDelegate?
    
    var deliveredAnnouncements = [String]() {
        didSet {
            print("Update deliveredAnnouncements")
            UserDefaults.standard.set(deliveredAnnouncements, forKey: keyDelivered)
        }
    }

    var clickedAnnouncements = [String]() {
        didSet {
            print("Update clickedAnnouncements")
            UserDefaults.standard.set(clickedAnnouncements, forKey: keyClicked)
        }
    }
    
    private override init() {
        if let array = UserDefaults.standard.value(forKey: keyDelivered) as? [String] {
            deliveredAnnouncements = array
        }
        if let array = UserDefaults.standard.value(forKey: keyClicked) as? [String] {
            clickedAnnouncements = array
        }
    }

    func willPresentNotification(_ userInfo: [AnyHashable : Any]?) {
        OneFlowLog.writeLog("OneFlow: didReceiveRemoteNotification \(String(describing: userInfo))")
        guard
            let aps = userInfo?["aps"] as? [String: Any],
            let alert = aps["alert"] as? [String: Any],
            let announcementID = alert["announcement_id"] as? String
        else {
            return
        }
        sendNotificationDeliveredEvent(announcementID)
    }

    func checkCurrentPermission() {
        let current = UNUserNotificationCenter.current()
        current.getNotificationSettings(completionHandler: { permission in
            switch permission.authorizationStatus  {
            case .authorized:
                print("User granted permission for notification")
            case .denied:
                print("User denied notification permission")
            case .notDetermined:
                print("Notification permission haven't been asked yet")
            case .provisional:
                // @available(iOS 12.0, *)
                print("The application is authorized to post non-interruptive user notifications.")
            case .ephemeral:
                // @available(iOS 14.0, *)
                print("The application is temporarily authorized to post notifications. Only available to app clips.")
            default:
                print("Unknow Status")
            }
        })
    }

    func didReceivedResponse(_  userInfo: [AnyHashable : Any]?) {
        OneFlowLog.writeLog("OneFlow: didReceiveRemoteNotification \(String(describing: userInfo))")
        guard
            let aps = userInfo?["aps"] as? [String: Any],
            let alert = aps["alert"] as? [String: Any],
            let announcementID = alert["announcement_id"] as? String
        else {
            return
        }
        sendNotificationClickEvent(announcementID)
        performActionFromNotification(alert)
    }

    func didLaunchedWith(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard
            let launchOptions,
            let apns = launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] as? [String: Any],
            let alert = apns["alert"] as? [String: Any],
            let announcementID = alert["announcement_id"] as? String
        else {
            return
        }
        sendNotificationClickEvent(announcementID)
        performActionFromNotification(alert)
    }

    func didSubscribedToNotification(_ token: String?) {
        guard let token else {
            OneFlow.recordEventName("notification_unsubscribed", parameters: ["token": token])
            return
        }
        OneFlow.recordEventName("notification_subscribed", parameters: ["token": token])
    }

    private func checkForDeliveredNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            for notification in notifications {
                print("Delivered notification: \(notification.request.content.userInfo)")
                guard
                    let aps = notification.request.content.userInfo["aps"] as? [String: Any],
                    let alert = aps["alert"] as? [String: Any],
                    let announcementID = alert["announcement_id"] as? String
                else {
                    continue
                }
                self.sendNotificationDeliveredEvent(announcementID)
            }
        }
    }

    private func performActionFromNotification(_ details: [String: Any]) {
        guard
            let link = details["link"] as? String,
            let url = URL(string: link)
        else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func sendNotificationDeliveredEvent(_ announcementID: String) {
        if !deliveredAnnouncements.contains(where: { $0 == announcementID }) {
            deliveredAnnouncements.append(announcementID)
            // send event
            OneFlow.recordEventName("notification_delivered", parameters: ["announcement_id": announcementID])
        }
    }

    private func sendNotificationClickEvent(_ announcementID: String) {
        if !clickedAnnouncements.contains(where: { $0 == announcementID }) {
            clickedAnnouncements.append(announcementID)
            // send event
            OneFlow.recordEventName("notification_clicked", parameters: ["announcement_id": announcementID])
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Notification token: ", token)
        OneFlow.pushToken = token
    }

    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: ", error)
        OneFlow.pushToken = nil
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("userNotificationCenter willPresent: \(userInfo)")
        OneFlow.appWillPresentRemoteNotification(userInfo)
        guard let delegate = delegate else {
            if #available(iOS 14.0, *) {
                completionHandler(.banner)
            } else {
                completionHandler(.alert)
            }
            return
        }
        delegate.oneFlowNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("userNotificationCenter didReceive response: \(userInfo)")
        OneFlow.appDidReceiveResponseForRemoteNotification(userInfo)
        guard let delegate = delegate else {
            completionHandler()
            return
        }
        delegate.oneFlowNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
}

extension NotificationManager {

    func registerPushNotification(option: UNAuthorizationOptions) {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: option, completionHandler: {(granted, error) in
            if (granted)
            {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        })
    }

    @objc dynamic func _swizzled_application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Notification Token: \(token)")
        OFProjectDetailsController.shared.pushToken = token
        delegate?.oneFlowDidGeneratePushToken(token)
    }

    @objc func _swizzled_application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: ", error)
        OFProjectDetailsController.shared.pushToken = nil
        delegate?.oneFlowDidFailedToGeneratePushToken(error)
    }

    func setupNotifications(for options: UNAuthorizationOptions, fromClass: AnyClass, delegate: OneFlowNotificationDelegate?) {
        self.delegate = delegate
        let selector1 = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        let selector2 = #selector(NotificationManager._swizzled_application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        
        let originalMethod1 = class_getInstanceMethod(fromClass.self, selector1)!
        let swizzleMethod1 = class_getInstanceMethod(NotificationManager.self, selector2)!
        method_exchangeImplementations(originalMethod1, swizzleMethod1)

        let selector3 = #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:))
        let selector4 = #selector(NotificationManager._swizzled_application(_:didFailToRegisterForRemoteNotificationsWithError:))
        
        let originalMethod2 = class_getInstanceMethod(fromClass.self, selector3)!
        let swizzleMethod2 = class_getInstanceMethod(NotificationManager.self, selector4)!
        method_exchangeImplementations(originalMethod2, swizzleMethod2)

        registerPushNotification(option: options)
    }
}
