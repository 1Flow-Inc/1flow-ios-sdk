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

@objc(OBJCOFThankYouView)
class OFThankYouView: UIView {

    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    weak var delegate: OFRatingViewProtocol?
    var imageView: UIImageView?
    
    deinit {
        imageView?.animationImages = nil
    }
    lazy var waterMarkURL = "https://1flow.app/?utm_source=1flow-ios-sdk&utm_medium=watermark&utm_campaign=real-time+feedback+powered+by+1flow"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        guard let imageView = UIImageView.fromGif(frame: animationView.bounds, resourceName: "OFdone", bundle: OneFlowBundle.bundleForObject(self)) else { return }
        animationView.addSubview(imageView)
        imageView.animationDuration = 1.0
        imageView.animationRepeatCount = 1
        lblTitle.textColor = kPrimaryTitleColor
        lblDescription.textColor = kSecondaryTitleColor
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            imageView.image = imageView.animationImages?.last
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.delegate?.onThankyouAnimationComplete()
            }
            imageView.startAnimating()
            CATransaction.commit()
        }
    }
    
    @IBAction func onClickWatermark(_ sender: Any) {
        guard let url = URL(string: waterMarkURL) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [ : ], completionHandler: nil)
        }
    }
}
