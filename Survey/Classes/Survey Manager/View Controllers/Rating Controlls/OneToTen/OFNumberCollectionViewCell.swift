//
//  OFNumberCollectionViewCell.swift
//  Feedback
//
//  Created by Rohan Moradiya on 14/07/21.
//

import UIKit

@objc(OBJCOFNumberCollectionViewCell)
class OFNumberCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var btnNumber: OFNumberButton!
    @IBOutlet weak var leftBorder: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
