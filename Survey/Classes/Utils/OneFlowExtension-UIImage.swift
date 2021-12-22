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

import Foundation
import UIKit

extension UIImage {

    class func getRadioButtonImage() -> UIImage? {
        
        let borderWidth: CGFloat = 2.0
        let newRect = CGRect(x: 0, y: 0, width: 42, height: 42)
        
        UIGraphicsBeginImageContext(newRect.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.clear(newRect)
        context.saveGState()
        let shapePath = UIBezierPath(ovalIn: newRect.insetBy(dx: borderWidth/2, dy: borderWidth/2))
        
        shapePath.lineWidth = borderWidth
        UIColor.white.setFill()
        kBorderColor.setStroke()
        
        context.addPath(shapePath.cgPath)
        shapePath.fill()
        shapePath.stroke()
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        context.restoreGState()
        UIGraphicsEndImageContext()
        return image.resized(to: CGSize(width: 14, height: 14))
    }
    
    class func getRadioButtonImageHighlighted() -> UIImage? {
        
        let borderWidth: CGFloat = 2.0
        let newRect = CGRect(x: 0, y: 0, width: 42, height: 42)
        
        UIGraphicsBeginImageContext(newRect.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.clear(newRect)
        context.saveGState()
        let shapePath = UIBezierPath(ovalIn: newRect.insetBy(dx: borderWidth/2, dy: borderWidth/2))
        shapePath.lineWidth = borderWidth
        UIColor.white.setFill()
        kPrimaryColor.setStroke()
        
        context.addPath(shapePath.cgPath)
        shapePath.fill()
        shapePath.stroke()
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        context.restoreGState()
        UIGraphicsEndImageContext()
        return image.resized(to: CGSize(width: 14, height: 14))
    }
    
    class func getRadioButtonImageSelected() -> UIImage? {
        
        let borderWidth: CGFloat = 12.0
        let newRect = CGRect(x: 0, y: 0, width: 42, height: 42)
        
        UIGraphicsBeginImageContext(newRect.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.clear(newRect)
        
        context.setFillColor(UIColor.clear.cgColor)
        context.saveGState()
        let shapePath = UIBezierPath(ovalIn: newRect.insetBy(dx: borderWidth/2, dy: borderWidth/2))
        shapePath.lineWidth = borderWidth
        UIColor.white.setFill()
        kPrimaryColor.setStroke()
        
        context.addPath(shapePath.cgPath)
        shapePath.fill()
        shapePath.stroke()
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        context.restoreGState()
        UIGraphicsEndImageContext()
        return image.resized(to: CGSize(width: 14, height: 14))
    }
    
    class func getCheckboxImage() -> UIImage? {
        
        let borderWidth: CGFloat = 2.0
        let newRect = CGRect(x: 0, y: 0, width: 42, height: 42)
        
        UIGraphicsBeginImageContext(newRect.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.clear(newRect)
        context.saveGState()
        let radius: CGFloat = 6.0
        let shapePath = UIBezierPath(roundedRect: newRect.insetBy(dx: borderWidth/2, dy: borderWidth/2), cornerRadius: radius)
        shapePath.lineWidth = borderWidth
        UIColor.white.setFill()
        kBorderColor.setStroke()
        
        context.addPath(shapePath.cgPath)
        shapePath.fill()
        shapePath.stroke()
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        context.restoreGState()
        UIGraphicsEndImageContext()
        return image.resized(to: CGSize(width: 14, height: 14))
    }
    
    class func getCheckboxImageHighlighted() -> UIImage? {
        
        let borderWidth: CGFloat = 2.0
        let newRect = CGRect(x: 0, y: 0, width: 42, height: 42)
        
        UIGraphicsBeginImageContext(newRect.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.clear(newRect)
        context.saveGState()
        let radius: CGFloat = 6.0
        let shapePath = UIBezierPath(roundedRect: newRect.insetBy(dx: borderWidth/2, dy: borderWidth/2), cornerRadius: radius)
        shapePath.lineWidth = borderWidth
        UIColor.white.setFill()
        kPrimaryColor.setStroke()
        
        context.addPath(shapePath.cgPath)
        shapePath.fill()
        shapePath.stroke()
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        context.restoreGState()
        UIGraphicsEndImageContext()
        return image.resized(to: CGSize(width: 14, height: 14))
    }
    
    class func getCheckboxImageSelected() -> UIImage? {

        let borderWidth: CGFloat = 2.0
        let newRect = CGRect(x: 0, y: 0, width: 42, height: 42)
        
        UIGraphicsBeginImageContext(newRect.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.clear(newRect)
        context.saveGState()
        let radius: CGFloat = 6.0
        let shapePath = UIBezierPath(roundedRect: newRect.insetBy(dx: borderWidth/2, dy: borderWidth/2), cornerRadius: radius)
        shapePath.lineWidth = borderWidth
        kPrimaryColor.setFill()
        kPrimaryColor.setStroke()
        
        context.addPath(shapePath.cgPath)
        shapePath.fill()
        shapePath.stroke()
        let frame = newRect
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: frame.minX + 0.26000 * frame.width, y: frame.minY + 0.50000 * frame.height))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 0.42000 * frame.width, y: frame.minY + 0.62000 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.38000 * frame.width, y: frame.minY + 0.60000 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.42000 * frame.width, y: frame.minY + 0.62000 * frame.height))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 0.70000 * frame.width, y: frame.minY + 0.24000 * frame.height))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 0.78000 * frame.width, y: frame.minY + 0.30000 * frame.height))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 0.44000 * frame.width, y: frame.minY + 0.76000 * frame.height))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 0.20000 * frame.width, y: frame.minY + 0.58000 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.44000 * frame.width, y: frame.minY + 0.76000 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.26000 * frame.width, y: frame.minY + 0.62000 * frame.height))
        
        context.addPath(bezierPath.cgPath)
        UIColor.white.setFill()
        bezierPath.fill()
        bezierPath.stroke()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        context.restoreGState()
        UIGraphicsEndImageContext()
        return image.resized(to: CGSize(width: 14, height: 14))
    }
    
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    class func getStartImage() -> UIImage? {
        let borderWidth: CGFloat = 3.0
        let newRect = CGRect(x: 0, y: 0, width: 95, height: 95)
        
        UIGraphicsBeginImageContext(newRect.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.clear(newRect)
        context.saveGState()
        let shapePath = UIImage.starPathInRect(rect: newRect)
        shapePath.lineWidth = borderWidth
        UIColor.white.setFill()
        kPrimaryColor.setStroke()
        
        context.addPath(shapePath.cgPath)
        shapePath.stroke()
        shapePath.fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        context.restoreGState()
        UIGraphicsEndImageContext()
        return image.resized(to: CGSize(width: 32, height: 32))
    }
    
    class func getStartImageSelected() -> UIImage? {
        let borderWidth: CGFloat = 3.0
        let newRect = CGRect(x: 0, y: 0, width: 95, height: 95)
        
        UIGraphicsBeginImageContext(newRect.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.clear(newRect)
        context.saveGState()
        let shapePath = UIImage.starPathInRect(rect: newRect)
        shapePath.lineWidth = borderWidth
        kPrimaryColor.setFill()
        kPrimaryColor.setStroke()
        
        context.addPath(shapePath.cgPath)
        shapePath.fill()
        shapePath.stroke()
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        context.restoreGState()
        UIGraphicsEndImageContext()
        return image.resized(to: CGSize(width: 32, height: 32))
    }
    
    class func starPathInRect(rect: CGRect) -> UIBezierPath {
        let cornerRadius: CGFloat = 4
        let rotation: CGFloat = 54
        let path = UIBezierPath()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let r = rect.width / 2
        let rc = cornerRadius
        let rn = r * 0.95 - rc
        
        var cangle = rotation
        for i in 1 ... 5 {
            // compute center point of tip arc
            let cc = CGPoint(x: center.x + rn * cos(cangle * .pi / 180), y: center.y + rn * sin(cangle * .pi / 180))
            
            // compute tangent point along tip arc
            let p = CGPoint(x: cc.x + rc * cos((cangle - 72) * .pi / 180), y: cc.y + rc * sin((cangle - 72) * .pi / 180))
            
            if i == 1 {
                path.move(to: p)
            } else {
                path.addLine(to: p)
            }
            
            // add 144 degree arc to draw the corner
            path.addArc(withCenter: cc, radius: rc, startAngle: (cangle - 72) * .pi / 180, endAngle: (cangle + 72) * .pi / 180, clockwise: true)
            
            cangle += 144
        }
        
        path.close()
        return path
    }
    
    class func pointFrom(_ angle: CGFloat, radius: CGFloat, offset: CGPoint) -> CGPoint {
        return CGPoint(x: offset.x + radius*cos(angle), y: offset.y + radius*sin(angle))
    }
}
