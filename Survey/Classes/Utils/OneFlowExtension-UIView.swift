//
//  OneFlowExtension-UIView.swift
//  1Flow
//
//  Created by Rohan Moradiya on 21/10/23.
//

import Foundation

extension UIView {
    func pinEdgeToParentWithPadding(top: CGFloat?, bottom: CGFloat?, leading: CGFloat?, trailing: CGFloat?) {
        guard let parentView = superview else {
            return
        }
        translatesAutoresizingMaskIntoConstraints = false
        var constraints = [NSLayoutConstraint]()
        if let top = top {
            constraints.append(topAnchor.constraint(equalTo: parentView.topAnchor, constant: top))
        }
        if let bottom = bottom {
            constraints.append(bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: bottom))
        }
        if let leading = leading {
            constraints.append(leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: leading))
        }
        if let trailing = trailing {
            constraints.append(trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: trailing))
        }
        NSLayoutConstraint.activate(constraints)
    }
}
