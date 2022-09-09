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

@objc(OBJCOFWelcomeView)
class OFWelcomeView: UIView {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var btnContinue: UIButton!
    weak var delegate: OFRatingViewProtocol?
    var imageView: UIImageView?
    
    var welcomeTitle: String = "" {
        didSet {
            self.lblTitle.text = welcomeTitle
        }
    }
    
    var welcomeDescription: String = "" {
        didSet {
            self.lblDescription.text = welcomeDescription
        }
    }
    
    var continueTitle: String = "" {
        didSet {
            self.btnContinue.setTitle(continueTitle, for: .normal)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        lblTitle.textColor = kPrimaryTitleColor
        lblDescription.textColor = kSecondaryTitleColor
        
        btnContinue.layer.cornerRadius = 5.0
        btnContinue.isHidden = false
        btnContinue.backgroundColor = kBrandColor
        btnContinue.isUserInteractionEnabled = true
    }
    
    @IBAction func onContinueTapped(_ sender: Any) {
        self.delegate?.onWelcomeNextTapped()
    }
}
