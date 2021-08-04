//
//  ScreenTrackingController.swift
//  Feedback
//
//  Created by Rohan Moradiya on 26/07/21.
//

import Foundation
import UIKit

class ScreenTrackingController: NSObject {
    
    var currentNavigationController: UINavigationController?
    var currentViewController: UIViewController?
    var currentTabbarController: UITabBarController?
    
    func startTacking() {
//        let navigationController: UINavigationController

        FBLogs("startTacking")
        DispatchQueue.main.async {
            self.getCurrentViewController()
        }
        
        
    }
    
    func getCurrentViewController() {
        FBLogs("getCurrentViewController")
        guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow == true }) else {
            return
        }
        
        if var topController = keyWindow.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            self.setupObserversFromViewCotnroller(topController)
        }
    }
    
    func setupObserversFromViewCotnroller(_ viewController: UIViewController) {
        
        if viewController.isKind(of: UINavigationController.self) {
            let navigationController = viewController as! UINavigationController
            self.startObserverForNavigationController(navigationController)
            
        } else if viewController.isKind(of: UITabBarController.self) {
            //tab bar controller
        } else {
            //view controller
            if let navigationController = viewController.navigationController {
                self.startObserverForNavigationController(navigationController)
            }
            
        }
    }
    
    func startObserverForNavigationController(_ navigationController: UINavigationController) {
        
        if self.currentNavigationController != nil {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UINavigationControllerWillShowViewControllerNotification"), object: self.currentNavigationController)
//            self.currentNavigationController?.removeObserver(self, forKeyPath: "UINavigationControllerWillShowViewControllerNotification")
        }
        
        self.currentNavigationController = navigationController
        FBLogs("navifation bar observer started")
        
        NotificationCenter.default.addObserver(self, selector: #selector(navigationViewControllerChange(_:)), name: NSNotification.Name(rawValue: "UINavigationControllerWillShowViewControllerNotification"), object: self.currentNavigationController)
    }
    
    @objc func navigationViewControllerChange(_ notification: Notification) {
        FBLogs("viewControllerChange")
        if let userInfo = notification.userInfo as? [String: Any] {
            let previous = userInfo["UINavigationControllerLastVisibleViewController"]
            let new = userInfo["UINavigationControllerNextVisibleViewController"]
            
            FBLogs("Previous: \(previous as Any)")
            FBLogs("current: \(new as Any)")
        }
    }
}
