//
//  OneToTenView.swift
//  Feedback
//
//  Created by Rohan Moradiya on 19/06/21.
//

import UIKit

class OneToTenView: UIView {

    @IBOutlet weak var collectionView: UICollectionView!
    var minValue = 1
    var maxValue = 5 {
        didSet {
            let numberOfItems: CGFloat = CGFloat(maxValue - minValue) + 1
            let numberOfRow = ceil(Double(numberOfItems / 6.0))
            collectionViewHeightConstraint.constant = CGFloat((numberOfRow > 3 ? 3 : numberOfRow) * 60)
            collectionView.reloadData()
        }
    }
    
    weak var delegate: RatingViewProtocol?
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    
    let columnLayout = FlowLayout(
            itemSize: CGSize(width: 40, height: 40),
            minimumInteritemSpacing: 10,
            minimumLineSpacing: 10,
            sectionInset: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        )
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        collectionView?.collectionViewLayout = columnLayout
        collectionView?.contentInsetAdjustmentBehavior = .always
        
        let frameworkBundle = Bundle(for: self.classForCoder)
//        let frameworkBundle = Bundle(identifier: "Rohan-Moradiya.Feedback")
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

extension OneToTenView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return maxValue - minValue + 1
//        return maxValue - minValue
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NumberCollectionViewCell", for: indexPath) as! NumberCollectionViewCell
        cell.btnNumber.addTarget(self, action: #selector(onSelectButton(_:)), for: .touchUpInside)
        let titleNumber = self.minValue + indexPath.item
        cell.btnNumber.tag = titleNumber
        cell.btnNumber.setTitle("\(titleNumber)", for: .normal)
        return cell
    }
    
}


class FlowLayout: UICollectionViewFlowLayout {

    required init(itemSize: CGSize, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0, sectionInset: UIEdgeInsets = .zero) {
        super.init()

        self.itemSize = itemSize
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.sectionInset = sectionInset
        sectionInsetReference = .fromSafeArea
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let layoutAttributes = super.layoutAttributesForElements(in: rect)!.map { $0.copy() as! UICollectionViewLayoutAttributes }
        guard scrollDirection == .vertical else { return layoutAttributes }

        // Filter attributes to compute only cell attributes
        let cellAttributes = layoutAttributes.filter({ $0.representedElementCategory == .cell })

        // Group cell attributes by row (cells with same vertical center) and loop on those groups
        for (_, attributes) in Dictionary(grouping: cellAttributes, by: { ($0.center.y / 10).rounded(.up) * 10 }) {
            // Get the total width of the cells on the same row
            let cellsTotalWidth = attributes.reduce(CGFloat(0)) { (partialWidth, attribute) -> CGFloat in
                partialWidth + attribute.size.width
            }

            // Calculate the initial left inset
            let totalInset = collectionView!.safeAreaLayoutGuide.layoutFrame.width - cellsTotalWidth - sectionInset.left - sectionInset.right - minimumInteritemSpacing * CGFloat(attributes.count - 1)
            var leftInset = (totalInset / 2 * 10).rounded(.down) / 10 + sectionInset.left

            // Loop on cells to adjust each cell's origin and prepare leftInset for the next cell
            for attribute in attributes {
                attribute.frame.origin.x = leftInset
                leftInset = attribute.frame.maxX + minimumInteritemSpacing
            }
        }

        return layoutAttributes
    }

}
