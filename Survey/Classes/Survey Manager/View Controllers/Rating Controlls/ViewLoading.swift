//
//  ViewLoading.swift
//  Feedback
//
//  Created by Rohan Moradiya on 19/06/21.
//

import Foundation
import UIKit

protocol UIViewLoading {}
extension UIView : UIViewLoading {}

extension UIViewLoading where Self : UIView {

  static func loadFromNib() -> Self {
    let nibName = "\(self)".split{$0 == "."}.map(String.init).last!
    let nib = UINib(nibName: nibName, bundle: Bundle(for: self))
    return nib.instantiate(withOwner: self, options: nil).first as! Self
  }

}
