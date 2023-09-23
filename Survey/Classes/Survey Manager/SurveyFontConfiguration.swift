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

protocol SurveyFontConfigurable {
    var fontName: String? { get set }

    var titleFont: UIFont { get }
    var subTitleFont: UIFont { get }
    var submitButtonFont: UIFont { get }
    var openTextFont: UIFont { get }
    var openTextCharCountFont: UIFont { get }
    var textFieldFont: UIFont { get }
    var numberFont: UIFont { get }
    var checkboxButtonFont: UIFont { get }
    var checkboxEnterButtonFont: UIFont { get }
}

class SurveyFontConfiguration: SurveyFontConfigurable {

    internal var fontName: String?

    init(fontName: String? = nil) {
        self.fontName = fontName
    }

    lazy var titleFont: UIFont = {
        guard let fontName = fontName, let baseFont = UIFont(name: fontName, size: 18) else {
            return UIFont.systemFont(ofSize: 18, weight: .medium)
        }
        if let font = UIFont(name: fontName+" Medium", size: 18) {
            return font
        } else {
            return baseFont
        }
    }()

    lazy var subTitleFont: UIFont  = {
        if let fontName = fontName, let font = UIFont(name: fontName, size: 14) {
            return font
        } else {
            return UIFont.systemFont(ofSize: 14)
        }
    }()

    lazy var submitButtonFont: UIFont  = {
        // bold
        guard let fontName = fontName, let baseFont = UIFont(name: fontName, size: 16) else {
            return UIFont.systemFont(ofSize: 16, weight: .bold)
        }
        if let font = UIFont(name: fontName+" Bold", size: 16) {
            return font
        } else {
            return baseFont
        }
    }()

    lazy var openTextFont: UIFont  = {
        if let fontName = fontName, let font = UIFont(name: fontName, size: 16) {
            return font
        } else {
            return UIFont.systemFont(ofSize: 16)
        }
    }()

    lazy var openTextCharCountFont: UIFont  = {
        if let fontName = fontName, let font = UIFont(name: fontName, size: 12) {
            return font
        } else {
            return UIFont.systemFont(ofSize: 12)
        }
    }()

    lazy var textFieldFont: UIFont  = {
        if let fontName = fontName, let font = UIFont(name: fontName, size: 14) {
            return font
        } else {
            return UIFont.systemFont(ofSize: 14)
        }
    }()

    lazy var numberFont: UIFont  = {
        if let fontName = fontName, let font = UIFont(name: fontName, size: 18) {
            return font
        } else {
            return UIFont.systemFont(ofSize: 18)
        }
    }()

    lazy var checkboxButtonFont: UIFont  = {
        // semi-bold
        guard let fontName = fontName, let baseFont = UIFont(name: fontName, size: 14) else {
            return UIFont.systemFont(ofSize: 14, weight: .semibold)
        }
        if let font = UIFont(name: fontName+" SemiBold", size: 14) {
            return font
        } else if let font = UIFont(name: fontName+" Semibold", size: 14) {
            return font
        } else if let font = UIFont(name: fontName+" Demi Bold", size: 14) {
            return font
        } else if let font = UIFont(name: fontName+" Demibold", size: 14) {
            return font
        } else {
            return baseFont
        }
    }()

    lazy var checkboxEnterButtonFont: UIFont  = {
        // bold
        guard let fontName = fontName, let baseFont = UIFont(name: fontName, size: 10) else {
            return UIFont.systemFont(ofSize: 10, weight: .bold)
        }
        if let font = UIFont(name: fontName+" Bold", size: 10) {
            return font
        } else {
            return baseFont
        }
    }()
}
