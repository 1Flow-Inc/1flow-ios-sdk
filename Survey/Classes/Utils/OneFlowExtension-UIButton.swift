//
//  OneFlowExtension-UIButton.swift
//  1Flow
//
//  Created by Rohan Moradiya on 08/01/24.
//

import Foundation
import UIKit

extension UIButton {
  func imageToRight() {
      transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
      titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
      imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
  }
}
