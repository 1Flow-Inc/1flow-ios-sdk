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

extension OFRatingViewController {
    func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWasShown(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc func keyboardWasShown(notification: NSNotification) {
        guard let rect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        keyboardRect = rect.cgRectValue
        self.isKeyboardVisible = true
        self.changePositionAsPerKeyboard()
    }

    func changePositionAsPerKeyboard() {
        if let rect = keyboardRect {
            if isWidgetPositionBottom() || isWidgetPositionBottomBanner() {
                self.bottomConstraint.constant = rect.size.height
            }
            self.ratingView.setNeedsUpdateConstraints()
            if isWidgetPositionMiddle() {
                self.containerBottom.constant = rect.size.height + 10
            } else if isWidgetPositionFullScreen() {
                self.containerBottom.constant = rect.size.height + 10
            } else if isWidgetPositionTop() || isWidgetPositionTopBanner() {
                self.containerBottom.constant = rect.size.height + 10
            }

            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                self.view.layoutIfNeeded()
                self.scrollView.scrollRectToVisible(
                    CGRect(
                        x: self.scrollView.contentSize.width - 1,
                        y: self.scrollView.contentSize.height - 1,
                        width: 1,
                        height: 1
                    ),
                    animated: false
                )
            })
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        self.isKeyboardVisible = false
        if let centerConstraint = self.centerConstraint {
            centerConstraint.constant = 0
        }
        if let stackCenterConstraint = self.stackViewCenterConstraint {
            stackCenterConstraint.constant = 0
        }
        self.bottomConstraint.constant = 0
        if #available(iOS 11.0, *) {
            if let bottomPadding = UIApplication.shared.keyWindow?.safeAreaInsets.bottom {
                self.containerBottom.constant = bottomPadding
            }
        } else {
            self.containerBottom.constant = 15
        }
        setupTopBottomIfNeeded()
        self.ratingView.setNeedsUpdateConstraints()
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
}
