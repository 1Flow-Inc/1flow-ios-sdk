//
//  OneToTenView.swift
//  Feedback
//
//  Created by Rohan Moradiya on 19/06/21.
//

import UIKit

class StarsView: UIView {

    @IBOutlet weak var stackView1: UIStackView!
    weak var delegate: RatingViewProtocol?
    
    var selectedButton: UIButton? {
        didSet {
            self.delegate?.starsViewChangeSelection(selectedButton?.tag ?? nil)
        }
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    @IBAction func onSelectButton(_ sender: UIButton) {
        
        let index = sender.tag
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
}
