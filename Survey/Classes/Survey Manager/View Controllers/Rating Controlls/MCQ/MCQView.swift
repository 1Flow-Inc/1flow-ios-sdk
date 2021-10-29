//
//  OneToTenView.swift
//  Feedback
//
//  Created by Rohan Moradiya on 19/06/21.
//

import UIKit

class MCQView: UIView {

    @IBOutlet weak var stackView1: UIStackView!
    weak var delegate: RatingViewProtocol?
    @IBOutlet weak var btnFinish: UIButton!
    var currentType:  OFRadioButton.OFRadioButtonType = OFRadioButton.OFRadioButtonType.radioButton
    var allOptions: [String]?
    var selectedButton: UIButton? {
        didSet {
            if self.currentType == .radioButton, self.selectedButton != nil {
                self.delegate?.mcqViewChangeSelection(selectedButton?.tag ?? nil, selectedValue: selectedButton?.title(for: .normal))
            }
        }
    }
    
    func setupViewWithOptions(_ options: [String], type: OFRadioButton.OFRadioButtonType, parentViewWidth: CGFloat) {
        OneFlowLog("Setup view with option: \(parentViewWidth)")
        self.currentType = type
        self.allOptions = options
        if type == .checkBox {
            btnFinish.backgroundColor = kPrimaryColor
            btnFinish.layer.cornerRadius = 2.0
        }
        while let first = stackView1.arrangedSubviews.first {
            stackView1.removeArrangedSubview(first)
                first.removeFromSuperview()
        }
        
        for i in 0..<options.count {
            let option = options[i]
            let button = OFRadioButton(frame: CGRect(x: 0, y: 0, width: parentViewWidth, height: 42), type: type)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.setTitle(option, for: .normal)
            button.tag = i
            button.addTarget(self, action: #selector(onSelectButton(_:)), for: .touchUpInside)
            self.stackView1.addArrangedSubview(button)
            let height = self.labelSize(for: option, maxWidth: (parentViewWidth - 42))
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: height + 24).isActive = true
        }
    }
    
    func labelSize(for text: String, maxWidth: CGFloat) -> CGFloat {
        
        let label =  UILabel(frame: CGRect(x: 0, y: 0, width: maxWidth, height: .greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.text = text
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.sizeToFit()
        return label.frame.height
    }
    
    func setupFinishButton() {
        if self.currentType == .checkBox {
            var isAnySelected = false
            for view in self.stackView1.arrangedSubviews {
                if let btn = view as? UIButton? {
                    if btn?.isSelected == true {
                        isAnySelected = true
                        break
                    }
                }
            }
            if isAnySelected == true {
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
    
    @IBAction func onFinishTaped(_ sender: UIButton) {
        var selectedIndexes = [Int]()
        for view in self.stackView1.arrangedSubviews {
            if let btn = view as? UIButton? {
                if btn?.isSelected == true {
                    selectedIndexes.append(btn!.tag)
                }
            }
        }
        self.delegate?.checkBoxViewDidFinishPicking(selectedIndexes)
    }

    @IBAction func onSelectButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if self.currentType == .radioButton {
            self.selectedButton?.isSelected = false
            if sender.isSelected == true {
                self.selectedButton = sender
            } else {
                self.selectedButton = nil
            }
        } else {
            self.setupFinishButton()
        }
        
    }
}
