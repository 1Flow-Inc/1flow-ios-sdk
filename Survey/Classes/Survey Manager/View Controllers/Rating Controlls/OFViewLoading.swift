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

import Foundation
import UIKit

protocol OFUIViewLoading {}
extension UIView: OFUIViewLoading {}

extension OFUIViewLoading where Self: UIView {

  static func loadFromNib() -> Self {
    let nibName = "\(self)".split { $0 == "."}.map(String.init).last!
    let nib = UINib(nibName: nibName, bundle: OneFlowBundle.bundleForObject(self))
      guard let view = nib.instantiate(withOwner: self, options: nil).first as? Self else {
          fatalError("view of type \(Self.self) not found in \(nib)")
      }
    return view
  }
}
