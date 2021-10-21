//
//  SwiftGIF.swift
//  Feedback
//
//  Created by Rohan Moradiya on 18/08/21.
//

import UIKit

extension UIImageView {
    static func fromGif(frame: CGRect, resourceName: String, bundle: Bundle) -> UIImageView? {
        
        guard let path = bundle.path(forResource: resourceName, ofType: "gif") else {
            print("[Error] gif not exist]")
            return nil
        }
        let url = URL(fileURLWithPath: path)
        guard let gifData = try? Data(contentsOf: url),
            let source =  CGImageSourceCreateWithData(gifData as CFData, nil) else { return nil }
        var images = [UIImage]()
        let imageCount = CGImageSourceGetCount(source)
        for i in 0 ..< imageCount {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
            }
        }
        let gifImageView = UIImageView(frame: frame)
        gifImageView.animationImages = images
        return gifImageView
    }
}
