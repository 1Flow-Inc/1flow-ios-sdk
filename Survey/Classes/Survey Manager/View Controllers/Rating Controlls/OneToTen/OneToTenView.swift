//
//  OneToTenView.swift
//  Feedback
//
//  Created by Rohan Moradiya on 19/06/21.
//

import UIKit

class OneToTenView: UIView {

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
            let numberOfItems = CGFloat(emojiArray!.count)
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
    weak var delegate: RatingViewProtocol?
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
        collectionView.layer.borderWidth = 0.5
        collectionView.layer.borderColor = kBorderColor.cgColor
        collectionView.layer.cornerRadius = 10.0
        let frameworkBundle = Bundle(for: self.classForCoder)
        let nib = UINib(nibName: "NumberCollectionViewCell", bundle: frameworkBundle)
        collectionView.register(nib, forCellWithReuseIdentifier: "NumberCollectionViewCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        
    }
    
    var selectedButton: UIButton? {
        didSet {
            self.delegate?.oneToTenViewChangeSelection(selectedButton?.tag ?? nil)
        }
    }

    @objc func onSelectButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        self.selectedButton?.isSelected = false
        if sender.isSelected == true {
            self.selectedButton = sender
        } else {
            self.selectedButton = nil
        }
    }
}

extension OneToTenView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.isForEmoji == true {
            return self.emojiArray?.count ?? 0
        } else {
            return maxValue - minValue + 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NumberCollectionViewCell", for: indexPath) as! NumberCollectionViewCell
        cell.btnNumber.addTarget(self, action: #selector(onSelectButton(_:)), for: .touchUpInside)
        let titleNumber = self.minValue + indexPath.item
        cell.btnNumber.tag = titleNumber
        if self.isForEmoji == true {
            if let emojies = self.emojiArray {
                cell.btnNumber.titleLabel?.font = UIFont.systemFont(ofSize: 30)
                cell.btnNumber.setTitle(emojies[indexPath.item], for: .normal)
            }
        } else {
            cell.btnNumber.setTitle("\(titleNumber)", for: .normal)
        }
        
        if indexPath.item == 0 {
            cell.leftBorder.isHidden = true
        } else {
            cell.leftBorder.isHidden = false
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.isForEmoji {
            var itemWidth = collectionView.bounds.width / CGFloat(emojiArray?.count ?? 1)
            if itemWidth > 65 {
                itemWidth = 65
            }
            return CGSize(width: itemWidth, height: 65)
        } else {
            let numberOfItems: CGFloat = CGFloat(maxValue - minValue) + 1
            var itemWidth = collectionView.bounds.width / numberOfItems
            if itemWidth > 65 {
                itemWidth = 65
            }
            return CGSize(width: itemWidth, height: 65)
        }
        
    }
}
