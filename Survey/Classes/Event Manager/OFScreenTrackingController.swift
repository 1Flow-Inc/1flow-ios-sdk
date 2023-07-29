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

import Foundation
import UIKit

final class OFScreenTrackingController: NSObject {
    
    var currentNavigationController: UINavigationController?
    var currentViewController: UIViewController?
    var currentTabbarController: UITabBarController?
    
    func startTacking() {
        OneFlowLog.writeLog("startTracking")
        DispatchQueue.main.async {
            self.getCurrentViewController()
        }
    }
    
    func getCurrentViewController() {
        OneFlowLog.writeLog("getCurrentViewController")
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
        if viewController.isKind(of: UINavigationController.self), let navigationController = viewController as? UINavigationController {
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
        }
        
        self.currentNavigationController = navigationController
        OneFlowLog.writeLog("navifation bar observer started")
        
        NotificationCenter.default.addObserver(self, selector: #selector(navigationViewControllerChange(_:)), name: NSNotification.Name(rawValue: "UINavigationControllerWillShowViewControllerNotification"), object: self.currentNavigationController)
    }
    
    @objc func navigationViewControllerChange(_ notification: Notification) {
        OneFlowLog.writeLog("viewControllerChange")
        if let userInfo = notification.userInfo as? [String: Any] {
            let previous = userInfo["UINavigationControllerLastVisibleViewController"]
            let new = userInfo["UINavigationControllerNextVisibleViewController"]
            
            OneFlowLog.writeLog("Previous: \(previous as Any)")
            OneFlowLog.writeLog("current: \(new as Any)")
        }
    }
}
