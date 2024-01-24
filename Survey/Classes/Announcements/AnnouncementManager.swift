//
//  AnnouncementManager.swift
//  1Flow
//
//  Created by Rohan Moradiya on 21/10/23.
//

import Foundation
import UIKit

class AnnouncementManager {
    static let shared = AnnouncementManager()
    var inboxWindow: UIWindow?
    var apiController: APIProtocol = OFAPIController.shared
    var announcements: [Announcement]?
    var inAppAnnouncements: [Announcement]?
    var theme: AnnouncementTheme?
    var temporaryEventArray: [EventStore]?
    let myGroupAnnouncement = DispatchGroup()
    private var readAnnouncements = [String]()

    lazy var bannerView: BannerView = {
        BannerView.loadFromNib()
    }()

    private var isFetchingProgress = false
    var isRunning = false

    func loadAnnouncements() {
        if let directory = AnnouncementComponentBuilder.getAnnouncementDirectory() {
            try? FileManager.default.removeItem(at: directory)
        }
        if isFetchingProgress == true, announcements == nil {
            return
        }
        isFetchingProgress = true
        apiController.getAnnouncements {[weak self] isSuccess, error, data in
            guard let self = self else {
                return
            }
            self.isFetchingProgress = false
            guard let data = data else {
                OneFlowLog.writeLog("Error: \(error?.localizedDescription ?? "NA")", .error)
                return
            }
            do {
                let response = try JSONDecoder().decode(AnnouncementsInbox.self, from: data)
                let announcements = response.result?.announcements?.inbox
                self.theme = response.result?.theme
                self.announcements = announcements?.filter({$0.status == "active"})
                guard let inAppAnnouncements = response.result?.announcements?.inApp?.filter( { $0.seen == false }) else {
                    return
                }
                self.inAppAnnouncements = inAppAnnouncements
                SurveyScriptValidator.shared.setupForAnnouncement(with: inAppAnnouncements)
                let queue = DispatchQueue(label: "com.1flow.queue1", attributes: .concurrent)
                queue.async(execute: {
                    self.checkAfterAnnouncementLoadForExistingEvents()
                })
            } catch {
                OneFlowLog.writeLog("Error: \(error.localizedDescription)", .error)
            }
        }
    }

    func checkAfterAnnouncementLoadForExistingEvents() {
        if let eventsArray = self.temporaryEventArray {
            for event in eventsArray {
                myGroupAnnouncement.enter()
                newEventRecorded(event.eventName, parameter: event.parameters, completion: { [weak self] isTriggered in
                    guard let self = self else {
                        return
                    }
                    defer {
                        self.myGroupAnnouncement.leave()
                    }
                    guard isTriggered == false else {
                        OneFlowLog.writeLog("Announcement Triggered. Dont trigger survey")
                        return
                    }
                })
                self.myGroupAnnouncement.wait()
            }
            self.temporaryEventArray = nil
        }
    }

    func showInbox() {
        guard let window = self.getWindow() else {
            return
        }
        self.inboxWindow = window
        let navigationController = UINavigationController(rootViewController: UIViewController())
        self.inboxWindow?.rootViewController = navigationController

        let controller = AnnouncementsInboxViewController(
            nibName: "AnnouncementsInboxViewController",
            bundle: OneFlowBundle.bundleForObject(self)
        )
        controller.announcements = self.announcements
        controller.theme = theme
        controller.uiDelegate = self
        navigationController.navigationBar.isHidden = true
        self.inboxWindow?.makeKeyAndVisible()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: {
            navigationController.pushViewController(controller, animated: true)
        })
    }

    func newEventRecorded(_ eventName: String, parameter: [String: Any]?, completion: @escaping(Bool) -> Void) {
        if isRunning == true {
            completion(true)
            return
        }
        guard let inAppAnnouncements = inAppAnnouncements else {
            if self.temporaryEventArray == nil {
                self.temporaryEventArray = [EventStore]()
            }
            let eventObj = EventStore(
                eventName: eventName,
                timeInterval: Int(Date().timeIntervalSince1970),
                parameters: parameter
            )
            self.temporaryEventArray?.append(eventObj)
            completion(false)
            return
        }
        let filtered = inAppAnnouncements.filter({ !self.readAnnouncements.contains($0.identifier) })
        if filtered.isEmpty {
            completion(false)
            return
        }
        SurveyScriptValidator.shared.setupForAnnouncement(with: filtered)
        var event = ["name": eventName] as [String: Any]
        if let param = parameter {
            event["parameters"] = param
        }
        SurveyScriptValidator.shared.validateAnnouncement(event: event) { [weak self] dic in
            guard let self = self else {
                completion(false)
                return
            }
            guard
                let dic1 = dic?["0"] as? [String: Any],
                let id = dic1["_id"] as? String,
                let inApp = dic1["in_app"] as? [String: Any],
                let style = inApp["style"] as? String
            else {
                OneFlowLog.writeLog("No Announcement returned")
                completion(false)
                return
            }
            completion(true)
            self.fetchAnnouncementDetails(id) { detailsList in
                guard let details = detailsList?.first else {
                    return
                }
                if
                    let timing = inApp["timing"] as? [String: Any],
                    let rule = timing["rule"] as? [String: Any],
                    let timingOption = (rule["filters"] as? [[String: Any]])?.first?["timingOption"] as? [String: Any],
                    let type = timingOption["type"] as? String,
                    type == "show_after",
                    let value = timingOption["value"] as? Int
                {
                    sleep(UInt32(value))
                }
                DispatchQueue.main.async {
                    if style == "banner_top" {
                        self.triggerTopBannerAnnouncement(details)
                    } else if style == "banner_bottom" {
                        self.triggerBottomBannerAnnouncement(details)
                    } else {
                        self.triggerModalAnnouncement(details, style: style)
                    }
                    self.markAnnouncementAsRead(id)
                }
            }
        }
    }

    func fetchAnnouncementDetails(_ announcementID: String, completion: @escaping ([AnnouncementsDetails]?) -> Void) {
        apiController.getAnnouncementsDetails(announcementID) { isSuccess, error, data in
            guard let data = data else {
                OneFlowLog.writeLog("Error: \(error?.localizedDescription ?? "NA")", .error)
                return
            }
            do {
                let response = try JSONDecoder().decode(AnnouncementsResponse.self, from: data)
                OneFlowLog.writeLog(response)
                completion(response.result)
            } catch {
                OneFlowLog.writeLog("Error: \(error.localizedDescription)", .error)
                completion(nil)
            }
        }
    }

    func triggerModalAnnouncement(_ announcementDetails: AnnouncementsDetails, style: String) {
        guard let window = self.getWindow() else {
            return
        }
        self.inboxWindow = window
        let navigationController = UINavigationController(rootViewController: UIViewController())
        self.inboxWindow?.rootViewController = navigationController

        let controller = AnnouncementModalViewController(
            nibName: "AnnouncementModalViewController",
            bundle: OneFlowBundle.bundleForObject(self)
        )
        controller.style = style
        controller.details = announcementDetails
        controller.modalPresentationStyle = .overCurrentContext
        controller.modalTransitionStyle = .crossDissolve
        controller.delegate = self
        controller.theme = theme
        isRunning = true
        navigationController.present(controller, animated: true)
    }

    func triggerTopBannerAnnouncement(_ announcementDetails: AnnouncementsDetails) {
        var window: UIWindow?
        
        if #available(iOS 13.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let keyWindow = windowScene.windows.first else {
                return
            }
            window = keyWindow
        } else {
            guard let keyWindow = UIApplication.shared.keyWindow else {
                return
            }
            window = keyWindow
        }
        guard let window = window else {
            return
        }
        let topInset: CGFloat
        if #available(iOS 11.0, *) {
            topInset = window.safeAreaInsets.top
        } else {
            topInset = 0
        }
        bannerView.type = .top
        bannerView.setupUI(with: announcementDetails, theme: self.theme)
        bannerView.delegate = self
        bannerView.layoutIfNeeded()

        bannerView.frame = CGRect(x: 0, y: -bannerView.frame.height + topInset, width: window.frame.width, height: bannerView.frame.height)
        
        // Add banner view to the window
        window.addSubview(bannerView)
        // Animate banner appearance
        isRunning = true
        UIView.animate(withDuration: 0.5, animations: {
            self.bannerView.frame.origin.y = topInset
        }) { _ in
        }
    }

    func triggerBottomBannerAnnouncement(_ announcementDetails: AnnouncementsDetails) {
        var window: UIWindow?
        
        if #available(iOS 13.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let keyWindow = windowScene.windows.first else {
                return
            }
            window = keyWindow
        } else {
            guard let keyWindow = UIApplication.shared.keyWindow else {
                return
            }
            window = keyWindow
        }
        guard let window = window else {
            return
        }
        let bottomInset: CGFloat
        if #available(iOS 11.0, *) {
            bottomInset = window.safeAreaInsets.bottom
        } else {
            bottomInset = 0
        }
        bannerView.setupUI(with: announcementDetails, theme: self.theme)
        bannerView.type = .bottom
        bannerView.delegate = self
        bannerView.layoutIfNeeded()

        bannerView.frame = CGRect(x: 0, y: bannerView.frame.height + window.frame.maxY, width: window.frame.width, height: bannerView.frame.height)
        
        // Add banner view to the window
        window.addSubview(bannerView)
        // Animate banner appearance
        isRunning = true
        UIView.animate(withDuration: 0.5, animations: {
            self.bannerView.frame.origin.y = window.frame.maxY - bottomInset - self.bannerView.frame.height
        }) { _ in
        }
    }

    private func dismissBanner(type: BannerType) {
        var window: UIWindow?
        if #available(iOS 13.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let keyWindow = windowScene.windows.first else {
                return
            }
            window = keyWindow
        } else {
            guard let keyWindow = UIApplication.shared.keyWindow else {
                return
            }
            window = keyWindow
        }
        guard let window = window else {
            return
        }
        
        let topInset: CGFloat
        if #available(iOS 11.0, *) {
            topInset = window.safeAreaInsets.top
        } else {
            topInset = 0
        }
        UIView.animate(withDuration: 0.5, animations: {
            if type == .top {
                self.bannerView.frame.origin.y = -self.bannerView.frame.height + topInset
            } else {
                self.bannerView.frame.origin.y = window.frame.maxY
            }
        }) { _ in
            self.bannerView.removeFromSuperview()
        }
    }

    private func getWindow() -> UIWindow? {
        var window: UIWindow?
        if #available(iOS 13.0, *) {
            if let currentWindowScene = UIApplication.shared.connectedScenes.first as?  UIWindowScene {
                window = UIWindow(windowScene: currentWindowScene)
            }
            if window == nil {
                if let currentWindowScene = UIApplication.shared.connectedScenes
                    .filter({$0.activationState == .foregroundActive})
                    .compactMap({$0 as? UIWindowScene})
                    .first {
                    window = UIWindow(windowScene: currentWindowScene)
                }
            }
        } else {
            // Fallback on earlier versions
            window = UIWindow(frame: UIScreen.main.bounds)
        }
        window?.isHidden = false
        window?.windowLevel = .normal
        return window
    }

    func markAnnouncementAsRead(_ announcementID: String) {
        readAnnouncements.append(announcementID)
        OneFlow.recordEventName(
            kEventNameAnnouncementViewed,
            parameters: [
                "announcement_id": announcementID,
                "channel": "in-app"
            ]
        )
    }
}
extension AnnouncementManager: AnnoucementsInboxUIDelegate {
    func inboxDidClosed(_ sender: AnnouncementsInboxViewController) {
        if let updated = sender.announcements {
            self.announcements = updated
        }
        DispatchQueue.main.async {
            self.inboxWindow?.isHidden = true
            self.inboxWindow = nil
        }
        isRunning = false
    }
}
extension AnnouncementManager: AnnouncementModalDelegate {
    func announcementModalDidClosed(_ sender: Any) {
        DispatchQueue.main.async {
            self.inboxWindow?.isHidden = true
            self.inboxWindow = nil
        }
        isRunning = false
    }
}

extension AnnouncementManager: BannerDelegate {
    func bannerViewDidTapppedClosed(_ sender: BannerView) {
        dismissBanner(type: sender.type)
        isRunning = false
    }
}
