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
        self.contentHorizontalAlignment = .left
        self.contentVerticalAlignment = .top
        if type == .radioButton {
            let image = UIImage.getRadioButtonImage()
            self.setImage(image, for: .normal)
            let hightlighted = UIImage.getRadioButtonImageHighlighted()
            self.setImage(hightlighted, for: .highlighted)
            let selected = UIImage.getRadioButtonImageSelected()
            self.setImage(selected, for: .selected)
        } else {
            let image = UIImage.getCheckboxImage()
            self.setImage(image, for: .normal)
            let hightlighted = UIImage.getCheckboxImageHighlighted()
            self.setImage(hightlighted, for: .highlighted)
            let selected = UIImage.getCheckboxImageSelected()
            self.setImage(selected, for: .selected)
        }
        self.setTitleColor(UIColor.black, for: .normal)
        self.layer.borderWidth = 0.5
        self.layer.borderColor = kBorderColor.cgColor
        self.layer.cornerRadius = 2.0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageEdgeInsets = UIEdgeInsets(top: 15, left: 14, bottom: 0, right: 0)
        self.titleEdgeInsets = UIEdgeInsets(top: 12, left: 28, bottom: 12, right: 12)
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
        if self.isHighlighted == true {
            self.layer.borderColor = kPrimaryColor.cgColor
        } else if self.isSelected == true {
            self.layer.borderColor = kPrimaryColor.cgColor

        } else {
            self.layer.borderColor = kBorderColor.cgColor
        }
    }
    
    override var isSelected: Bool {
        didSet {
            self.setupButtonStyle()
        }
    }
    
    

}
