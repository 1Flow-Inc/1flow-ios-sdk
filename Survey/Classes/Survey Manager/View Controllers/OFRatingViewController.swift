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

typealias RatingViewCompletion = ((_ surveyResult: [SurveySubmitRequest.Answer], _ isCompleted: Bool) -> Void)
typealias RecordOnlyEmptyTextCompletion = (() -> Void)

class OFRatingViewController: UIViewController {
    @IBOutlet weak var mostContainerView: UIView!
    @IBOutlet weak var ratingView: OFDraggableView!
    @IBOutlet weak var containerView: OFRoundedConrnerView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var imgDraggView: UIImageView!
    @IBOutlet weak var dragViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewPrimaryTitle1: UIView!
    @IBOutlet weak var viewSecondaryTitle: UIView!
    @IBOutlet weak var lblPrimaryTitle1: UILabel!
    @IBOutlet weak var lblSecondaryTitle: UILabel!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var poweredByButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var webContainerView: OFWebContainerView!
    @IBOutlet weak var bottomPaddingView: UIView!
    @IBOutlet weak var topPaddingView: UIView!
    @IBOutlet weak var webContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var containerLeading: NSLayoutConstraint!
    @IBOutlet weak var containerTrailing: NSLayoutConstraint!
    @IBOutlet weak var containerBottom: NSLayoutConstraint!
    @IBOutlet weak var containerTop: NSLayoutConstraint!
    @IBOutlet weak var stackViewTop: NSLayoutConstraint!
    @IBOutlet weak var stackViewBottom: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!

    var isKeyboardVisible = false
    var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?
    var allScreens: [SurveyListResponse.Survey.Screen]?
    var surveyResult = [SurveySubmitRequest.Answer]()
    var widgetPosition = WidgetPosition.bottomCenter
    var completionBlock: RatingViewCompletion?
    var currentScreenIndex = -1
    var recordEmptyTextCompletionBlock: RecordOnlyEmptyTextCompletion?
    var isClosingAnimationRunning: Bool = false
    private var shouldShowRating: Bool = false
    private var shouldOpenUrl: Bool = false
    var shouldRemoveWatermark = false
    var shouldShowCloseButton = true
    var shouldShowDarkOverlay = true
    var shouldShowProgressBar = true
    var surveyID: String?
    var surveyName: String?
    var isFirstQuestionLaunched = false
    var centerConstraint: NSLayoutConstraint!
    var stackViewCenterConstraint: NSLayoutConstraint!
    var keyboardRect: CGRect!
    lazy var waterMarkURL = "https://1flow.app/?utm_source=1flow-ios-sdk&utm_medium=watermark&utm_campaign=real-time+feedback+powered+by+1flow"
    var isSurveyFullyAnswered = true
    var indexToAddOn = 3

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        self.setupKeyboardObserver()
        let width = self.view.bounds.width * 0.119
        self.dragViewWidthConstraint.constant = width
        self.imgDraggView.layer.cornerRadius = 2.5
        self.containerView.alpha = 0.0
        self.ratingView.alpha = 0.0
        self.ratingView.layer.shadowColor = UIColor.black.cgColor
        self.ratingView.layer.shadowOpacity = 0.25
        self.ratingView.layer.shadowOffset = CGSize.zero
        self.ratingView.layer.shadowRadius = 8.0
        self.mostContainerView.backgroundColor = kBackgroundColor
        self.containerView.backgroundColor = kBackgroundColor
        self.bottomView.backgroundColor = kBackgroundColor
        self.stackView.arrangedSubviews.forEach({ $0.backgroundColor = kBackgroundColor })
        self.setPoweredByButtonText(fullText: " Powered by 1Flow", mainText: " Powered by ", creditsText: "1Flow")
        if let closeImage = UIImage(
            named: "CloseButton",
            in: OneFlowBundle.bundleForObject(self),
            compatibleWith: nil)?
            .withRenderingMode(.alwaysTemplate) {
            self.closeButton.setImage(closeImage, for: .normal)
            self.closeButton.tintColor = kCloseButtonColor
        }
        self.poweredByButton.isHidden = self.shouldRemoveWatermark
        self.closeButton.isHidden = !self.shouldShowCloseButton
        self.progressBar.isHidden = !self.shouldShowProgressBar
        setupWidgetPosition()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.progressBar.tintColor = kBrandColor
        if self.shouldShowDarkOverlay {
            UIView.animate(withDuration: 0.2) {
                self.view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
            }
        }
        if self.currentScreenIndex == -1 {
            self.presentNextScreen(nil)
        }
        let radius: CGFloat = 5.0
        self.bottomView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: radius)
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }

    func setupView(with survey: SurveyListResponse.Survey) {
        shouldRemoveWatermark = survey.surveySettings?.sdkTheme?.removeWatermark ?? false
        shouldShowCloseButton = survey.surveySettings?.sdkTheme?.closeButton ?? true
        shouldShowDarkOverlay = survey.surveySettings?.sdkTheme?.darkOverlay ?? true
        shouldShowProgressBar = survey.surveySettings?.sdkTheme?.progressBar ?? true
        modalPresentationStyle = .overFullScreen
        view.backgroundColor = UIColor.clear
        allScreens = survey.screens
        surveyID = survey.identifier
        surveyName = survey.name
        if let widgetPosition = survey.surveySettings?.sdkTheme?.widgetPosition {
            self.widgetPosition = widgetPosition
            setupWidgetPosition()
        }
    }

    func setPoweredByButtonText(fullText: String, mainText: String, creditsText: String) {
        let fontBig = UIFont.systemFont(ofSize: 12, weight: .regular)
        let fontSmall = UIFont.systemFont(ofSize: 12, weight: .bold)
        let attributedString = NSMutableAttributedString(string: fullText, attributes: nil)

        let bigRange = (attributedString.string as NSString).range(of: mainText)
        let creditsRange = (attributedString.string as NSString).range(of: creditsText)
        attributedString.setAttributes(
            [
                NSAttributedString.Key.font: fontBig as Any,
                NSAttributedString.Key.foregroundColor: kWatermarkColor
            ],
            range: bigRange
        )
        attributedString.setAttributes(
            [
                NSAttributedString.Key.font: fontSmall as Any,
                NSAttributedString.Key.foregroundColor: kWatermarkColor
            ],
            range: creditsRange
        )
        self.poweredByButton.setAttributedTitle(attributedString, for: .normal)
        let highlightedString = NSMutableAttributedString(string: fullText, attributes: nil)
        highlightedString.setAttributes(
            [
                NSAttributedString.Key.font: fontBig as Any,
                NSAttributedString.Key.foregroundColor: kWatermarkColorHightlighted
            ],
            range: bigRange
        )
        highlightedString.setAttributes(
            [
                NSAttributedString.Key.font: fontSmall as Any,
                NSAttributedString.Key.foregroundColor: kWatermarkColorHightlighted
            ],
            range: creditsRange
        )
        self.poweredByButton.setAttributedTitle(highlightedString, for: .highlighted)
    }

    @IBAction func onClickWatermark(_ sender: Any) {
        guard let url = URL(string: waterMarkURL) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    func runCloseAnimation(_ completion: @escaping () -> Void) {
        if self.isSurveyFullyAnswered {
            OneFlow.shared.eventManager.recordInternalEvent(
                name: InternalEvent.flowCompleted,
                parameters: [InternalKey.flowId: surveyID as Any]
            )
        } else {
            OneFlow.shared.eventManager.recordInternalEvent(
                name: InternalEvent.flowEnded,
                parameters: [InternalKey.flowId: surveyID as Any]
            )
        }
        OneFlowLog.writeLog("End Screen logic : Running close animation")
        self.isClosingAnimationRunning = true
        if isWidgetPositionBottom() || isWidgetPositionBottomBanner() {
            UIView.animate(withDuration: 0.5) {
                self.ratingView.frame.origin.y += self.ratingView.frame.size.height
            }
        } else if isWidgetPositionMiddle() || isWidgetPositionFullScreen() {
            UIView.transition(with: self.ratingView, duration: 0.5, options: .transitionCrossDissolve) {
                self.ratingView.alpha = 0.0
            }
        } else if isWidgetPositionTop() || isWidgetPositionTopBanner() {
            UIView.animate(withDuration: 0.5) {
                self.ratingView.frame.origin.y = 0 - self.ratingView.frame.size.height
            }
        }
        if !self.shouldShowDarkOverlay {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.001)
        }
        UIView.animate(withDuration: 0.3, delay: 0.5, options: UIView.AnimationOptions.curveEaseIn) {
            self.view.backgroundColor = UIColor.clear
        } completion: { _ in
            completion()
        }
    }

    @IBAction func onBlankSpaceTapped(_ sender: Any) {
        if self.isKeyboardVisible == true {
            self.view.endEditing(true)
            return
        }
    }

    @IBAction func onCloseTapped(_ sender: UIButton) {
        OneFlowLog.writeLog("End Screen logic: onCloseTapped")
        if self.isKeyboardVisible == true {
            self.view.endEditing(true)
        }
        if let currentScreen = self.allScreens?[currentScreenIndex] {
            if !(currentScreen.input?.inputType == "end-screen" || currentScreen.input?.inputType == "thank_you") {
                self.isSurveyFullyAnswered = false
            }
        }
        guard let completion = self.completionBlock else { return }
        self.runCloseAnimation {
            completion(self.surveyResult, self.isSurveyFullyAnswered)
        }
    }
}

extension OFRatingViewController: WebContainerDelegate {
    func webContainerDidLoadWith(_ contentHeight: CGFloat) {
        self.webContainerHeight.constant = contentHeight
        self.view.layoutIfNeeded()
        self.setupTopBottomIfNeeded()
    }
}
