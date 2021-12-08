//
//  OneToTenView.swift
//  Feedback
//
//  Created by Rohan Moradiya on 19/06/21.
//

import UIKit

class OFThankYouView: UIView {

    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var lblTitle: UILabel!
    
    var imageView: UIImageView?
    
    deinit {
        imageView?.animationImages = nil
    }
    lazy var waterMarkURL = "https://1flow.app/?utm_source=1flow-ios-sdk&utm_medium=watermark&utm_campaign=real-time+feedback+powered+by+1flow"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let frameworkBundle = Bundle(for: self.classForCoder)
        
        guard let imageView = UIImageView.fromGif(frame: animationView.bounds, resourceName: "OFdone", bundle: frameworkBundle) else { return }
        animationView.addSubview(imageView)
        imageView.animationDuration = 1.0
        imageView.animationRepeatCount = 1
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.2) {
                imageView.image = imageView.animationImages?.last
                imageView.startAnimating()
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
