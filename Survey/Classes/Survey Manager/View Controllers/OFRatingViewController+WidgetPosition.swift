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

extension OFRatingViewController {
    func setupWidgetPosition() {
        let topSpacing: CGFloat
        let bottomSpacing: CGFloat
        if #available(iOS 11.0, *) {
            if let topPadding = UIApplication.shared.keyWindow?.safeAreaInsets.top {
                topSpacing = topPadding
            } else {
                topSpacing = 15
            }
            if let bottomPadding = UIApplication.shared.keyWindow?.safeAreaInsets.bottom {
                bottomSpacing = bottomPadding
            } else {
                bottomSpacing = 15
            }
        } else {
            topSpacing = 15
            bottomSpacing = 15
        }
        if isWidgetPositionBottom() {
            containerTop.constant = topSpacing
        } else if isWidgetPositionMiddle() {
            bottomConstraint.isActive = false
            centerConstraint = ratingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            centerConstraint.isActive = true
            containerBottom.constant = bottomSpacing
            containerTop.constant = topSpacing
        } else if isWidgetPositionTop() {
            bottomConstraint.isActive = false
            ratingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            containerTop.constant = topSpacing + 15
            containerBottom.constant = bottomSpacing
        } else if isWidgetPositionTopBanner() {
            bottomConstraint.isActive = false
            ratingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            containerTop.constant = topSpacing
            containerBottom.constant = bottomSpacing
            containerLeading.constant = 0
            containerTrailing.constant = 0
            topPaddingView.isHidden = false
            topPaddingView.backgroundColor = kBackgroundColor
        } else if isWidgetPositionBottomBanner() {
            containerBottom.constant = bottomSpacing
            containerTop.constant = topSpacing
            containerLeading.constant = 0
            containerTrailing.constant = 0
            bottomPaddingView.isHidden = false
            bottomPaddingView.backgroundColor = kBackgroundColor
        } else if isWidgetPositionFullScreen() {
            if #available(iOS 11.0, *) {
                if let bottomPadding = UIApplication.shared.keyWindow?.safeAreaInsets.bottom {
                    containerBottom.constant = bottomPadding + 10
                }
            } else {
                containerBottom.constant = 10
            }
            containerLeading.constant = 0
            containerTrailing.constant = 0
            containerTop.constant = topSpacing
            ratingView.backgroundColor = kBackgroundColor
            centerConstraint = ratingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            centerConstraint.isActive = true
            stackViewCenterConstraint = scrollView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            stackViewCenterConstraint.isActive = true
            setupTopBottomIfNeeded()
        }
    }

    func setupTopBottomIfNeeded() {
        if self.isWidgetPositionFullScreen() {
            if self.isKeyboardVisible {
                if self.stackView.bounds.height < (self.view.bounds.height - keyboardRect.height - 46) {
                    self.stackViewTop.priority = .defaultLow
                    self.stackViewBottom.priority = .defaultLow
                } else {
                    self.stackViewTop.priority = .required
                    self.stackViewBottom.priority = .required
                }
            } else {
                if self.stackView.bounds.height < self.view.bounds.height {
                    self.stackViewTop.priority = .defaultLow
                    self.stackViewBottom.priority = .defaultLow
                } else {
                    self.stackViewTop.priority = .required
                    self.stackViewBottom.priority = .required
                }
            }
        }
    }

    func isWidgetPositionBottom() -> Bool {
        if widgetPosition == .bottomLeft || widgetPosition == .bottomCenter || widgetPosition == .bottomRight {
            return true
        }
        return false
    }

    func isWidgetPositionMiddle() -> Bool {
        if widgetPosition == .middleLeft || widgetPosition == .middleCenter || widgetPosition == .middleRight {
            return true
        }
        return false
    }

    func isWidgetPositionTop() -> Bool {
        if widgetPosition == .topLeft || widgetPosition == .topCenter || widgetPosition == .topRight {
            return true
        }
        return false
    }

    func isWidgetPositionFullScreen() -> Bool {
        if widgetPosition == .fullScreen {
            return true
        }
        return false
    }

    func isWidgetPositionTopBanner() -> Bool {
        if widgetPosition == .topBanner {
            return true
        }
        return false
    }

    func isWidgetPositionBottomBanner() -> Bool {
        if widgetPosition == .bottomBanner {
            return true
        }
        return false
    }
}
