//
//  OneToTenView.swift
//  Feedback
//
//  Created by Rohan Moradiya on 19/06/21.
//

import UIKit

class ThankYouView: UIView {

    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var lblTitle: UILabel!
    
    var imageView: UIImageView?
    
    deinit {
        imageView?.animationImages = nil
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let frameworkBundle = Bundle(for: self.classForCoder)
        
        guard let imageView = UIImageView.fromGif(frame: animationView.bounds, resourceName: "done", bundle: frameworkBundle) else { return }
        animationView.addSubview(imageView)
        imageView.animationDuration = 1.0
        imageView.animationRepeatCount = 1
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.2) {
                imageView.image = imageView.animationImages?.last
                imageView.startAnimating()
            }
    }
}
