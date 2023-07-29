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
import StoreKit

enum RatingStyle {
    case OneToTen
    case Stars
    case Emoji
    case MCQ
    case FollowUp
    case ReviewPrompt
    case ThankYou
}
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

    private var isKeyboardVisible = false
    var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?

    var allScreens: [SurveyListResponse.Survey.Screen]?
    var surveyResult = [SurveySubmitRequest.Answer]()
    var widgetPosition = WidgetPosition.bottomCenter

    var completionBlock: RatingViewCompletion?
    var currentScreenIndex = -1
    var recordEmptyTextCompletionBlock: RecordOnlyEmptyTextCompletion?
    
    private var isClosingAnimationRunning: Bool = false
    private var shouldShowRating: Bool = false
    private var shouldOpenUrl: Bool = false
    var shouldRemoveWatermark = false
    var shouldShowCloseButton = true
    var shouldShowDarkOverlay = true
    var shouldShowProgressBar = true
    var surveyID: String?
    var surveyName: String?
    
    private var isFirstQuestionLaunched = false


    var centerConstraint  : NSLayoutConstraint!
    var stackViewCenterConstraint  : NSLayoutConstraint!
    
    var keyboardRect : CGRect!

    lazy var waterMarkURL = "https://1flow.app/?utm_source=1flow-ios-sdk&utm_medium=watermark&utm_campaign=real-time+feedback+powered+by+1flow"
    var isSurveyFullyAnswered = true

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
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
        if let closeImage = UIImage.init(named: "CloseButton", in: OneFlowBundle.bundleForObject(self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate) {
            self.closeButton.setImage(closeImage, for: .normal)
            self.closeButton.tintColor = kCloseButtonColor
        }
        self.poweredByButton.isHidden = self.shouldRemoveWatermark
        self.closeButton.isHidden = !self.shouldShowCloseButton
        self.progressBar.isHidden = !self.shouldShowProgressBar
        setupWidgetPosition()
    }
    
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
            self.containerTop.constant = topSpacing
        } else if isWidgetPositionMiddle() {
            self.bottomConstraint.isActive = false
            centerConstraint = self.ratingView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
            centerConstraint.isActive = true
            self.containerBottom.constant = bottomSpacing
            self.containerTop.constant = topSpacing

        } else if isWidgetPositionTop() {
            self.bottomConstraint.isActive = false
            self.ratingView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            self.containerTop.constant = topSpacing + 15
            self.containerBottom.constant = bottomSpacing
        } else if isWidgetPositionTopBanner() {
            self.bottomConstraint.isActive = false
            self.ratingView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            self.containerTop.constant = topSpacing
            self.containerBottom.constant = bottomSpacing
            self.containerLeading.constant = 0
            self.containerTrailing.constant = 0
            self.topPaddingView.isHidden = false
            self.topPaddingView.backgroundColor = kBackgroundColor
        } else if isWidgetPositionBottomBanner() {
            self.containerBottom.constant = bottomSpacing
            self.containerTop.constant = topSpacing
            self.containerLeading.constant = 0
            self.containerTrailing.constant = 0
            self.bottomPaddingView.isHidden = false
            self.bottomPaddingView.backgroundColor = kBackgroundColor
        } else if isWidgetPositionFullScreen() {
            if #available(iOS 11.0, *) {
                if let bottomPadding = UIApplication.shared.keyWindow?.safeAreaInsets.bottom {
                    self.containerBottom.constant = bottomPadding + 10
                }
            } else {
                self.containerBottom.constant = 10
            }
            self.containerLeading.constant = 0
            self.containerTrailing.constant = 0
            self.containerTop.constant = topSpacing
            self.ratingView.backgroundColor = kBackgroundColor
            centerConstraint = self.ratingView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
            centerConstraint.isActive = true
            stackViewCenterConstraint = self.scrollView.centerYAnchor.constraint(equalTo: self.containerView.centerYAnchor)
            stackViewCenterConstraint.isActive = true
            self.setupTopBottomIfNeeded()
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
    
    func setPoweredByButtonText(fullText: String, mainText: String, creditsText: String) {
        let fontBig = UIFont.systemFont(ofSize: 12, weight:.regular)
        let fontSmall = UIFont.systemFont(ofSize: 12, weight:.bold)
        let attributedString = NSMutableAttributedString(string: fullText, attributes: nil)
        
        let bigRange = (attributedString.string as NSString).range(of: mainText)
        let creditsRange = (attributedString.string as NSString).range(of: creditsText)
        attributedString.setAttributes([NSAttributedString.Key.font: fontBig as Any, NSAttributedString.Key.foregroundColor: kWatermarkColor], range: bigRange)
        attributedString.setAttributes([NSAttributedString.Key.font: fontSmall as Any, NSAttributedString.Key.foregroundColor: kWatermarkColor], range: creditsRange)
        self.poweredByButton.setAttributedTitle(attributedString, for: .normal)
        
        let highlightedString = NSMutableAttributedString(string: fullText, attributes: nil)
        highlightedString.setAttributes([NSAttributedString.Key.font: fontBig as Any, NSAttributedString.Key.foregroundColor: kWatermarkColorHightlighted], range: bigRange)
        highlightedString.setAttributes([NSAttributedString.Key.font: fontSmall as Any, NSAttributedString.Key.foregroundColor: kWatermarkColorHightlighted], range: creditsRange)
        self.poweredByButton.setAttributedTitle(highlightedString, for: .highlighted)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.progressBar.tintColor = kBrandColor
//        self.progressBar.trackTintColor = kBackgroundColor
        if self.shouldShowDarkOverlay {
            UIView.animate(withDuration: 0.2) {
                self.view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
            } completion: { _ in
                
            }
        }
       
        if self.currentScreenIndex == -1 {
            self.presentNextScreen(nil)
        }
        let radius: CGFloat = 5.0
        self.bottomView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: radius)
    }
    
    @IBAction func onClickWatermark(_ sender: Any) {
        guard let url = URL(string: waterMarkURL) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [ : ], completionHandler: nil)
        }
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

    @objc func keyboardWasShown(notification: NSNotification) {
        let info = notification.userInfo!
        keyboardRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.isKeyboardVisible = true
        self.changePositionAsPerKeyboard()
    }
    
    func changePositionAsPerKeyboard() {
        if let _ = keyboardRect  {
            if isWidgetPositionBottom() || isWidgetPositionBottomBanner() {
                self.bottomConstraint.constant = keyboardRect.size.height
            }
            self.ratingView.setNeedsUpdateConstraints()
            if isWidgetPositionMiddle() {
                self.containerBottom.constant = keyboardRect.size.height + 10
            } else if isWidgetPositionFullScreen() {
                self.containerBottom.constant = keyboardRect.size.height + 10
            } else if isWidgetPositionTop() || isWidgetPositionTopBanner() {
                self.containerBottom.constant = keyboardRect.size.height + 10
            }
            
            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                self.view.layoutIfNeeded()
                self.scrollView.scrollRectToVisible(CGRect(x: self.scrollView.contentSize.width - 1, y: self.scrollView.contentSize.height - 1, width: 1, height: 1), animated: false)
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
    //MARK: -
    
    fileprivate func presentNextScreen(_ previousAnswer : String?) {
        if let newIndex = self.getNextQuestionIndex(previousAnswer) {
            currentScreenIndex = newIndex
            if self.allScreens!.count > self.currentScreenIndex,
                let screen = self.allScreens?[self.currentScreenIndex] {
                self.setupUIAccordingToConfiguration(screen)
                OneFlow.shared.eventManager.recordInternalEvent(
                    name: InternalEvent.flowStepSeen,
                    parameters: [InternalKey.stepId: screen._id, InternalKey.flowId: surveyID as Any]
                )
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    if let surveyScreens = self.allScreens {
                        let filteredSurveyScreens = surveyScreens.filter { $0.input?.input_type != "end-screen" && $0.input?.input_type != "thank_you"  }
                        let extraScreens = (surveyScreens.count - filteredSurveyScreens.count) > 0 ? 1 : 0
                        self.progressBar.setProgress(Float(CGFloat(self.currentScreenIndex + 1 )/CGFloat(filteredSurveyScreens.count + extraScreens)), animated: true)
                    }
                }
            } else {
                //finish the survey
                guard let completion = self.completionBlock else { return }
                self.runCloseAnimation {
                    completion(self.surveyResult, self.isSurveyFullyAnswered)
                }
            }
        } else {
            OneFlowLog.writeLog("Data Logic : No need to show next question as rating or open url action is performed")
        }
    }

    fileprivate func getNextQuestionIndex(_ previousAnswer : String?) -> Int? {
        var nextSurveyIndex : Int!
        if currentScreenIndex == -1 {
            nextSurveyIndex = currentScreenIndex + 1
            return nextSurveyIndex
        }
        OneFlowDataLogic().getNextAction(currentIndex: currentScreenIndex, allSurveys: self.allScreens!, previousAnswer : previousAnswer,  completion: { (action, nextIndex, urlToOpen) -> Void in
            if let actionToPerform : String  = action {
                if actionToPerform == "open-url" {
                    if let actionUrl : String = urlToOpen {
                        self.performOpenUrlAction(actionUrl)
                        return
                    }
                } else if actionToPerform == "rating" {
                    self.performRatingAction()
                    return
                } else if actionToPerform == "skipTo" {
                    if let nextQuestionIndex : Int = nextIndex {
                        nextSurveyIndex = nextQuestionIndex
                    }
                }
            }
            else {
                OneFlowLog.writeLog("Data Logic : No Action detected for this question")
                nextSurveyIndex = currentScreenIndex + 1

            }
        })
        return nextSurveyIndex
    }
    
    private func checkandPerformEndScreenAction() {
        OneFlowLog.writeLog("End Screen logic : Check for end screen data logic")
        OneFlowDataLogic().getNextAction(currentIndex: currentScreenIndex, allSurveys: self.allScreens!, previousAnswer : "",  completion: { (action, nextIndex, urlToOpen) -> Void in
            if let actionToPerform : String  = action {
                if actionToPerform == "open-url" {
                    if let actionUrl : String = urlToOpen {
                        OneFlowLog.writeLog("End Screen logic : URL action detected with url \(actionUrl)")
                        self.performOpenUrlAction(actionUrl)
                        return
                    }
                }
                else if actionToPerform == "rating" {
                    OneFlowLog.writeLog("End Screen logic : Rating detected")
                    self.performRatingAction()
                    return
                }
                else {
                    guard let completion = self.completionBlock else { return }
                    self.runCloseAnimation {
                        completion(self.surveyResult, self.isSurveyFullyAnswered)
                    }
                }
                
            }
            else {
                OneFlowLog.writeLog("End Screen logic : No Action detected")
                guard let completion = self.completionBlock else { return }
                self.runCloseAnimation {
                    completion(self.surveyResult, self.isSurveyFullyAnswered)
                }
            }
        })
    }

    private func performRatingAction() {
        currentScreenIndex = -2
        guard let completion = self.completionBlock else { return }
        self.runCloseAnimation {
            self.openRatemePopup()
            completion(self.surveyResult, self.isSurveyFullyAnswered)
        }
    }

    private func openRatemePopup() {
        if #available(iOS 14.0, *) {
            if let currentWindowScene = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .compactMap({$0 as? UIWindowScene})
                .first {
                SKStoreReviewController.requestReview(in: currentWindowScene)
            }
            else {
                OneFlowLog.writeLog("Could not fetch currentWindowScene while showing rating")
            }
        } else {
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
            } else {
                self.openAppStoreRateMeUrl()
            }
        }
    }

    private func openAppStoreRateMeUrl(){
        
        OFAPIController.shared.getAppStoreDetails { [weak self] isSuccess, error, data in
            guard self != nil else {
                return
            }
            if isSuccess == true, let data = data {
                do{
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                    if let results : NSArray =  json!["results"] as? NSArray {
                        if results.count > 0 {
                            guard let result : NSDictionary = results.firstObject as? NSDictionary else {
                                return
                            }
                            if let trackId = result["trackId"]{
                                let ratingUrl = "https://itunes.apple.com/app/id\(trackId)?action=write-review" // (Option 2) Open App Review Page
                                OneFlowLog.writeLog("Data Logic : App store rating Url : \(ratingUrl)")

                                guard let url = URL(string: ratingUrl) else {
                                    return
                                }
                                DispatchQueue.main.async {
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                }
                            }
                        }
                        else {
                            OneFlowLog.writeLog("Data Logic : App Store track ID not found")
                        }
                    }
                }catch{
                    OneFlowLog.writeLog("Data Logic : App Store Url not found")
                }
                 
                
            } else {
                OneFlowLog.writeLog(error?.localizedDescription ?? "NA")
            }
        }
    }
    
    private func performOpenUrlAction(_ urlString : String) {
        currentScreenIndex = -2
        guard let completion = self.completionBlock else { return }
        self.runCloseAnimation {
            guard let url = URL(string: urlString) else {
                OneFlowLog.writeLog("Data Logic : Invalid Url received from server")
                completion(self.surveyResult, self.isSurveyFullyAnswered)
                return
            }
            DispatchQueue.main.async {
                if UIApplication.shared.canOpenURL(url) {
                    OneFlowLog.writeLog("Data Logic : Opening Url  : \(url.absoluteURL)")
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                else {
                    OneFlowLog.writeLog("Data Logic : Can not open url : \(url.absoluteURL)")
                }
                
            }
            completion(self.surveyResult, self.isSurveyFullyAnswered)
        }
    }
    
    private func setupUIAccordingToConfiguration(_ currentScreen: SurveyListResponse.Survey.Screen) {
        self.stackView.alpha = 0.0
        self.webContainerView.stopLoadingContent()
        if let value = currentScreen.title {
            self.viewPrimaryTitle1.isHidden = false
            self.lblPrimaryTitle1.text = value
            self.lblPrimaryTitle1.textColor = kPrimaryTitleColor
            self.lblPrimaryTitle1.font = OneFlow.fontConfiguration?.titleFont
            if currentScreen.input?.input_type == "welcome-screen" {
                self.lblPrimaryTitle1.textAlignment = .center
            } else {
                self.lblPrimaryTitle1.textAlignment = .natural
            }
        } else {
            self.viewPrimaryTitle1.isHidden = true
        }

        if let value = currentScreen.message, value.count > 0 {
            self.viewSecondaryTitle.isHidden = false
            self.lblSecondaryTitle.text = value
            self.lblSecondaryTitle.textColor = kSecondaryTitleColor
            self.lblSecondaryTitle.font = OneFlow.fontConfiguration?.subTitleFont
            if currentScreen.input?.input_type == "welcome-screen" {
                self.lblSecondaryTitle.textAlignment = .center
            } else {
                self.lblSecondaryTitle.textAlignment = .natural
            }
        } else {
            self.viewSecondaryTitle.isHidden = true
        }

        if let mediaContent = currentScreen.media_embed_html {
            webContainerView.isHidden = false
            self.webContainerHeight.constant = 0
            webContainerView.delegate = self
            webContainerView.loadHTMLContent(mediaContent)
        } else {
            webContainerView.isHidden = true
        }

        var indexToAddOn = 3
        if self.stackView.arrangedSubviews.count > indexToAddOn {
            let subView = self.stackView.arrangedSubviews[indexToAddOn]
            subView.removeFromSuperview()
        }

        if currentScreen.input?.input_type == "text" {
            let view = OFFollowupView.loadFromNib()
            view.delegate = self
            view.widgetPosition = self.widgetPosition
            view.placeHolderText = currentScreen.input!.placeholder_text ?? "Type here"
            view.maxCharsAllowed = currentScreen.input!.max_chars ?? 1000
            view.minCharsAllowed = currentScreen.input!.min_chars ?? 5
            if let buttonArray = currentScreen.buttons {
                if buttonArray.count > 0 {
                    if let buttonTitle = buttonArray.first?.title {
                        view.submitButtonTitle = buttonTitle
                    }
                }
            }
            view.isHidden = true
            self.stackView.insertArrangedSubview(view, at: indexToAddOn)
            
        } else if currentScreen.input?.input_type == "short-text" {
            let view = OFShortAnswerView.loadFromNib()
            view.delegate = self
            view.placeHolderText = currentScreen.input!.placeholder_text ?? "Type here"
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
            
        }  else if currentScreen.input?.input_type == "rating" ||  currentScreen.input?.input_type == "rating-5-star" {
            let view = OFStarsView.loadFromNib()
            if let ratingDic : [String : String] = currentScreen.input?.rating_text {
                view.ratingDic = ratingDic
            }
            view.delegate = self
            view.isHidden = true
            self.stackView.insertArrangedSubview(view, at: indexToAddOn)
        } else if currentScreen.input?.input_type == "rating-emojis" {
            let view = OFOneToTenView.loadFromNib()
            view.isForEmoji = true
            view.emojiArray = ["☹️", "🙁", "😐", "🙂", "😊"]
            view.delegate = self
            view.isHidden = true
            self.stackView.insertArrangedSubview(view, at: indexToAddOn)
        } else if currentScreen.input?.input_type == "rating-numerical" {
            let view = OFOneToTenView.loadFromNib()
            view.delegate = self
            view.minValue = 1
            view.maxValue = 5
            view.ratingMinText = currentScreen.input?.rating_min_text
            view.ratingMaxText = currentScreen.input?.rating_max_text
            view.isHidden = true
            self.stackView.insertArrangedSubview(view, at: indexToAddOn)
        } else if currentScreen.input?.input_type == "nps" {
            let view = OFOneToTenView.loadFromNib()
            view.delegate = self
            view.minValue = currentScreen.input?.min_val ?? 0
            view.maxValue = currentScreen.input?.max_val ?? 10
            view.ratingMinText = currentScreen.input?.rating_min_text
            view.ratingMaxText = currentScreen.input?.rating_max_text
            view.isHidden = true
            self.stackView.insertArrangedSubview(view, at: indexToAddOn)
        } else if currentScreen.input?.input_type == "mcq" {
            let view = OFMCQView.loadFromNib()
            view.delegate = self
            view.currentType = .radioButton
            if let titleArray = currentScreen.input!.choices?.map({ return $0 }) {
                view.setupViewWithOptions(titleArray, type: .radioButton, parentViewWidth: self.stackView.bounds.width, currentScreen.input?.other_option_id)
            }
            view.isHidden = true
            self.stackView.insertArrangedSubview(view, at: indexToAddOn)
        } else if currentScreen.input?.input_type == "checkbox" {
            let view = OFMCQView.loadFromNib()
            view.delegate = self
            view.currentType = .checkBox
            if let titleArray = currentScreen.input!.choices?.map({ return $0 }) {
                view.setupViewWithOptions(titleArray, type: .checkBox, parentViewWidth: self.stackView.bounds.width, currentScreen.input?.other_option_id)
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
        } else if currentScreen.input?.input_type == "end-screen" || currentScreen.input?.input_type == "thank_you" {
        
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
            let shouldFadeAway = (self.allScreens?[self.currentScreenIndex].rules?.dismiss_behavior?.fades_away) ?? true
            if !shouldFadeAway {
                self.closeButton.isHidden = false
            }
            /// For thank you page, web container will be on 4th position. So add thanks you view at 3rd in stack view
            /// since thank you screen is last screen it will not affect anything
            /// if thank you screen to be presented in in between other screens, then we need to arrange subview index again
            self.stackView.insertArrangedSubview(view, at: 2)
            indexToAddOn = 2
        }
        else if currentScreen.input?.input_type == "welcome-screen" {
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
        else {
            presentNextScreen(nil)
            return
        }

        for subview in self.stackView.arrangedSubviews {
            subview.alpha = 0.0
            subview.backgroundColor = kBackgroundColor
        }
        
        UIView.animate(withDuration: 0.3) {
            if self.stackView.arrangedSubviews.count > indexToAddOn {
                self.stackView.arrangedSubviews[indexToAddOn].isHidden = false
            }
            
        } completion: { _ in
            self.stackView.alpha = 1.0
            
            if self.currentScreenIndex == 0 || !self.isFirstQuestionLaunched {
                self.isFirstQuestionLaunched = true
                if self.isWidgetPositionBottom() || self.isWidgetPositionBottomBanner() {
                    let originalPosition = self.ratingView.frame.origin.y
                    self.ratingView.frame.origin.y = self.view.frame.size.height
                    self.ratingView.alpha = 1.0
                    self.containerView.alpha = 1.0
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: UIView.AnimationOptions.curveEaseInOut) {
                        self.ratingView.frame.origin.y = originalPosition
                    } completion: { _ in
                        var totalDelay = 0.0
                        for subView in self.stackView.arrangedSubviews {
                            UIView.animate(withDuration: 0.5, delay: totalDelay, options: UIView.AnimationOptions.allowUserInteraction) {
                                subView.alpha = 1.0
                            } completion: { _ in
                                
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
                } else if self.isWidgetPositionTop() || self.isWidgetPositionTopBanner()  {
                    let originalPosition = self.ratingView.frame.origin.y
                    self.ratingView.frame.origin.y = 0 - self.ratingView.frame.size.height
                    self.ratingView.alpha = 1.0
                    self.containerView.alpha = 1.0
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: UIView.AnimationOptions.curveEaseInOut) {
                        self.ratingView.frame.origin.y = originalPosition
                    } completion: { _ in
                        var totalDelay = 0.0
                        for subView in self.stackView.arrangedSubviews {
                            UIView.animate(withDuration: 0.5, delay: totalDelay, options: UIView.AnimationOptions.allowUserInteraction) {
                                subView.alpha = 1.0
                            } completion: { _ in
                                
                            }
                            totalDelay += 0.2
                        }
                    }
                }
            } else {
                var totalDelay = 0.0
                for subView in self.stackView.arrangedSubviews {
                    UIView.animate(withDuration: 0.5, delay: totalDelay, options: UIView.AnimationOptions.allowUserInteraction) {
                        subView.alpha = 1.0
                    } completion: { _ in

                    }
                    totalDelay += 0.2
                }
                self.setupTopBottomIfNeeded()
            }
        }
    }

    func runCloseAnimation(_ completion: @escaping ()-> Void) {
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
                self.ratingView.frame.origin.y = self.ratingView.frame.origin.y + self.ratingView.frame.size.height
            }
        } else if isWidgetPositionMiddle() || isWidgetPositionFullScreen() {
            UIView.transition(with: self.ratingView, duration: 0.5, options: .transitionCrossDissolve) {
                self.ratingView.alpha = 0.0
            }
        }
        else if isWidgetPositionTop() || isWidgetPositionTopBanner() {
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
    
    @objc func tapGestureAction(_ panGesture: UITapGestureRecognizer) {
        OneFlowLog.writeLog("tapGestureAction called")
        onBlankSpaceTapped(panGesture)
    }
    
    @objc func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: ratingView)
        if panGesture.state == .began {
            originalPosition = ratingView.center
            currentPositionTouched = panGesture.location(in: ratingView)
            
        } else if panGesture.state == .changed {
            if translation.y > 0 {
                ratingView.frame.origin = CGPoint(
                    x: ratingView.frame.origin.x,
                    y: (originalPosition?.y ?? 0) - (ratingView.frame.size.height / 2) + translation.y
                )
            }
            
        } else if panGesture.state == .ended {
            let velocity = panGesture.velocity(in: ratingView)
            
            if velocity.y >= 1500 {
                UIView.animate(withDuration: 0.2
                               , animations: {
                                self.ratingView.frame.origin = CGPoint(
                                    x: self.ratingView.frame.origin.x,
                                    y: self.view.frame.size.height
                                )
                               }, completion: { (isCompleted) in
                                if isCompleted {
                                    guard let completion = self.completionBlock else { return }
                                    completion(self.surveyResult, self.isSurveyFullyAnswered)
                                }
                               })
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.ratingView.center = self.originalPosition!
                })
            }
        }
    }

    @IBAction func onBlankSpaceTapped(_ sender: Any) {
        if self.isKeyboardVisible == true {
            self.view.endEditing(true)
            return
        }
    }

    @IBAction func onCloseTapped(_ sender: UIButton) {
        OneFlowLog.writeLog("End Screen logic : onCloseTapped")
        if self.isKeyboardVisible == true {
            self.view.endEditing(true)
        }
        if let currentScreen = self.allScreens?[currentScreenIndex] {
            if !(currentScreen.input?.input_type == "end-screen" || currentScreen.input?.input_type == "thank_you") {
                self.isSurveyFullyAnswered = false
            }
        }
        guard let completion = self.completionBlock else { return }
        self.runCloseAnimation {
            completion(self.surveyResult, self.isSurveyFullyAnswered)
        }
    }
}

extension OFRatingViewController : UIGestureRecognizerDelegate {
    
}

extension OFRatingViewController: OFRatingViewProtocol {
    
    func oneToTenViewChangeSelection(_ selectedIndex: Int?) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            if let index = selectedIndex, let screen = self.allScreens?[self.currentScreenIndex] {
                OneFlow.shared.eventManager.recordInternalEvent(
                    name: InternalEvent.questionAnswered,
                    parameters: [
                        InternalKey.questionId: screen._id,
                        InternalKey.stepId: screen._id,
                        InternalKey.flowId: self.surveyID as Any,
                        InternalKey.type: screen.input?.input_type as Any,
                        InternalKey.answer: "\(index)",
                        InternalKey.questionTitle: screen.title as Any,
                        InternalKey.questionDescription: screen.message as Any,
                        InternalKey.surveyName: self.surveyName as Any,
                    ]
                )
                let answer = SurveySubmitRequest.Answer(screen_id: screen._id, answer_value: "\(index)", answer_index: nil)
                self.surveyResult.append(answer)
                self.presentNextScreen(answer.answer_value)
            }
        }
    }
    
    func mcqViewChangeSelection(_ selectedOptionID: String,_ otherTextAnswer : String?) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            if  let screen = self.allScreens?[self.currentScreenIndex] {
                if let choices = screen.input?.choices {
                    let rawAnswer: String
                    if let otherTextAnswer = otherTextAnswer {
                        rawAnswer = otherTextAnswer
                    } else if let title = choices.first(where: { $0._id == selectedOptionID })?.title {
                        rawAnswer = title
                    } else {
                        rawAnswer = ""
                    }
                    
                    OneFlow.shared.eventManager.recordInternalEvent(
                        name: InternalEvent.questionAnswered,
                        parameters: [
                            InternalKey.questionId: screen._id,
                            InternalKey.stepId: screen._id,
                            InternalKey.flowId: self.surveyID as Any,
                            InternalKey.type: screen.input?.input_type as Any,
                            InternalKey.answer: rawAnswer,
                            InternalKey.questionTitle: screen.title as Any,
                            InternalKey.questionDescription: screen.message as Any,
                            InternalKey.surveyName: self.surveyName as Any,
                        ]
                    )
                }
                let answer = SurveySubmitRequest.Answer(screen_id: screen._id, answer_value: otherTextAnswer, answer_index: selectedOptionID)
                self.surveyResult.append(answer)
                self.presentNextScreen(answer.answer_index)
            }
        }
    }
    
    func checkBoxViewDidFinishPicking(_ selectedOptions: [String], _ otherTextAnswer: String?) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            if let screen = self.allScreens?[self.currentScreenIndex] {
                let finalString = selectedOptions.joined(separator: ",")
                if let choices = screen.input?.choices {
                    var rawAnswers = choices.filter { choice in
                        if screen.input?.other_option_id == choice._id {
                            return false
                        } else {
                            return selectedOptions.contains(choice._id ?? "")
                        }
                    }.compactMap({$0.title}).joined(separator: ",")
                    if let otherTextAnswer = otherTextAnswer {
                        rawAnswers += "," + otherTextAnswer
                    }
                    OneFlow.shared.eventManager.recordInternalEvent(
                        name: InternalEvent.questionAnswered,
                        parameters: [
                            InternalKey.questionId: screen._id,
                            InternalKey.stepId: screen._id,
                            InternalKey.flowId: self.surveyID as Any,
                            InternalKey.type: screen.input?.input_type as Any,
                            InternalKey.answer: rawAnswers,
                            InternalKey.questionTitle: screen.title as Any,
                            InternalKey.questionDescription: screen.message as Any,
                            InternalKey.surveyName: self.surveyName as Any,
                        ]
                    )
                }
                let answer = SurveySubmitRequest.Answer(screen_id: screen._id, answer_value: otherTextAnswer, answer_index: finalString)
                self.surveyResult.append(answer)
                self.presentNextScreen(answer.answer_index)
            }
        }
    }
    
    func followupViewEnterTextWith(_ text: String?) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            
            if let inputString = text, let screen = self.allScreens?[self.currentScreenIndex] {
                let finalString = inputString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                OneFlow.shared.eventManager.recordInternalEvent(
                    name: InternalEvent.questionAnswered,
                    parameters: [
                        InternalKey.questionId: screen._id,
                        InternalKey.stepId: screen._id,
                        InternalKey.flowId: self.surveyID as Any,
                        InternalKey.type: screen.input?.input_type as Any,
                        InternalKey.answer: inputString,
                        InternalKey.questionTitle: screen.title as Any,
                        InternalKey.questionDescription: screen.message as Any,
                        InternalKey.surveyName: self.surveyName as Any,
                    ]
                )
                if finalString.count > 0 {
                    let answer = SurveySubmitRequest.Answer(screen_id: screen._id, answer_value: inputString, answer_index: nil)
                    self.surveyResult.append(answer)
                } else {
                    if let screens = self.allScreens, screens.count == 1 {
                        if let completionEmptyText = self.recordEmptyTextCompletionBlock {
                            completionEmptyText()
                        }
                    } else if let screens = self.allScreens, screens.count <= 2, let lastScreen = screens.last, lastScreen.input?.input_type == "thank_you" {
                        if let completionEmptyText = self.recordEmptyTextCompletionBlock {
                            completionEmptyText()
                        }
                    }
                }
                self.view.endEditing(true)
                self.presentNextScreen(inputString)
            }
        }
    }
    
    func shortAnswerViewEnterTextWith(_ text: String?) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            
            if let inputString = text, let screen = self.allScreens?[self.currentScreenIndex] {
                let finalString = inputString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                OneFlow.shared.eventManager.recordInternalEvent(
                    name: InternalEvent.questionAnswered,
                    parameters: [
                        InternalKey.questionId: screen._id,
                        InternalKey.stepId: screen._id,
                        InternalKey.flowId: self.surveyID as Any,
                        InternalKey.type: screen.input?.input_type as Any,
                        InternalKey.answer: inputString,
                        InternalKey.questionTitle: screen.title as Any,
                        InternalKey.questionDescription: screen.message as Any,
                        InternalKey.surveyName: self.surveyName as Any,
                    ]
                )
                if finalString.count > 0 {
                    let answer = SurveySubmitRequest.Answer(screen_id: screen._id, answer_value: inputString, answer_index: nil)
                    self.surveyResult.append(answer)
                } else {
                    if let screens = self.allScreens, screens.count == 1 {
                        if let completionEmptyText = self.recordEmptyTextCompletionBlock {
                            completionEmptyText()
                        }
                    } else if let screens = self.allScreens, screens.count <= 2, let lastScreen = screens.last, lastScreen.input?.input_type == "thank_you" {
                        if let completionEmptyText = self.recordEmptyTextCompletionBlock {
                            completionEmptyText()
                        }
                    }
                }
                self.view.endEditing(true)
                self.presentNextScreen(inputString)
            }
        }
    }
    
    func starsViewChangeSelection(_ selectedIndex: Int?) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            if let index = selectedIndex, let screen = self.allScreens?[self.currentScreenIndex] {
                OneFlow.shared.eventManager.recordInternalEvent(
                    name: InternalEvent.questionAnswered,
                    parameters: [
                        InternalKey.questionId: screen._id,
                        InternalKey.stepId: screen._id,
                        InternalKey.flowId: self.surveyID as Any,
                        InternalKey.type: screen.input?.input_type as Any,
                        InternalKey.answer: "\(index)",
                        InternalKey.questionTitle: screen.title as Any,
                        InternalKey.questionDescription: screen.message as Any,
                        InternalKey.surveyName: self.surveyName as Any,
                    ]
                )
                let answer = SurveySubmitRequest.Answer(screen_id: screen._id, answer_value: "\(index)", answer_index: nil)
                self.surveyResult.append(answer)
                self.presentNextScreen(answer.answer_value)
            }
        }
    }
    
    func onThankyouAnimationComplete() {
        let shouldFadeAway = (self.allScreens?[self.currentScreenIndex].rules?.dismiss_behavior?.fades_away) ?? true
        if !shouldFadeAway {
            OneFlowLog.writeLog("End Screen logic : should not fade away as per survey logic")
            return
        }
        let delay = (self.allScreens?[self.currentScreenIndex].rules?.dismiss_behavior?.delay_in_seconds) ?? 0
        OneFlowLog.writeLog("End Screen logic : delay added for \(delay) seconds")

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1 + CGFloat(delay)) {
            if self.isClosingAnimationRunning == true {
                OneFlowLog.writeLog("End Screen logic : already closed so no animation and no need to check for end screen data logic")
                return
            }
            self.checkandPerformEndScreenAction()
        }
    }
    
    func followupTextViewHeightDidChange() {
        self.setupTopBottomIfNeeded()
        self.scrollView.scrollRectToVisible(CGRect(x: scrollView.contentSize.width - 1, y: scrollView.contentSize.height - 1, width: 1, height: 1), animated: false)
    }
    
    func onWelcomeNextTapped() {
        if let screen = self.allScreens?[self.currentScreenIndex] {
            OneFlow.shared.eventManager.recordInternalEvent(
                name: InternalEvent.flowStepClicked,
                parameters: [InternalKey.stepId: screen._id, InternalKey.flowId: surveyID as Any]
            )
        }

        if allScreens?.count == 1 {
            isSurveyFullyAnswered = true
            OneFlowLog.writeLog("only welcome screen. turning completed true", .verbose)
        }
        self.presentNextScreen("")
    }
}
extension OFRatingViewController: WebContainerDelegate {
    func webContainerDidLoadWith(_ contentHeight: CGFloat) {
        self.webContainerHeight.constant = contentHeight
        self.view.layoutIfNeeded()
        self.setupTopBottomIfNeeded()
    }
}
