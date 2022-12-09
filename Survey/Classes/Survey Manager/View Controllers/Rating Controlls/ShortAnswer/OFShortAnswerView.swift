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

@objc(OBJCOFShortAnswerView)
class OFShortAnswerView: UIView {

    @IBOutlet weak var btnFinish: UIButton!
    @IBOutlet weak var textField: UITextField!
    weak var delegate: OFRatingViewProtocol?

    var minCharsAllowed = 5 {
        didSet {
            if minCharsAllowed == 0 {
                self.btnFinish.alpha = 1.0
                self.btnFinish.isHidden = false
                btnFinish.backgroundColor = kBrandColor
                btnFinish.isUserInteractionEnabled = true
            }
        }
    }

    var placeHolderText = "Write here..." {
        didSet {
            if !placeHolderText.isEmpty {
                //self.textField.placeholder = placeHolderText
                self.textField.attributedPlaceholder = NSAttributedString(
                    string: placeHolderText,
                    attributes: [NSAttributedString.Key.foregroundColor: kPlaceholderColor, NSAttributedString.Key.font: OneFlow.fontConfiguration?.textFieldFont ?? UIFont.systemFont(ofSize: 14)]
                )
            }
        }
    }
    var enteredText: String? {
        didSet {
            if enteredText?.count ?? 0 >= minCharsAllowed {
                btnFinish.backgroundColor = kBrandColor
                btnFinish.isUserInteractionEnabled = true

            } else {
                btnFinish.backgroundColor = kSubmitButtonColorDisable
                btnFinish.isUserInteractionEnabled = false

            }
        }
    }
    var submitButtonTitle : String = "Submit Feedback" {
        didSet {
            btnFinish.setTitle(self.submitButtonTitle, for: .normal)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        btnFinish.layer.cornerRadius = 5.0
        btnFinish.isHidden = false
        btnFinish.backgroundColor = kSubmitButtonColorDisable
        btnFinish.isUserInteractionEnabled = false
        btnFinish.titleLabel?.font = OneFlow.fontConfiguration?.submitButtonFont
        setupTextFieldAppreance()
        textField.delegate = self
        textField.addTarget(self, action: #selector(OFShortAnswerView.textFieldDidChange(_:)),
                                      for: .editingChanged)
        textField.font = OneFlow.fontConfiguration?.textFieldFont
       
    }
    
    private func setupTextFieldAppreance() {
        textField.textColor = kPrimaryTitleColor
        textField.backgroundColor = UIColor.clear
        textField.layer.borderWidth = 0.5
        textField.layer.borderColor = kBorderColor.cgColor
        textField.layer.cornerRadius = 2.0
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        self.enteredText = textField.text
    }
    
    @IBAction func onFinished(_ sender: UIButton) {
        if let text = self.textField.text, text.count >= minCharsAllowed {
            self.isUserInteractionEnabled = false
            self.delegate?.shortAnswerViewEnterTextWith(text)
        }
    }
}


extension OFShortAnswerView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}
