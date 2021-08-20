//
//  OFRadioButton.swift
//  Feedback
//
//  Created by Rohan Moradiya on 16/08/21.
//

import UIKit

class OFRadioButton: UIButton {

    
    enum OFRadioButtonType {
        case radioButton
        case checkBox
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    init(frame: CGRect, type: OFRadioButtonType) {
        super.init(frame: frame)
        self.radioButtonType = type
        self.contentHorizontalAlignment = .left
        self.contentVerticalAlignment = .top
        let frameworkBundle = Bundle(for: self.classForCoder)
        if type == .radioButton {
            self.setImage(UIImage(named: "RadioButton", in: frameworkBundle, compatibleWith: nil), for: .normal)
            self.setImage(UIImage(named: "RadioButton_Highlighted", in: frameworkBundle, compatibleWith: nil), for: .highlighted)
            self.setImage(UIImage(named: "RadioButton_Selected", in: frameworkBundle, compatibleWith: nil), for: .selected)
        } else {
            self.setImage(UIImage(named: "Checkbox", in: frameworkBundle, compatibleWith: nil), for: .normal)
            self.setImage(UIImage(named: "Checkbox_Highlighted", in: frameworkBundle, compatibleWith: nil), for: .highlighted)
            self.setImage(UIImage(named: "Checkbox_Selected", in: frameworkBundle, compatibleWith: nil), for: .selected)
        }
//        self.contentMode = .left
        self.setTitleColor(UIColor.black, for: .normal)
        self.layer.borderWidth = 0.5
        self.layer.borderColor = kBorderColor.cgColor
        self.layer.cornerRadius = 2.0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageEdgeInsets = UIEdgeInsets(top: 15, left: 14, bottom: 0, right: 0)
        self.titleEdgeInsets = UIEdgeInsets(top: 12, left: 28, bottom: 12, right: 0)
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
            self.layer.borderColor = kPrimaryButtonEnableColor.cgColor
        } else if self.isSelected == true {
            self.layer.borderColor = kPrimaryButtonEnableColor.cgColor

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
