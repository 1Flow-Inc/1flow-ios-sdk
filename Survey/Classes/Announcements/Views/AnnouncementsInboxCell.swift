//
//  AnnouncementsInboxCell.swift
//  1Flow
//
//  Created by Rohan Moradiya on 21/10/23.
//

import UIKit
import WebKit

protocol AnnouncementsCellDelegate: AnyObject {
    func cellDidFinishCalculatingHeight(index: Int, height: CGFloat)
    func didTapActionButton(index: Int)
}

class AnnouncementsInboxCell: UITableViewCell {

    @IBOutlet var unReadIndicator: UIView!
    @IBOutlet var mainStackView: UIStackView!
    var webView: WKWebView?
    var index: Int = -1
    var webContentHeight: CGFloat?
    var details: AnnouncementsDetails?
    weak var delegate: AnnouncementsCellDelegate?
    var unreadColor = "#2D4EFF"

    override func prepareForReuse() {
        super.prepareForReuse()
        index = -1
        webContentHeight = nil
        webView = nil
        mainStackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    var isUnread: Bool = false {
        didSet {
            let color = isUnread ? UIColor.colorFromHex(unreadColor) : UIColor.clear
            unReadIndicator.backgroundColor = color
        }
    }

    func configureUI(with details: AnnouncementsDetails, theme: AnnouncementTheme?) {
        self.details = details
        self.unreadColor = theme?.brandColor ?? "#2D4EFF"
        self.backgroundColor = UIColor.colorFromHex(theme?.backgroundColor ?? "FFFFFF")
        let date = Date(timeIntervalSince1970: TimeInterval(details.publishedAt / 1000))
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        let dateString = formatter.string(from: date)
        
        if let category = details.category {
            mainStackView.addArrangedSubview(
                AnnouncementComponentBuilder.categoryView(with: category, date: dateString)
            )
        } else {
            mainStackView.addArrangedSubview(
                AnnouncementComponentBuilder.categoryView(with: nil, date: dateString)
            )
        }
        
        mainStackView.addArrangedSubview(
            AnnouncementComponentBuilder.verticalSpace(with: 5)
        )
        let textColor = UIColor.colorFromHex(theme?.textColor ?? "000000")
        mainStackView.addArrangedSubview(
            AnnouncementComponentBuilder.titleView(with: details.title, titleColor: textColor)
        )
        mainStackView.addArrangedSubview(
            AnnouncementComponentBuilder.verticalSpace(with: 10)
        )
        if let content = details.content {
            guard let webView = AnnouncementComponentBuilder.richTextContentView(with: content, textColor: theme?.textColor ?? "#2f54eb") as? WKWebView else {
                return
            }
            webView.navigationDelegate = self
            mainStackView.addArrangedSubview(webView)
            webView.isOpaque = false
            webView.backgroundColor = .clear
            webView.scrollView.backgroundColor = .clear
            self.webView = webView
            if let webContentHeight = self.webContentHeight {
                webView.heightAnchor.constraint(equalToConstant: webContentHeight).isActive = true
                self.mainStackView.alpha = 1.0
            } else {
                self.mainStackView.alpha = 0.0
            }
            mainStackView.addArrangedSubview(
                AnnouncementComponentBuilder.verticalSpace(with: 20)
            )
        }

        if let action = details.action {
            let brandColor = theme?.brandColor ?? "2D4EFF"
            mainStackView.addArrangedSubview(
                AnnouncementComponentBuilder.actionButtonInboxView(with: action.name, target: self, selector: #selector(didTapActionButton(_:)), color: brandColor)
            )

            mainStackView.addArrangedSubview(
                AnnouncementComponentBuilder.verticalSpace(with: 10)
            )
        }
    }

    @objc func didTapActionButton(_ sender: Any) {
        guard
            let urlString = details?.action?.link,
            let url = URL(string: urlString),
            let linkText = details?.action?.name
        else {
            OneFlowLog.writeLog("No action available")
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            OneFlowLog.writeLog("Can not open url: \(url)", .error)
        }
        delegate?.didTapActionButton(index: index)
        OneFlow.recordEventName(
            kEventNameAnnouncementClicked,
            parameters: [
                "announcement_id": self.details?.identifier ?? "",
                "channel": "inbox",
                "link_text": linkText,
                "link_url": urlString
            ]
        )
    }
}

extension AnnouncementsInboxCell: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        OneFlowLog.writeLog("Webview did finish loading", .verbose)
        guard self.webContentHeight == nil else {
            return
        }
        webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, _) in
            if complete != nil {
                webView.evaluateJavaScript("quill.root.scrollHeight", completionHandler: { (height, _) in
                    guard let finalHeight = height as? CGFloat else { return }
                    self.delegate?.cellDidFinishCalculatingHeight(index: self.index, height: finalHeight + 20)
                })
            }
        })
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated:
            if navigationAction.targetFrame == nil {
                if let url = navigationAction.request.url {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    } else {
                        OneFlowLog.writeLog("Can not open url: \(url)", .error)
                    }
                }
                decisionHandler(.cancel)
                return
            }
        default:
            break
        }
        
        if let url = navigationAction.request.url {
            print(url.absoluteString) // It will give the selected link URL
            
        }
        decisionHandler(.allow)
    }
}
