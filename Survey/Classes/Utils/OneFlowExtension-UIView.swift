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
