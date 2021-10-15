//
//  NumberButton.swift
//  Feedback
//
//  Created by Rohan Moradiya on 19/06/21.
//

import UIKit

class NumberButton: UIButton {

    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setTitleColor(UIColor.white, for: .selected)
        self.setTitleColor(UIColor.black, for: .normal)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setTitleColor(UIColor.white, for: .selected)
        self.setTitleColor(UIColor.black, for: .normal)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override var isHighlighted: Bool {
        didSet {
            if self.isSelected == false {
                self.layer.backgroundColor = isHighlighted ? kPrimaryHightlightColor.cgColor : UIColor.white.cgColor
            }
        }
    }
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if isSelected == true {
            self.layer.backgroundColor = kPrimaryColor.cgColor
            
        } else {
            self.layer.backgroundColor = UIColor.clear.cgColor
        }
        
    }
}
