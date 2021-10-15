//
//  RatingViewProtocol.swift
//  Feedback
//
//  Created by Rohan Moradiya on 19/06/21.
//

import Foundation

protocol RatingViewProtocol: AnyObject {
    func oneToTenViewChangeSelection(_ selectedIndex: Int?)
    func starsViewChangeSelection(_ selectedIndex: Int?)
    func mcqViewChangeSelection(_ selectedIndex: Int?, selectedValue: String?)
    func followupViewEnterTextWith(_ text: String?)
    func checkBoxViewDidFinishPicking(_ selectedIndexes: [Int])
}
