//
//  OneFlowBundle.swift
//  Feedback
//
//  Created by Rohan Moradiya on 16/12/21.
//

import Foundation

class OneFlowBundle {
    class func bundleForObject(_ obj: AnyObject) -> Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: obj.classForCoder)
        #endif
    }
}
