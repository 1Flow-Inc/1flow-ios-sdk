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

@objc(OBJCOFStarsView)
class OFStarsView: UIView {

    @IBOutlet weak var stackView1: UIStackView!
    @IBOutlet weak var ratingText: UILabel!

    weak var delegate: OFRatingViewDelegate?
    private var ratingTextArray = [
        "Very dissatisfied",
        "Somewhat dissatisfied",
        "Not dissatisfied nor satisfied",
        "Somewhat satisfied",
        "Very satisfied"
    ]
    var ratingDic = ["": ""] {
        didSet {
            if let defaultText = ratingDic["0"] {
                self.ratingText.text = defaultText
            }
            if let firstOption = ratingDic["1"] {
                self.ratingTextArray[0] = firstOption
            }
            if let secondOption = ratingDic["2"] {
                self.ratingTextArray[1] = secondOption
            }
            if let thirdOption = ratingDic["3"] {
                self.ratingTextArray[2] = thirdOption
            }
            if let fourthOption = ratingDic["4"] {
                self.ratingTextArray[3] = fourthOption
            }
            if let fifthOption = ratingDic["5"] {
                self.ratingTextArray[4] = fifthOption
            }
        }
    }

    var selectedButton: UIButton? {
        didSet {
            self.delegate?.starsViewChangeSelection(selectedButton?.tag ?? nil)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(checkGestureAction(_:)))
        self.stackView1.addGestureRecognizer(gesture)
        self.setupImages()
        self.ratingText.textColor = kFooterColor
        self.ratingText.font = OneFlow.fontConfiguration?.openTextCharCountFont
    }

    func setupImages() {
        let emptyImage = UIImage(named: "unSelectedStar", in: OneFlowBundle.bundleForObject(self), compatibleWith: nil)
        let filledImage = UIImage(named: "selectedStar", in: OneFlowBundle.bundleForObject(self), compatibleWith: nil)
        for view in self.stackView1.arrangedSubviews {
            if let btn = view as? UIButton {
                btn.setImage(emptyImage, for: .normal)
                btn.setImage(filledImage, for: .selected)
            }
        }
    }

    @IBAction func onSelectButton(_ sender: UIButton) {
        self.isUserInteractionEnabled = false
        let index = sender.tag
        if index <= ratingTextArray.count {
            ratingText.text = ratingTextArray[index-1]
        }
        _ = self.stackView1.arrangedSubviews.map { view in
            if let btn = view as? UIButton {
                if btn.tag <= index {
                    btn.isSelected = true
                } else {
                    btn.isSelected = false
                }
            }
        }
        self.selectedButton = sender
    }

    @objc func checkGestureAction(_ sender: UIPanGestureRecognizer) {
        if sender.state == .changed {
            let location = sender.location(in: self.stackView1)
            let filteredSubviews = self.stackView1.subviews.filter { subView -> Bool in
                return subView.frame.contains(location)
            }
            guard let subviewTapped = filteredSubviews.first else {
                return
            }
            let index = subviewTapped.tag
            if index <= ratingTextArray.count {
                ratingText.text = ratingTextArray[index-1]
            }
            _ = self.stackView1.arrangedSubviews.map { view in
                if let btn = view as? UIButton {
                    if btn.tag <= index {
                        btn.isSelected = true
                    } else {
                        btn.isSelected = false
                    }
                }
            }
        } else if sender.state == .ended {
            if let temp = self.stackView1.arrangedSubviews.last(where: { view in
                if let btn = view as? UIButton {
                    return btn.isSelected == true
                } else {
                    return false
                }
            }) {
                guard let senderButton = temp as? UIButton else {
                    return
                }
                self.onSelectButton(senderButton)
            }
        }
    }
}
