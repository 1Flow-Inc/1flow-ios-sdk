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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(checkGestureAction(_:)))
        self.stackView1.addGestureRecognizer(gesture)
        self.setupImages()
    }
    
    func setupImages() {
        let starImage = UIImage.getStartImage()
        let filledStarImage = UIImage.getStartImageSelected()
        for view in self.stackView1.arrangedSubviews {
            if let btn = view as? UIButton {
                btn.setImage(starImage, for: .normal)
                btn.setImage(filledStarImage, for: .selected)
            }
        }
    }
    
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
    
    @objc func checkGestureAction(_ sender: UIPanGestureRecognizer) {
        if sender.state == .changed {
            let location = sender.location(in: self.stackView1)
            let filteredSubviews = self.stackView1.subviews.filter { subView -> Bool in
                return subView.frame.contains(location)
            }
            guard let subviewTapped = filteredSubviews.first else {
                // No subview touched
                return
            }
            let index = subviewTapped.tag
            _ = self.stackView1.arrangedSubviews.map { view in
                if let btn = view as? UIButton {
                    if btn.tag <= index {
                        btn.isSelected = true
                    } else {
                        btn.isSelected = false
                    }
                }
            }
        } else if sender.state == .ended {
            if let temp = self.stackView1.arrangedSubviews.last(where: { view in
                if let btn = view as? UIButton {
                    return btn.isSelected == true
                } else {
                    return false
                }
            }) {
                self.onSelectButton(temp as! UIButton)
            }
            
        }
    }
}
