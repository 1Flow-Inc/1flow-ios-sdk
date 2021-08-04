//
//  RatingViewController.swift
//  Feedback
//
//  Created by Rohan Moradiya on 16/06/21.
//

import UIKit

enum RatingStyle {
    case OneToTen
    case Stars
    case Emoji
    case MCQ
    case FollowUp
    case ReviewPrompt
    case ThankYou
}

typealias RatingViewCompletion = ((_ answerValue:String?, _ answerIndex: Int?, _ isSubmitted: Bool) -> Void)

class RatingViewController: UIViewController {
    
    @IBOutlet weak var ratingView: RoundedConrnerView!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var viewPrimaryTitle1: UIView!
    @IBOutlet weak var viewPrimaryTitle2: UIView!
    @IBOutlet weak var viewSecondaryTitle: UIView!
    @IBOutlet weak var viewPrimaryButton: UIView!
    @IBOutlet weak var viewSecondaryButton: UIView!
    @IBOutlet weak var viewDoneButton: UIView!
    
    @IBOutlet weak var lblPrimaryTitle1: UILabel!
    @IBOutlet weak var lblPrimaryTitle2: UILabel!
    @IBOutlet weak var lblSecondaryTitle: UILabel!
    @IBOutlet weak var btnPrimary: ActionButton!
    @IBOutlet weak var btnSecondary: ActionButton!
    @IBOutlet weak var btnDone: ActionButton!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    private var isKeyboardVisible = false
    var panGestureRecognizer: UIPanGestureRecognizer?
    var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?
    
    var screen: SurveyListResponse.Survey.Screen?
    
    var selectedValue: String?
    
    var selectedIndex: Int? {
        didSet {
            if selectedIndex != nil {
                self.btnPrimary.isActive = true
            } else {
                self.btnPrimary.isActive = false
            }
        }
    }
    
    var enteredText: String? {
        didSet {
            if enteredText?.count ?? 0 > screen?.input.min_chars ?? 0 {
                self.btnPrimary.isActive = true
            } else {
                self.btnPrimary.isActive = false
            }
        }
    }
    
    var completionBlock: RatingViewCompletion?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUIAccordingToConfiguration()
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        ratingView.addGestureRecognizer(panGestureRecognizer!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil);
    }
    
    @objc func keyboardWasShown(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.isKeyboardVisible = true
        self.bottomConstraint.constant = keyboardFrame.size.height //+ 20
        self.ratingView.setNeedsUpdateConstraints()
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.isKeyboardVisible = false
        
        self.bottomConstraint.constant = 0
        self.ratingView.setNeedsUpdateConstraints()
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func setupUIAccordingToConfiguration() {
        
        guard let currentScreen = screen else {
            return
        }

        if let value = screen?.title {
            self.viewPrimaryTitle1.isHidden = false
            self.lblPrimaryTitle1.text = value
        } else {
            self.viewPrimaryTitle1.isHidden = true
        }
        self.viewPrimaryTitle2.isHidden = true

        if let value = screen?.message {
            self.viewSecondaryTitle.isHidden = false
            self.lblSecondaryTitle.text = value
        } else {
            self.viewSecondaryTitle.isHidden = true
        }

        if let primaryButton = screen?.buttons.first(where: { $0.button_type == "primary" }) {
            self.viewPrimaryButton.isHidden = false
            self.btnPrimary.setTitle(primaryButton.title, for: .normal)
            self.btnPrimary.style = .primary
            self.btnPrimary.isActive = false
        } else {
            self.viewPrimaryButton.isHidden = true
        }

        if let secondaryButton = screen?.buttons.first(where: { $0.button_type == "secondary" }) {
            self.viewSecondaryButton.isHidden = false
            self.btnSecondary.setTitle(secondaryButton.title, for: .normal)
            self.btnSecondary.style = .secondary
            self.btnSecondary.isActive = true
        } else {
            self.viewSecondaryButton.isHidden = true
        }

        if let doneButton = screen?.buttons.first(where: { $0.button_type == "done" }) {
            self.viewDoneButton.isHidden = false
            self.btnDone.setTitle(doneButton.title, for: .normal)
            self.btnDone.style = .done
            self.btnDone.isActive = true
        } else {
            self.viewDoneButton.isHidden = true
        }
        
        if currentScreen.input.input_type == "text" {
            let view = FollowupView.loadFromNib()
            view.delegate = self
            view.placeHolderText = currentScreen.input.placeholder_text ?? "Write here..."
            view.maxCharsAllowed = currentScreen.input.max_chars ?? 1000
            self.stackView.insertArrangedSubview(view, at: 3)
        } else if currentScreen.input.input_type == "rating" {
            
            if currentScreen.input.stars == true {
                let view = StarsView.loadFromNib()
                view.delegate = self
                self.stackView.insertArrangedSubview(view, at: 3)
            } else if currentScreen.input.emoji == true {
                let view = EmojiView.loadFromNib()
                view.delegate = self
                self.stackView.insertArrangedSubview(view, at: 3)
            } else {
                let view = OneToTenView.loadFromNib()
                view.minValue = currentScreen.input.min_val ?? 1
                view.maxValue = currentScreen.input.max_val ?? 5
                view.delegate = self
                self.stackView.insertArrangedSubview(view, at: 3)
            }
        } else if currentScreen.input.input_type == "mcq" {
            let view = MCQView.loadFromNib()
            view.delegate = self
            if let titleArray = currentScreen.input.choices?.map({ return $0.title }) {
                view.setupViewWithOptions(titleArray)
            }
            self.stackView.insertArrangedSubview(view, at: 3)
        } else if currentScreen.input.input_type == "reviewPrompt" {
            self.btnPrimary.isActive = true
        } else {
            //ThankYou
        }
        
    }
    
    func animateRatingView() {
        let originalPosition = self.ratingView.frame.origin.y
        ratingView.frame.origin.y = self.view.frame.size.height
        ratingView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.ratingView.frame.origin.y = originalPosition
        }
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
                                    self.closeFeedbackView()
                                    guard let completion = self.completionBlock else { return }
                                    if self.screen?.input.input_type == "thank_you" {
                                        completion(nil, nil, true)
                                    } else {
                                        completion(nil, nil, false)
                                    }
                                    
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
        guard let completion = self.completionBlock else { return }
        self.view.backgroundColor = UIColor.clear
        self.closeFeedbackView()
        if self.screen?.input.input_type == "thank_you" {
            completion(nil, nil, true)
        } else {
            completion(nil, nil, false)
        }
    }
    
    @IBAction func onPrimaryButton(_ sender: UIButton) {
        guard let completion = self.completionBlock else { return }
        self.closeFeedbackView()
        if self.selectedValue != nil {
            //For MCQ it will required multiple type
            completion(self.selectedValue, self.selectedIndex, true)
        } else {
            completion(self.enteredText, self.selectedIndex, true)
        }
        
    }
    
    @IBAction func onSecondaryButton(_ sender: UIButton) {
        guard let completion = self.completionBlock else { return }
        self.closeFeedbackView()
        completion(nil, nil, true)
    }
    
    @IBAction func onDoneButton(_ sender: UIButton) {
        guard let completion = self.completionBlock else { return }
        self.closeFeedbackView()
        completion(nil, nil, true)
    }
    
    func closeFeedbackView() {
        self.dismiss(animated: false, completion: nil)
    }
}

extension RatingViewController: RatingViewProtocol {
    
    func oneToTenViewChangeSelection(_ selectedIndex: Int?) {
        self.selectedIndex = selectedIndex
    }
    
    func oneToFiveViewChangeSelection(_ selectedIndex: Int?) {
        self.selectedIndex = selectedIndex
    }
    
    func starsViewChangeSelection(_ selectedIndex: Int?) {
        self.selectedIndex = selectedIndex
    }
    
    func emojiViewChangeSelection(_ selectedIndex: Int?) {
        self.selectedIndex = selectedIndex
    }
    
    func mcqViewChangeSelection(_ selectedIndex: Int?, selectedValue: String?) {
        self.selectedIndex = selectedIndex
        self.selectedValue = selectedValue
    }
    
    func followupViewEnterTextWith(_ text: String?) {
        self.enteredText = text
    }
}
