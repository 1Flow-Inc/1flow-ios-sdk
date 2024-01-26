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

    func presentNextScreen(_ previousAnswer: String?) {
        if let newIndex = self.getNextQuestionIndex(previousAnswer) {
            currentScreenIndex = newIndex
            if self.allScreens!.count > self.currentScreenIndex,
                let screen = self.allScreens?[self.currentScreenIndex] {
                self.setupUIAccordingToConfiguration(screen)
                OneFlow.shared.eventManager.recordInternalEvent(
                    name: InternalEvent.flowStepSeen,
                    parameters: [InternalKey.stepId: screen.identifier, InternalKey.flowId: surveyID as Any]
                )
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    if let surveyScreens = self.allScreens {
                        let filteredSurveyScreens = surveyScreens
                            .filter {
                                $0.input?.inputType != "end-screen" &&
                                $0.input?.inputType != "thank_you"
                            }
                        let extraScreens = (surveyScreens.count - filteredSurveyScreens.count) > 0 ? 1 : 0
                        self.progressBar.setProgress(
                            Float(CGFloat(self.currentScreenIndex + 1)/CGFloat(filteredSurveyScreens.count + extraScreens)),
                            animated: true
                        )
                    }
                }
            } else {
                // finish the survey
                guard let completion = self.completionBlock else { return }
                self.runCloseAnimation {
                    completion(self.surveyResult, self.isSurveyFullyAnswered)
                }
            }
        } else {
            OneFlowLog.writeLog("Data Logic : No need to show next question as rating or open url action is performed")
        }
    }

    func setupPrimaryTitle(for currentScreen: SurveyListResponse.Survey.Screen) {
        if let value = currentScreen.title {
            self.viewPrimaryTitle1.isHidden = false
            self.lblPrimaryTitle1.text = value
            self.lblPrimaryTitle1.textColor = kPrimaryTitleColor
            self.lblPrimaryTitle1.font = OneFlow.fontConfiguration?.titleFont
            if currentScreen.input?.inputType == "welcome-screen" {
                self.lblPrimaryTitle1.textAlignment = .center
            } else {
                self.lblPrimaryTitle1.textAlignment = .natural
            }
        } else {
            self.viewPrimaryTitle1.isHidden = true
        }
    }

    func setupSecondaryTitle(for currentScreen: SurveyListResponse.Survey.Screen) {
        if let value = currentScreen.message, value.count > 0 {
            self.viewSecondaryTitle.isHidden = false
            self.lblSecondaryTitle.text = value
            self.lblSecondaryTitle.textColor = kSecondaryTitleColor
            self.lblSecondaryTitle.font = OneFlow.fontConfiguration?.subTitleFont
            if currentScreen.input?.inputType == "welcome-screen" {
                self.lblSecondaryTitle.textAlignment = .center
            } else {
                self.lblSecondaryTitle.textAlignment = .natural
            }
        } else {
            self.viewSecondaryTitle.isHidden = true
        }
    }

    func setupMediaContentView(for currentScreen: SurveyListResponse.Survey.Screen) {
        if let mediaContent = currentScreen.mediaEmbedHtml {
            webContainerView.isHidden = false
            self.webContainerHeight.constant = 0
            webContainerView.delegate = self
            webContainerView.loadHTMLContent(mediaContent)
        } else {
            webContainerView.isHidden = true
        }
    }

    func setupOpenTextViewIfNeeded(for currentScreen: SurveyListResponse.Survey.Screen) {
        if currentScreen.input?.inputType == "text" {
            let view = OFFollowupView.loadFromNib()
            view.delegate = self
            view.widgetPosition = self.widgetPosition
            view.placeHolderText = currentScreen.input?.placeholderText ?? "Type here"
            view.maxCharsAllowed = currentScreen.input?.maxChars ?? 1000
            view.minCharsAllowed = currentScreen.input?.minChars ?? 5
            if let buttonArray = currentScreen.buttons {
                if buttonArray.count > 0 {
                    if let buttonTitle = buttonArray.first?.title {
                        view.submitButtonTitle = buttonTitle
                    }
                }
            }
            view.isHidden = true
            self.stackView.insertArrangedSubview(view, at: indexToAddOn)
        }
    }

    func setupShortTextViewIfNeeded(for currentScreen: SurveyListResponse.Survey.Screen) {
        if currentScreen.input?.inputType == "short-text" {
            let view = OFShortAnswerView.loadFromNib()
            view.delegate = self
            view.placeHolderText = currentScreen.input!.placeholderText ?? "Type here"
            view.minCharsAllowed = 0 // currentScreen.input!.min_chars ?? 5
            if let buttonArray = currentScreen.buttons {
                if buttonArray.count > 0 {
                    if let buttonTitle = buttonArray.first?.title {
                        view.submitButtonTitle = buttonTitle
                    }
                }
            }
            view.isHidden = true
            self.stackView.insertArrangedSubview(view, at: indexToAddOn)
        }
    }

    func setupStarViewIfNeeded(for currentScreen: SurveyListResponse.Survey.Screen) {
        if currentScreen.input?.inputType == "rating" || currentScreen.input?.inputType == "rating-5-star" {
            let view = OFStarsView.loadFromNib()
            if let ratingDic = currentScreen.input?.ratingText {
                view.ratingDic = ratingDic
            }
            view.delegate = self
            view.isHidden = true
            self.stackView.insertArrangedSubview(view, at: indexToAddOn)
        }
    }

    func setupEmojiViewIfNeeded(for currentScreen: SurveyListResponse.Survey.Screen) {
        if currentScreen.input?.inputType == "rating-emojis" {
            let view = OFOneToTenView.loadFromNib()
            view.isForEmoji = true
            view.emojiArray = ["☹️", "🙁", "😐", "🙂", "😊"]
            view.delegate = self
            view.isHidden = true
            self.stackView.insertArrangedSubview(view, at: indexToAddOn)
        }
    }

    func setupNumericRatingViewIfNeeded(for currentScreen: SurveyListResponse.Survey.Screen) {
        if currentScreen.input?.inputType == "rating-numerical" {
            let view = OFOneToTenView.loadFromNib()
            view.delegate = self
            view.minValue = 1
            view.maxValue = 5
            view.ratingMinText = currentScreen.input?.ratingMinText
            view.ratingMaxText = currentScreen.input?.ratingMaxText
            view.isHidden = true
            self.stackView.insertArrangedSubview(view, at: indexToAddOn)
        }
    }

    func setupNPSViewIfNeeded(for currentScreen: SurveyListResponse.Survey.Screen) {
        if currentScreen.input?.inputType == "nps" {
            let view = OFOneToTenView.loadFromNib()
            view.delegate = self
            view.minValue = currentScreen.input?.minVal ?? 0
            view.maxValue = currentScreen.input?.maxVal ?? 10
            view.ratingMinText = currentScreen.input?.ratingMinText
            view.ratingMaxText = currentScreen.input?.ratingMaxText
            view.isHidden = true
            self.stackView.insertArrangedSubview(view, at: indexToAddOn)
        }
    }

    func setupMCQViewIfNeeded(for currentScreen: SurveyListResponse.Survey.Screen) {
        if currentScreen.input?.inputType == "mcq" {
            let view = OFMCQView.loadFromNib()
            view.delegate = self
            view.currentType = .radioButton
            if let titleArray = currentScreen.input!.choices?.map({ return $0 }) {
                view.setupViewWithOptions(
                    titleArray,
                    type: .radioButton,
                    parentViewWidth: self.stackView.bounds.width,
                    currentScreen.input?.otherOptionID
                )
            }
            view.isHidden = true
            self.stackView.insertArrangedSubview(view, at: indexToAddOn)
        }
    }

    func setupCheckboxViewIfNeeded(for currentScreen: SurveyListResponse.Survey.Screen) {
        if currentScreen.input?.inputType == "checkbox" {
            let view = OFMCQView.loadFromNib()
            view.delegate = self
            view.currentType = .checkBox
            if let titleArray = currentScreen.input!.choices?.map({ return $0 }) {
                view.setupViewWithOptions(
                    titleArray,
                    type: .checkBox,
                    parentViewWidth: self.stackView.bounds.width,
                    currentScreen.input?.otherOptionID
                )
            }
            if let buttonArray = currentScreen.buttons {
                if buttonArray.count > 0 {
                    if let buttonTitle = buttonArray.first?.title {
                        view.submitButtonTitle = buttonTitle
                    }
                }
            }
            view.isHidden = true
            self.stackView.insertArrangedSubview(view, at: indexToAddOn)
        }
    }

    func setupEndScreenIfNeeded(for currentScreen: SurveyListResponse.Survey.Screen) {
        if currentScreen.input?.inputType == "end-screen" || currentScreen.input?.inputType == "thank_you" {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                self.progressBar.setProgress(1.0, animated: true)
            }
            self.viewPrimaryTitle1.isHidden = true
            self.viewSecondaryTitle.isHidden = true
            let view = OFThankYouView.loadFromNib()
            view.delegate = self
            view.thankyouTitle = currentScreen.title ?? "Thank you!"
            view.thankyouDescription = currentScreen.message ?? "Your answer has been recorded."

            view.isHidden = true
            let shouldFadeAway = (self.allScreens?[self.currentScreenIndex].rules?.dismissBehavior?.fadesAway) ?? true
            if !shouldFadeAway {
                self.closeButton.isHidden = false
            }
            /// For thank you page, web container will be on 4th position. So add thanks you view at 3rd in stack view
            /// since thank you screen is last screen it will not affect anything
            /// if thank you screen to be presented in in between other screens,
            /// then we need to arrange subview index again
            self.stackView.insertArrangedSubview(view, at: 2)
            indexToAddOn = 2
        }
    }

    func setupWelcomeScreenIfNeeded(for currentScreen: SurveyListResponse.Survey.Screen) {
        if currentScreen.input?.inputType == "welcome-screen" {
            let view = OFWelcomeView.loadFromNib()
            view.delegate = self
            if let buttonArray = currentScreen.buttons {
                if buttonArray.count > 0 {
                    if let buttonTitle = buttonArray.first?.title {
                        view.continueTitle = buttonTitle
                    }
                }
            }
            view.isHidden = true
            self.stackView.insertArrangedSubview(view, at: indexToAddOn)
        }
    }

    func startFirstScreenLaunchAnimation() {
        self.isFirstQuestionLaunched = true
        if self.isWidgetPositionBottom() || self.isWidgetPositionBottomBanner() {
            let originalPosition = self.ratingView.frame.origin.y
            self.ratingView.frame.origin.y = self.view.frame.size.height
            self.ratingView.alpha = 1.0
            self.containerView.alpha = 1.0
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.5,
                options: UIView.AnimationOptions.curveEaseInOut
            ) {
                self.ratingView.frame.origin.y = originalPosition
            } completion: { _ in
                var totalDelay = 0.0
                for subView in self.stackView.arrangedSubviews {
                    UIView.animate(
                        withDuration: 0.5,
                        delay: totalDelay,
                        options: UIView.AnimationOptions.allowUserInteraction
                    ) {
                        subView.alpha = 1.0
                    }
                    totalDelay += 0.2
                }
            }
        } else if self.isWidgetPositionMiddle() || self.isWidgetPositionFullScreen() {
            self.ratingView.alpha = 1.0
            self.ratingView.isHidden = true
            for subView in self.stackView.arrangedSubviews {
                subView.alpha = 1.0
            }
            self.containerView.alpha = 1.0
            UIView.transition(with: self.ratingView, duration: 0.5, options: .transitionCrossDissolve) {
                self.ratingView.isHidden = false
            }
        } else if self.isWidgetPositionTop() || self.isWidgetPositionTopBanner() {
            let originalPosition = self.ratingView.frame.origin.y
            self.ratingView.frame.origin.y = 0 - self.ratingView.frame.size.height
            self.ratingView.alpha = 1.0
            self.containerView.alpha = 1.0
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.5,
                options: UIView.AnimationOptions.curveEaseInOut
            ) {
                self.ratingView.frame.origin.y = originalPosition
            } completion: { _ in
                var totalDelay = 0.0
                for subView in self.stackView.arrangedSubviews {
                    UIView.animate(
                        withDuration: 0.5,
                        delay: totalDelay,
                        options: UIView.AnimationOptions.allowUserInteraction
                    ) {
                        subView.alpha = 1.0
                    }
                    totalDelay += 0.2
                }
            }
        }
    }

    func setupUIAccordingToConfiguration(_ currentScreen: SurveyListResponse.Survey.Screen) {
        self.stackView.alpha = 0.0
        self.webContainerView.stopLoadingContent()
        self.setupPrimaryTitle(for: currentScreen)
        self.setupSecondaryTitle(for: currentScreen)
        self.setupMediaContentView(for: currentScreen)

        self.indexToAddOn = 3

        if self.stackView.arrangedSubviews.count > indexToAddOn {
            let subView = self.stackView.arrangedSubviews[indexToAddOn]
            subView.removeFromSuperview()
        }

        self.setupOpenTextViewIfNeeded(for: currentScreen)
        self.setupShortTextViewIfNeeded(for: currentScreen)
        self.setupStarViewIfNeeded(for: currentScreen)
        self.setupEmojiViewIfNeeded(for: currentScreen)
        self.setupNumericRatingViewIfNeeded(for: currentScreen)
        self.setupNPSViewIfNeeded(for: currentScreen)
        self.setupMCQViewIfNeeded(for: currentScreen)
        self.setupCheckboxViewIfNeeded(for: currentScreen)
        self.setupEndScreenIfNeeded(for: currentScreen)
        self.setupWelcomeScreenIfNeeded(for: currentScreen)

        for subview in self.stackView.arrangedSubviews {
            subview.alpha = 0.0
            subview.backgroundColor = kBackgroundColor
        }
        UIView.animate(withDuration: 0.3) {
            if self.stackView.arrangedSubviews.count > self.indexToAddOn {
                self.stackView.arrangedSubviews[self.indexToAddOn].isHidden = false
            }
        } completion: { _ in
            self.stackView.alpha = 1.0
            if self.currentScreenIndex == 0 || !self.isFirstQuestionLaunched {
                self.startFirstScreenLaunchAnimation()
            } else {
                var totalDelay = 0.0
                for subView in self.stackView.arrangedSubviews {
                    UIView.animate(
                        withDuration: 0.5,
                        delay: totalDelay,
                        options: UIView.AnimationOptions.allowUserInteraction
                    ) {
                        subView.alpha = 1.0
                    }
                    totalDelay += 0.2
                }
                self.setupTopBottomIfNeeded()
            }
        }
    }
}
