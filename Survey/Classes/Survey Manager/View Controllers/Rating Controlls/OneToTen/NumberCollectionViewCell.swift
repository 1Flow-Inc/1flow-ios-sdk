//
//  NumberCollectionViewCell.swift
//  Feedback
//
//  Created by Rohan Moradiya on 14/07/21.
//

import UIKit

class NumberCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var btnNumber: NumberButton!
    @IBOutlet weak var leftBorder: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
//        self.layer.borderWidth = 0.25
//        self.layer.borderColor = UIColor(red: 0.76, green: 0.76, blue: 0.76, alpha: 1.0).cgColor
    }

}
