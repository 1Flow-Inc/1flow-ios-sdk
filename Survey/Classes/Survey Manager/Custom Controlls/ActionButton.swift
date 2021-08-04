//
//  ActionButton.swift
//  Feedback
//
//  Created by Rohan Moradiya on 18/06/21.
//

import UIKit

enum ActionButtonStyle {
    case primary
    case secondary
    case done
    
    
}

class ActionButton: UIButton {

    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 10.0
    }
    var style: ActionButtonStyle = .primary {
        didSet{
            self.setupUI()
        }
    }
    var isActive: Bool = true {
        didSet{
            self.setupUI()
        }
    }
    
    private func setupUI() {
        switch style {
        case .primary:
            self.setTitleColor(UIColor.white, for: .normal)
            if isActive == true {
                self.backgroundColor = kPrimaryButtonEnableColor
                self.isUserInteractionEnabled = true
            } else {
                self.backgroundColor = kPrimaryButtonDisableColor
                self.isUserInteractionEnabled = false
            }
            break
        case .secondary:
            self.setTitleColor(UIColor.darkGray, for: .normal)
            self.backgroundColor = UIColor.clear
            break
        case .done:
            self.setTitleColor(UIColor.darkGray, for: .normal)
            self.backgroundColor = kDoneButtonColor
            break
        }
    }
    
    

}
