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

@objc(OBJCOFFollowupView)
class OFFollowupView: UIView {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var lblNumbers: UILabel!
    @IBOutlet weak var btnFinish: UIButton!
    @IBOutlet weak var skipButton: UIButton!

    weak var delegate: OFRatingViewProtocol?
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    var maxCharsAllowed = 1000 {
        didSet {
            self.lblNumbers.text = "\(self.enteredText?.count ?? 0)/\(self.maxCharsAllowed)"
        }
    }
    var minCharsAllowed = 5 {
        didSet {
            if minCharsAllowed == 0 {
                self.btnFinish.alpha = 1.0
                self.btnFinish.isHidden = false
                btnFinish.backgroundColor = kPrimaryColor
                btnFinish.isUserInteractionEnabled = true
            }
        }
    }
    var placeHolderText = "Write here..." {
        didSet {
            self.placeholderLabel.text = placeHolderText
            self.placeholderLabel.sizeToFit()
        }
    }
    var placeholderLabel : UILabel!
    var enteredText: String? {
        didSet {
            self.lblNumbers.text = "\(self.enteredText?.count ?? 0)/\(self.maxCharsAllowed)"
            if enteredText?.count ?? 0 >= minCharsAllowed {
                btnFinish.backgroundColor = kPrimaryColor
                btnFinish.isUserInteractionEnabled = true

            } else {
                btnFinish.backgroundColor = kSubmitButtonBGColor
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
        textView.delegate = self
        textView.layer.borderColor = kBorderColor.cgColor
        textView.layer.borderWidth = 0.5
        textView.layer.cornerRadius = 2.0
        placeholderLabel = UILabel()
        placeholderLabel.text = placeHolderText
        placeholderLabel.font = UIFont.systemFont(ofSize: (textView.font?.pointSize)!)
        placeholderLabel.sizeToFit()
        textView.addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPoint(x: 5, y: (textView.font?.pointSize)! / 2)
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.isHidden = !textView.text.isEmpty
        btnFinish.layer.cornerRadius = 5.0
        btnFinish.isHidden = false
        btnFinish.backgroundColor = kSubmitButtonBGColor
        btnFinish.isUserInteractionEnabled = false
        
        let skipAttributes: [NSAttributedString.Key: Any] = [
             .font: UIFont.systemFont(ofSize: 14),
             .foregroundColor: UIColor.colorFromHex("50555C"),
             .underlineStyle: NSUnderlineStyle.single.rawValue
         ] //
        
        let attributeString = NSMutableAttributedString(
                string: "Skip",
                attributes: skipAttributes
             )
        self.skipButton.setTitleColor(UIColor.colorFromHex("50555C"), for: .normal)
        self.skipButton.setTitle("Skip", for: .normal)
        self.skipButton.setAttributedTitle(attributeString, for: .normal)
    }
    
    @IBAction func onFinished(_ sender: UIButton) {
        if let text = textView.text, text.count >= minCharsAllowed {
            self.isUserInteractionEnabled = false
            self.delegate?.followupViewEnterTextWith(text)
        }
    }
    
    @IBAction func onSkip(_ sender: UIButton) {
        self.isUserInteractionEnabled = false
        self.delegate?.followupViewEnterTextWith("")
    }
}

extension OFFollowupView: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let finalText = textView.text + text
        if finalText.count > maxCharsAllowed {
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        self.enteredText = textView.text
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newHeight = newSize.height > 109 ? newSize.height : 109
        
        if let frame = textView.superview?.superview?.superview?.superview?.superview?.frame {
            if (frame.origin.y > 80) || (newHeight < textView.bounds.height) {
                self.textViewHeightConstraint.constant = newHeight
            }
        }
    }
}
