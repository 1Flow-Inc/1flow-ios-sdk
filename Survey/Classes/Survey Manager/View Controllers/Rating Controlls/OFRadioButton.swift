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

class OFRadioButton: UIButton {
    enum OFRadioButtonType {
        case radioButton
        case checkBox
    }
    
    init(frame: CGRect, type: OFRadioButtonType) {
        super.init(frame: frame)
        self.radioButtonType = type
        if #available(iOS 11.0, *) {
            self.contentHorizontalAlignment = .leading
        } else {
            // Fallback on earlier versions
            self.contentHorizontalAlignment = .left
        }
        self.contentVerticalAlignment = .center
        self.layer.cornerRadius = 5.0
        self.setupButtonStyle()

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 12)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var radioButtonType: OFRadioButtonType = .radioButton
    
    override var isHighlighted: Bool {
        didSet {
            self.setupButtonStyle()
        }
    }
    
    func setupButtonStyle() {
        self.layer.borderWidth = 0

        if self.radioButtonType == .radioButton {
            if self.isHighlighted == true {
                
            } else if self.isSelected == true {
                self.layer.backgroundColor = kBrandColor.cgColor
                self.setTitleColor(UIColor.white, for: .normal)

            } else {
                self.layer.backgroundColor = kOptionBackgroundColor.cgColor
                self.setTitleColor(kPrimaryTitleColor, for: .normal)

            }
        }
        else {
            if self.isHighlighted == true {
                self.layer.backgroundColor = kOptionBackgroundColorHightlighted.cgColor
                self.setTitleColor(kPrimaryTitleColor, for: .normal)
                
            } else if self.isSelected == true {
                self.layer.borderWidth = CGFloat(2.0)
                self.layer.borderColor = kBrandColor.cgColor
                self.layer.backgroundColor = kOptionBackgroundColorHightlighted.cgColor
                self.setTitleColor(kPrimaryTitleColor, for: .normal)

            } else {
                self.layer.backgroundColor = kOptionBackgroundColor.cgColor
                self.setTitleColor(kPrimaryTitleColor, for: .normal)
            }
        }
    }

    override var isSelected: Bool {
        didSet {
            self.setupButtonStyle()
        }
    }
}
