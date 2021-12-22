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

@objc(OBJCOFStarsView)
class OFStarsView: UIView {

    @IBOutlet weak var stackView1: UIStackView!
    weak var delegate: OFRatingViewProtocol?
    
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
