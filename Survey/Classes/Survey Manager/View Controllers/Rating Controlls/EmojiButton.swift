//
//  EmojiButton.swift
//  Feedback
//
//  Created by Rohan Moradiya on 19/06/21.
//

import UIKit

class EmojiButton: UIButton {
    
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 10.0
//        self.layer.borderWidth = 1.0
//        self.layer.borderColor = UIColor.lightGray.cgColor
        self.setTitleColor(UIColor.black, for: .selected)
        self.setTitleColor(UIColor.black, for: .normal)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if isSelected == true {
            self.layer.backgroundColor = kDoneButtonColor.cgColor
            
        } else {
            self.layer.backgroundColor = UIColor.clear.cgColor
            
            
        }
        
    }
}
