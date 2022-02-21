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

@objc(OBJCOFMCQView)
class OFMCQView: UIView {

    @IBOutlet weak var stackView1: UIStackView!

    weak var delegate: OFRatingViewProtocol?
    @IBOutlet weak var btnFinish: UIButton!
    var currentType:  OFRadioButton.OFRadioButtonType = OFRadioButton.OFRadioButtonType.radioButton
    var allOptions: [Codable]?
    var otherOptionID = ""

    let textFieldViewTag = 1001
    let enterButtonTag = 1002

    var otherOptionTF: UITextField!
    var otherOptionAnswer = ""
    var parentWidth = 0.0

    var selectedButton: UIButton? {
        didSet {
            if self.currentType == .radioButton, self.selectedButton != nil {
                if let selectedBtn = self.selectedButton {
                    let selectedOption = self.allOptions![selectedBtn.tag]
                    if let option : SurveyListResponse.Survey.Screen.Input.Choice = selectedOption as? SurveyListResponse.Survey.Screen.Input.Choice, let optionID : String  = option._id {
                        if optionID == self.otherOptionID  {
                            if !otherOptionAnswer.isEmpty {
                                self.delegate?.mcqViewChangeSelection(optionID, otherOptionAnswer)
                            }
                        } else {
                            self.delegate?.mcqViewChangeSelection(optionID, nil)
                        }
                    }
                }
            }
        }
    }
   
    func setupViewWithOptions(_ options: [Codable], type: OFRadioButton.OFRadioButtonType, parentViewWidth: CGFloat, _ otherOptionIdentifier : String?) {
        self.currentType = type
        self.allOptions = options
        parentWidth = parentViewWidth
        if type == .checkBox {
            btnFinish.backgroundColor = kPrimaryColor
            btnFinish.layer.cornerRadius = 2.0
        }
        
        if let otherOptionId : String = otherOptionIdentifier {
            self.otherOptionID = otherOptionId
        }
        
        while let first = stackView1.arrangedSubviews.first {
            stackView1.removeArrangedSubview(first)
                first.removeFromSuperview()
        }
        
        for i in 0..<options.count {
            let currentOption = options[i]
           
            if let option : SurveyListResponse.Survey.Screen.Input.Choice = currentOption as? SurveyListResponse.Survey.Screen.Input.Choice, let optionString : String  = option.title {
              
                let button = OFRadioButton(frame: CGRect(x: 0, y: 0, width: parentViewWidth, height: 42), type: type)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
                button.titleLabel?.lineBreakMode = .byWordWrapping
                
                button.setTitle(optionString, for: .normal)
                button.tag = i
                button.addTarget(self, action: #selector(onSelectButton(_:)), for: .touchUpInside)
                
                
                self.stackView1.addArrangedSubview(button)
                let height = self.labelSize(for: optionString, maxWidth: (parentViewWidth - 54))
                button.translatesAutoresizingMaskIntoConstraints = false
                button.heightAnchor.constraint(equalToConstant: height + 24).isActive = true
            }
        }
        
  
    }
    
    
    func addTextFieldToView(_ button : UIButton) {
        let otherOptionView = UIView.init(frame: CGRect(x: 42, y: 0, width: button.frame.size.width - 50 , height: button.frame.size.height))
        otherOptionView.backgroundColor = .clear
        otherOptionView.tag = textFieldViewTag
        
        let otherOptionTextField =  UITextField(frame: CGRect(x: 0, y: 0, width: otherOptionView.frame.size.width - 60 , height: otherOptionView.frame.size.height))
        otherOptionTextField.placeholder = "Type your answer"
        otherOptionTextField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        otherOptionTextField.borderStyle = UITextField.BorderStyle.none
        otherOptionTextField.keyboardType = UIKeyboardType.default
        otherOptionTextField.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        otherOptionTextField.delegate = self
        otherOptionTextField.text = otherOptionAnswer
        otherOptionTF = otherOptionTextField
        
        let enterButton = UIButton(frame: CGRect(x: otherOptionView.frame.size.width - 50, y: 8, width: 50, height: 28))
        enterButton.backgroundColor = kPrimaryColor
        enterButton.setTitle("Enter", for: .normal)
        enterButton.addTarget(self, action: #selector(enterButtonTapped), for: .touchUpInside)
        enterButton.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        if let enterIcon : UIImage = UIImage.init(named: "Enter", in: OneFlowBundle.bundleForObject(self), compatibleWith: nil) {
            enterButton.setImage(enterIcon, for: .normal)
        }
        enterButton.semanticContentAttribute = .forceRightToLeft
        enterButton.tag = enterButtonTag
        
        otherOptionView.addSubview(otherOptionTextField)
        otherOptionView.addSubview(enterButton)
        enterButton.layer.cornerRadius = 2.0
        button.addSubview(otherOptionView)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            otherOptionTextField.becomeFirstResponder()
        }
    }
    
    @objc func enterButtonTapped(sender: UIButton!) {
        if let _ = otherOptionTF {
            otherOptionAnswer = otherOptionTF.text!
            if otherOptionAnswer.isEmpty {
                if let optionButton = sender.superview?.superview as? UIButton {
                    onSelectButton(optionButton)
                }
            } else {
                if let optionButton = sender.superview?.superview as? UIButton {
                    if let otherOptionView = optionButton.viewWithTag(textFieldViewTag) {
                        otherOptionView.removeFromSuperview()
                    }
                    optionButton.setTitle(otherOptionAnswer, for: .normal)
                    self.setHeightForButton(optionButton)
                    if self.currentType == .radioButton {
                        self.selectedButton?.isSelected = false
                        self.selectedButton = optionButton
                    } else {
                        self.setupFinishButton()
                    }
                }
            }
        }
    }
    
    func addTextFieldIfRequired(_ sender: UIButton){
        if self.checkIfOptionNeedsTextAnswer(sender) {
            sender.setTitle("", for: .normal)
            self.setHeightForButton(sender)
            self.addTextFieldToView(sender)
        }
    }
    
    func setUnselectedButtonTitle(_ sender: UIButton){
        if sender.tag < self.allOptions!.count {
            let selectedOption = self.allOptions![sender.tag]
            if let option : SurveyListResponse.Survey.Screen.Input.Choice = selectedOption as? SurveyListResponse.Survey.Screen.Input.Choice, let optionName : String  = option.title, let optionID : String  = option._id  {
                if optionID == self.otherOptionID  {
                   // otherOptionAnswer = ""
                    sender.setTitle(optionName, for: .normal)
                    self.setHeightForButton(sender)
                    if let otherOptionView = sender.viewWithTag(textFieldViewTag) {
                        otherOptionView.removeFromSuperview()
                    }
                }
            }
        }
    }
    
    func checkIfOptionNeedsTextAnswer(_ sender: UIButton) -> Bool{
        if sender.tag < self.allOptions!.count {
            let selectedOption = self.allOptions![sender.tag]
            if let option : SurveyListResponse.Survey.Screen.Input.Choice = selectedOption as? SurveyListResponse.Survey.Screen.Input.Choice, let optionID : String  = option._id {
                if optionID == self.otherOptionID  {
                    return true
                }
            }
        }
        return false
    }
    
    func setHeightForButton(_ button : UIButton ) {
        if var buttonTitle = button.title(for: .normal) {
            if buttonTitle.isEmpty {
                buttonTitle = "Dummy Text"
            }
            let newHeight = self.labelSize(for: buttonTitle, maxWidth: (parentWidth - 54))
            button.constraints.forEach { (constraint) in
                 if constraint.firstAttribute == .height
                 {
                     constraint.constant = newHeight + 24
                 }
             }
        }
    }
    
    func labelSize(for text: String, maxWidth: CGFloat) -> CGFloat {
        
        let label =  UILabel(frame: CGRect(x: 0, y: 0, width: maxWidth, height: .greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.text = text
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.sizeToFit()
        return label.frame.height
    }
    
    func setupFinishButton() {
        if self.currentType == .checkBox {
            var isAnySelected = false
            for view in self.stackView1.arrangedSubviews {
                if let btn = view as? UIButton {
                    if btn.isSelected == true {
                        if self.checkIfOptionNeedsTextAnswer(btn) {
                            if !otherOptionAnswer.isEmpty {
                                isAnySelected = true
                                break
                            }
                        } else {
                            isAnySelected = true
                            break
                        }
                    }
                }
            }
            if isAnySelected == true {
                if self.btnFinish.isHidden == true {
                    self.btnFinish.alpha = 0.0
                    self.btnFinish.isHidden = false
                    UIView.animate(withDuration: 0.5) {
                        self.btnFinish.alpha = 1.0
                    }
                }
            } else {
                if self.btnFinish.isHidden == false {
                    UIView.animate(withDuration: 0.5) {
                        self.btnFinish.alpha = 0.0
                    } completion: { _ in
                        self.btnFinish.isHidden = true
                    }
                }
            }
        }
    }
    
    @IBAction func onFinishTaped(_ sender: UIButton) {
        var selectedOptionIDs = [String]()
        var isOtherOptionSelected = false
        for view in self.stackView1.arrangedSubviews {
            if let btn = view as? UIButton {
                if btn.isSelected == true {
                    let selectedOption = self.allOptions![btn.tag]
                    if let option : SurveyListResponse.Survey.Screen.Input.Choice = selectedOption as? SurveyListResponse.Survey.Screen.Input.Choice, let optionID : String  = option._id {
                        if optionID == self.otherOptionID  {
                            if !otherOptionAnswer.isEmpty {
                                isOtherOptionSelected = true
                                selectedOptionIDs.append(optionID)
                            }
                        }
                        else {
                            selectedOptionIDs.append(optionID)
                        }
                    }
                }
            }
        }
        self.delegate?.checkBoxViewDidFinishPicking(selectedOptionIDs,  isOtherOptionSelected ? otherOptionAnswer : nil)
        
    }
    

    @IBAction func onSelectButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if self.currentType == .radioButton {
            self.selectedButton?.isSelected = false
            if sender.isSelected == true {
                if !self.checkIfOptionNeedsTextAnswer(sender) {
                    self.selectedButton = sender
                }
            } else {
                self.selectedButton = nil
            }
        } else {
            self.setupFinishButton()
        }
        if sender.isSelected {
            self.addTextFieldIfRequired(sender)
        }
        else {
            self.setUnselectedButtonTitle(sender)
        }
        
    }
}

extension OFMCQView : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        if let enterButton : UIButton = textField.superview?.viewWithTag(self.enterButtonTag) as? UIButton {
            self.enterButtonTapped(sender: enterButton)
        }
        return true
    }
}

