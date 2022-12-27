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

@objc(OBJCOFOneToTenView)
class OFOneToTenView: UIView {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewWidth: NSLayoutConstraint!
    var minValue = 1
    var maxValue = 5 {
        didSet {
            let numberOfItems = CGFloat(maxValue - minValue + 1)
            collectionViewWidth.constant = (numberOfItems * 65)
            collectionView.reloadData()
        }
    }
    var emojiArray: [String]? {
        didSet {
            let numberOfItems = CGFloat(emojiArray?.count ?? 0)
            collectionViewWidth.constant = (numberOfItems * 65)
            collectionView.reloadData()
        }
    }
    var isForEmoji = false {
        didSet {
            if isForEmoji == true {
                self.lblMinValue.isHidden = true
                self.lblMaxValue.isHidden = true
            }
        }
    }
    weak var delegate: OFRatingViewProtocol?
    @IBOutlet weak var lblMinValue: UILabel!
    @IBOutlet weak var lblMaxValue: UILabel!
    var ratingMaxText: String? {
        didSet {
            if ratingMaxText != nil {
                self.lblMaxValue.text = ratingMaxText
            }
        }
    }
    
    var ratingMinText: String? {
        didSet {
            if ratingMinText != nil {
                self.lblMinValue.text = ratingMinText
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let nib = UINib(nibName: "OFNumberCollectionViewCell", bundle: OneFlowBundle.bundleForObject(self))
        collectionView.register(nib, forCellWithReuseIdentifier: "OFNumberCollectionViewCell")
        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        collectionView.dataSource = self
        self.lblMaxValue.textColor = kFooterColor
        self.lblMinValue.textColor = kFooterColor
        self.lblMaxValue.font = OneFlow.fontConfiguration?.openTextCharCountFont
        self.lblMinValue.font = OneFlow.fontConfiguration?.openTextCharCountFont
    }
    
    var selectedButton: UIButton? {
        didSet {
            self.delegate?.oneToTenViewChangeSelection(selectedButton?.tag ?? nil)
        }
    }

    @objc func onSelectButton(_ sender: UIButton) {
        self.isUserInteractionEnabled = false
        sender.isSelected = !sender.isSelected
        self.selectedButton?.isSelected = false
        if sender.isSelected == true {
            self.selectedButton = sender
        } else {
            self.selectedButton = nil
        }
    }
}

extension OFOneToTenView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.isForEmoji == true {
            return self.emojiArray?.count ?? 0
        } else {
            return maxValue - minValue + 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OFNumberCollectionViewCell", for: indexPath) as! OFNumberCollectionViewCell
        cell.btnNumber.addTarget(self, action: #selector(onSelectButton(_:)), for: .touchUpInside)
        let titleNumber = self.minValue + indexPath.item
        cell.btnNumber.tag = titleNumber
        if self.isForEmoji == true {
            cell.btnNumber.isEmoji = true
            if let emojies = self.emojiArray {
                cell.btnNumber.layer.backgroundColor = UIColor.clear.cgColor

                cell.btnNumber.titleLabel?.font = UIFont.systemFont(ofSize: 30)
                cell.btnNumber.setTitle(emojies[indexPath.item], for: .normal)
            }
        } else {
            cell.btnNumber.isEmoji = false
            cell.btnNumber.layer.backgroundColor = kAppGreyBGColor.cgColor
            cell.btnNumber.titleLabel?.font = OneFlow.fontConfiguration?.numberFont
            cell.btnNumber.setTitle("\(titleNumber)", for: .normal)
        }
        
        if indexPath.item == 0 {
            cell.leftBorder.isHidden = true
        } else {
            cell.leftBorder.isHidden = true
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if self.isForEmoji {
            return 0
        }
        let numberOfItems: CGFloat = CGFloat(maxValue - minValue) + 1
        if numberOfItems > 5 {
            return 6.0
        }
        else{
            return 10.5
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.isForEmoji {
            var itemWidth = collectionView.bounds.width / CGFloat(emojiArray?.count ?? 1)
            if itemWidth > 55 {
                itemWidth = 55
            }
            return CGSize(width: itemWidth, height: 55)
        } else {
            let numberOfItems: CGFloat = CGFloat(maxValue - minValue) + 1
            var itemWidth = collectionView.bounds.width / numberOfItems
            if numberOfItems > 5 {
                itemWidth = itemWidth - 6
            }
            else{
                itemWidth = itemWidth - 10.5

            }
            if itemWidth > 55 {
                itemWidth = 55
            }
            return CGSize(width: itemWidth, height: 48)
        }
        
    }
}
