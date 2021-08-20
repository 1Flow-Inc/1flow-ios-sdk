//
//  DraggableView.swift
//  Feedback
//
//  Created by Rohan Moradiya on 14/08/21.
//

import UIKit

class DraggableView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        self.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        self.endEditing(true)
    }
}
