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
    
    var selectedButton: UIButton? {
        didSet {
            self.delegate?.mcqViewChangeSelection(selectedButton?.tag ?? nil, selectedValue: selectedButton?.title(for: .normal))
        }
    }
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude)) //CGRectMake(0, 0, width, CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.textAlignment = .center
        label.sizeToFit()
        return label.frame.height
    }
    
    func setupViewWithOptions(_ options: [String]) {
        
        for i in 0..<options.count {
            let option = options[i]
//            let button = UIButton(type: .custom)
            let button = NumberButton(frame: CGRect(x: 0, y: 0, width: self.stackView1.frame.size.width, height: 40))
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.titleLabel?.textAlignment = .center
            button.setTitle(option, for: .normal)
            button.tag = i
            button.addTarget(self, action: #selector(onSelectButton(_:)), for: .touchUpInside)
            self.stackView1.addArrangedSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        }
    }

    @IBAction func onSelectButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        self.selectedButton?.isSelected = false
        if sender.isSelected == true {
            self.selectedButton = sender
        } else {
            self.selectedButton = nil
        }
    }
}
