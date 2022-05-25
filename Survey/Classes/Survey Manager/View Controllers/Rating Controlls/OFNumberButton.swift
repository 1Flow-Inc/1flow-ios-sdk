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
@objc(OBJCOFNumberButton)
class OFNumberButton: UIButton {

    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    var isEmoji = false
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setTitleColor(UIColor.white, for: .selected)
        self.setTitleColor(kPrimaryTitleColor, for: .normal)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setTitleColor(UIColor.white, for: .selected)
        self.setTitleColor(kPrimaryTitleColor, for: .normal)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override var isHighlighted: Bool {
        didSet {
            if self.isSelected == false {
                self.layer.backgroundColor = isHighlighted ? kBrandHightlightColor.cgColor : kOptionBackgroundColor.cgColor
            }
        }
    }
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if isEmoji {
            self.layer.cornerRadius = rect.width/2
            if isSelected == true {
                self.layer.backgroundColor = kBrandColor.cgColor
                
            } else {
                self.layer.backgroundColor =  UIColor.clear.cgColor
            }
        }
        else {
            self.layer.cornerRadius = 5.0
            if isSelected == true {
                self.layer.backgroundColor = kBrandColor.cgColor
                
            } else {
                self.layer.backgroundColor =  kOptionBackgroundColor.cgColor
            }
        }
        
        
    }
}
