//
//  OneFlowExtension-Data.swift
//  1Flow-SurveySDK
//
//  Created by Rohan Moradiya on 11/03/24.
//

import Foundation

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}
