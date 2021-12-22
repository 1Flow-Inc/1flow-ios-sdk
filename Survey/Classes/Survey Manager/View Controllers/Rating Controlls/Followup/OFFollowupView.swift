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
    weak var delegate: OFRatingViewProtocol?
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    var maxCharsAllowed = 1000 {
        didSet {
            self.lblNumbers.text = "\(self.enteredText?.count ?? 0)/\(self.maxCharsAllowed)"
        }
    }
    var minCharsAllowed = 5
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
            if enteredText?.count ?? 0 > minCharsAllowed {
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
        btnFinish.backgroundColor = kPrimaryColor
        btnFinish.layer.cornerRadius = 2.0
    }
    
    @IBAction func onFinished(_ sender: UIButton) {
        if let text = self.enteredText, text.count > minCharsAllowed {
            self.delegate?.followupViewEnterTextWith(text)
        }
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
        let newHeight = newSize.height > 90 ? newSize.height : 90
        
        if let frame = textView.superview?.superview?.superview?.superview?.frame {
            if (frame.origin.y > 80) || (newHeight < textView.bounds.height) {
                self.textViewHeightConstraint.constant = newHeight
            }
        }
    }
    
}
