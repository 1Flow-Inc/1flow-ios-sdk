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
import WebKit

class AnnouncementComponentBuilder {
    static func categoryView(with category: AnnouncementCategory?, date: String?) -> UIView {
        let containerView = UIView()
        var catView: UIView?
        
        if let category = category {
            let categoryView = UIView()
            let label = UILabel()
            label.text = category.name
            let color = UIColor.colorFromHex(category.color)
            label.textColor = color
            label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
            categoryView.addSubview(label)
            categoryView.backgroundColor = color.withAlphaComponent(0.1)
            label.pinEdgeToParentWithPadding(top: 5, bottom: -5, leading: 10, trailing: -10)
            containerView.addSubview(categoryView)
            categoryView.pinEdgeToParentWithPadding(top: 10, bottom: -5, leading: 10, trailing: nil)
            categoryView.layer.cornerRadius = 12
            catView = categoryView
        }
        if let date = date {
            let label = UILabel()
            label.text = date
            label.textColor = UIColor.colorFromHex("#AAAFB6")
            label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            containerView.addSubview(label)
            label.pinEdgeToParentWithPadding(top: 14, bottom: -10, leading: nil, trailing: nil)
            if let catView = catView {
                label.leadingAnchor.constraint(equalTo: catView.trailingAnchor, constant: 5).isActive = true
            } else {
                label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10).isActive = true
            }
        }
        return containerView
    }

    static func verticalSpace(with height: CGFloat) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }

    static func poweredBy1FlowView(with target: Any, selector: Selector) -> UIView {
        let view = UIView()
        let poweredByButton = UIButton()
        poweredByButton.addTarget(target, action: selector, for: .touchUpInside)
        let fullText = " Powered by 1Flow"
        let mainText = " Powered by "
        let creditsText = "1Flow"

        let fontBig = UIFont.systemFont(ofSize: 12, weight: .regular)
        let fontSmall = UIFont.systemFont(ofSize: 12, weight: .bold)
        let attributedString = NSMutableAttributedString(string: fullText, attributes: nil)

        let bigRange = (attributedString.string as NSString).range(of: mainText)
        let creditsRange = (attributedString.string as NSString).range(of: creditsText)
        attributedString.setAttributes(
            [
                NSAttributedString.Key.font: fontBig as Any,
                NSAttributedString.Key.foregroundColor: kWatermarkColor
            ],
            range: bigRange
        )
        attributedString.setAttributes(
            [
                NSAttributedString.Key.font: fontSmall as Any,
                NSAttributedString.Key.foregroundColor: kWatermarkColor
            ],
            range: creditsRange
        )
        poweredByButton.setAttributedTitle(attributedString, for: .normal)
        let highlightedString = NSMutableAttributedString(string: fullText, attributes: nil)
        highlightedString.setAttributes(
            [
                NSAttributedString.Key.font: fontBig as Any,
                NSAttributedString.Key.foregroundColor: kWatermarkColorHightlighted
            ],
            range: bigRange
        )
        highlightedString.setAttributes(
            [
                NSAttributedString.Key.font: fontSmall as Any,
                NSAttributedString.Key.foregroundColor: kWatermarkColorHightlighted
            ],
            range: creditsRange
        )
        poweredByButton.setAttributedTitle(highlightedString, for: .highlighted)
        if let powerByImage = UIImage(named: "1FlowLogo", in: OneFlowBundle.bundleForObject(self), compatibleWith: nil) {
            poweredByButton.setImage(powerByImage, for: .normal)
        }
        view.addSubview(poweredByButton)
        poweredByButton.pinEdgeToParentWithPadding(top: 22, bottom: -22, leading: 0, trailing: 0)
        poweredByButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
        return view
    }

    static func titleView(with title: String, titleColor: UIColor = .black) -> UIView {
        let containerView = UIView()
        let label = UILabel()
        label.text = title
        label.textColor = titleColor
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        containerView.addSubview(label)
        label.pinEdgeToParentWithPadding(top: 2, bottom: -2, leading: 10, trailing: -10)
        return containerView
    }

    static func richTextContentView(with content: String, textColor: String) -> UIView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let source: String = "var meta = document.createElement('meta');" +
        "meta.name = 'viewport';" +
        "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
        "var head = document.getElementsByTagName('head')[0];" +
        "head.appendChild(meta);"
        
        let script: WKUserScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let userContentController: WKUserContentController = WKUserContentController()
        let conf = WKWebViewConfiguration()
        conf.preferences = preferences
        conf.userContentController = userContentController
        userContentController.addUserScript(script)
        let webview = WKWebView(frame: CGRect(x: 0, y: 0, width: 400, height: 400), configuration: conf)
        guard
            let path = OneFlowBundle.bundleForObject(self).path(forResource: "quill-html", ofType: "html"),
            let htmlString = try? String(contentsOfFile: path, encoding: .utf8)
        else {
            return webview
        }
        
        let text = htmlString
            .replacingOccurrences(of: "XXXXXX", with: content)
            .replacingOccurrences(of: "THEME_COLOR", with: textColor)
        
        let file = "myHTML\(OFProjectDetailsController.objectId()).html" //this is the file. we will write to and read from it
        guard let dir = AnnouncementComponentBuilder.getAnnouncementDirectory() else {
            return webview
        }

        let fileURL = dir.appendingPathComponent(file)
        do {
            //writing
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            let request = URLRequest(url: fileURL)
            webview.load(request)
        }
        catch {
            OneFlowLog.writeLog(error.localizedDescription, .error)
        }
        return webview
    }

    static func actionButtonView(with title: String, target: Any, selector: Selector, color: String) -> UIView {
        let containerView = UIView()
        let actionButton = UIButton()
        actionButton.layer.cornerRadius = 5.0
        actionButton.backgroundColor = UIColor.colorFromHex(color)
        actionButton.setTitle(title, for: .normal)
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        actionButton.titleLabel?.textColor = UIColor.white
        containerView.addSubview(actionButton)
        actionButton.pinEdgeToParentWithPadding(top: 0, bottom: 0, leading: 10, trailing: -10)
        actionButton.heightAnchor.constraint(equalToConstant: 38).isActive = true
        actionButton.addTarget(target, action: selector, for: .touchUpInside)
        return containerView
    }

    static func actionButtonInboxView(with title: String, target: Any, selector: Selector, color: String) -> UIView {
        let containerView = UIView()
        let actionButton = UIButton()
        actionButton.setTitle(title, for: .normal)
        if let icon = UIImage(named: "next_icon", in: OneFlowBundle.bundleForObject(self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate) {
            actionButton.setImage(icon, for: .normal)
        }
        
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let titleColor = UIColor.colorFromHex(color)
        actionButton.setTitleColor(titleColor, for: .normal)
        actionButton.tintColor = titleColor
        if #available(iOS 11.0, *) {
            actionButton.contentHorizontalAlignment = .leading
        } else {
            // Fallback on earlier versions
        }
        let insetAmount: CGFloat = 4.0
        actionButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: insetAmount)
        actionButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: -insetAmount)
        actionButton.imageToRight()
        
        containerView.addSubview(actionButton)
        actionButton.pinEdgeToParentWithPadding(top: 0, bottom: 0, leading: 10, trailing: nil)
        actionButton.heightAnchor.constraint(equalToConstant: 38).isActive = true
        actionButton.addTarget(target, action: selector, for: .touchUpInside)
        return containerView
    }

    static func getAnnouncementDirectory() -> URL? {
        if var dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let directoryName = "Announcement"
            dir = dir.appendingPathComponent(directoryName)
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            } catch {
                OneFlowLog.writeLog(error.localizedDescription, .error)
                return nil
            }
            return dir
        }
        return nil
    }
}

