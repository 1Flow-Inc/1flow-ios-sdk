//
//  RoundedConrnerView.swift
//  Feedback
//
//  Created by Rohan Moradiya on 16/06/21.
//

import UIKit

class RoundedConrnerView: UIView {

    override func layoutSubviews() {
        super.layoutSubviews()
        let cornerRadiudRatio: CGFloat = 0.0813
        let radius = self.bounds.width * cornerRadiudRatio
        roundCorners(corners: [.topLeft, .topRight], radius: radius)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        self.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        self.endEditing(true)
    }
}

extension UIView {
   func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
