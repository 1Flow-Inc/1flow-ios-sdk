//
//  AnnouncementComponentBuilder.swift
//  1Flow
//
//  Created by Rohan Moradiya on 21/10/23.
//

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

static let html =
"""
<html>
    <head>
        <link href="https://cdn.jsdelivr.net/npm/quill-emoji@0.2.0/dist/quill-emoji.min.css" rel="stylesheet">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/quill/1.3.7/quill.snow.min.css" integrity="sha512-/FHUK/LsH78K9XTqsR9hbzr21J8B8RwHR/r8Jv9fzry6NVAOVIGFKQCNINsbhK7a1xubVu2r5QZcz2T9cKpubw==" crossorigin="anonymous" referrerpolicy="no-referrer" />
        <link href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/styles/atom-one-light.min.css" rel="stylesheet">

        <style>
            .ql-container {
                font-family: Inter;
            }

            .ql-toolbar,
            .ql-blank {
                display: none;
            }

            .ql-snow  a {
                color: #2f54eb;
            }

            .ql-snow .ql-editor {
                padding: 0;
                word-break: break-word;
            }

            .ql-snow .ql-editor pre.ql-syntax  {
                padding: 10px;
                color: var(--oneflow-rich-text-preview-color);
                background-color: rgba(0, 0, 0, 0.05);
                border-radius: 8px;
            }

            .ql-snow .ql-editor blockquote {
                margin-top: 0;
                margin-bottom: 0;
            }

            .ql-container.ql-snow {
                border: none;
            }

            .editor {
                color: var(--oneflow-rich-text-preview-color);
            }

            .editor-content::-webkit-scrollbar {
                width: 8px;
                height: 8px;
            }

            .editor-content::-webkit-scrollbar-thumb  {
                cursor: pointer;
                background-color: rgba(0, 0, 0, 0.2);
                border-radius: 4px;
            }

            .editor-content::-webkit-scrollbar-track {
                background-color: transparent;
            }

            @media screen and (max-width: 568px) {
                .editor-content {
                    max-height: 100vh;
                }
            }
        </style>
    </head>
    <body>

    <!-- Create the editor container -->
    <div id="quill-editor" class="editor">
        <div id="editor-content" class="editor-content">
        </div>
    </div>

    <!-- Include the Quill library -->
    <script src="https://cdn.quilljs.com/1.3.6/quill.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/quill-emoji@0.2.0/dist/quill-emoji.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/javascript.min.js" integrity="sha512-H69VMoQ814lKjFuFwLImb4OwoK8Rm8fcvsqZexaxjp/VkJfEnrt5TO7oaOdNlMf/j51QUctfLTe8+rgozW7l2A==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>

    <!-- Initialize Quill editor -->
    <script>
        /* color in the next line should be updated with the theme color */
        document.getElementById('quill-editor').style.setProperty('--oneflow-rich-text-preview-color', 'TEXTCOLOR');

        var quill = new Quill('#editor-content', {
            theme: 'snow',
            modules: {
                toolbar: [],
                'emoji-shortname': true,
                syntax: {
                    highlight: (text) => hljs.highlightAuto(text).value,
                },
            },
            readOnly: true
        });

        /* content in the next line should be updated with the real content */
        quill.setContents(XXXXXX);
    </script>
    </body>
</html>
"""

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
        
        let text = html
            .replacingOccurrences(of: "XXXXXX", with: content)
            .replacingOccurrences(of: "TEXTCOLOR", with: textColor)
        
        let file = "myHTML\(OFProjectDetailsController.objectId()).html" //this is the file. we will write to and read from it
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {

            let fileURL = dir.appendingPathComponent(file)
            //writing
            do {
                try text.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {
                OneFlowLog.writeLog(error.localizedDescription, .error)
            }
            let request = URLRequest(url: fileURL)
            webview.load(request)
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
}
