//
//  OneToTenView.swift
//  Feedback
//
//  Created by Rohan Moradiya on 19/06/21.
//

import UIKit

class EmojiView: UIView {

    @IBOutlet weak var stackView1: UIStackView!
    weak var delegate: RatingViewProtocol?
    
    var selectedButton: UIButton? {
        didSet {
            self.delegate?.emojiViewChangeSelection(selectedButton?.tag ?? nil)
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
        sender.isSelected = !sender.isSelected
        self.selectedButton?.isSelected = false
        if sender.isSelected == true {
            self.selectedButton = sender
        } else {
            self.selectedButton = nil
        }
    }
}
