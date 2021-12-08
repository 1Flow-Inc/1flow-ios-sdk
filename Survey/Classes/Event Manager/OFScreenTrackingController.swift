//
//  OFScreenTrackingController.swift
//  Feedback
//
//  Created by Rohan Moradiya on 26/07/21.
//

import Foundation
import UIKit

final class OFScreenTrackingController: NSObject {
    
    var currentNavigationController: UINavigationController?
    var currentViewController: UIViewController?
    var currentTabbarController: UITabBarController?
    
    func startTacking() {
//        let navigationController: UINavigationController

        OneFlowLog("startTacking")
        DispatchQueue.main.async {
            self.getCurrentViewController()
        }
        
        
    }
    
    func getCurrentViewController() {
        OneFlowLog("getCurrentViewController")
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
        OneFlowLog("navifation bar observer started")
        
        NotificationCenter.default.addObserver(self, selector: #selector(navigationViewControllerChange(_:)), name: NSNotification.Name(rawValue: "UINavigationControllerWillShowViewControllerNotification"), object: self.currentNavigationController)
    }
    
    @objc func navigationViewControllerChange(_ notification: Notification) {
        OneFlowLog("viewControllerChange")
        if let userInfo = notification.userInfo as? [String: Any] {
            let previous = userInfo["UINavigationControllerLastVisibleViewController"]
            let new = userInfo["UINavigationControllerNextVisibleViewController"]
            
            OneFlowLog("Previous: \(previous as Any)")
            OneFlowLog("current: \(new as Any)")
        }
    }
}
