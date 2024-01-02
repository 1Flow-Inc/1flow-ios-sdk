//
//  AnnouncementModalViewController.swift
//  1Flow
//
//  Created by Rohan Moradiya on 17/12/23.
//

import UIKit
import WebKit

protocol AnnouncementModalDelegate: AnyObject {
    func announcementModalDidClosed(_ sender: Any)
}
class AnnouncementModalViewController: UIViewController {

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var centerVerticalConstraint: NSLayoutConstraint!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet var topConstraint: NSLayoutConstraint!

    var details: AnnouncementsDetails?
    var webContentHeight: NSLayoutConstraint?
    weak var delegate: AnnouncementModalDelegate?
    var theme: AnnouncementTheme?
    var style: String?
    lazy var waterMarkURL = "https://1flow.app/?utm_source=1flow-ios-sdk&utm_medium=watermark&utm_campaign=real-time+feedback+powered+by+1flow"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI(details)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        performPresentAnimation()
    }

    func performPresentAnimation() {
        print(style ?? "NA")
        switch style {
        case "top_left", "top_right":
            self.centerVerticalConstraint.isActive = false
            self.bottomConstraint.isActive = false
            self.bottomConstraint = nil
            let margins = view.layoutMarginsGuide
            self.bottomConstraint = scrollView.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: self.scrollView.bounds.height)
            self.bottomConstraint.isActive = true
            self.topConstraint.constant = self.view.bounds.height * 0.2
            UIView.animate(withDuration: 0.5, animations: {
                self.bottomConstraint.constant = 0
            })
        case "bottom_left", "bottom_right":
            self.centerVerticalConstraint.isActive = false
            self.topConstraint.isActive = false
            let margins = view.layoutMarginsGuide
            self.topConstraint = scrollView.topAnchor.constraint(equalTo: margins.topAnchor, constant: -self.scrollView.bounds.height)
            self.topConstraint.isActive = true
            self.bottomConstraint.constant = self.view.bounds.height * 0.2
            let topInset: CGFloat
            if #available(iOS 11.0, *) {
                topInset = self.view.window?.safeAreaInsets.top ?? 0
            } else {
                topInset = 0
            }
            UIView.animate(withDuration: 0.5, animations: {
                self.topConstraint.constant = topInset
            })
        default:
            break
        }
    }

    func setupUI(_ details: AnnouncementsDetails?) {
        guard let details = details else {
            return
        }
        stackView.layer.cornerRadius = 5
        let textColor = UIColor.colorFromHex(theme?.textColor ?? "000000")
        let backgroundColor = UIColor.colorFromHex(theme?.backgroundColor ?? "FFFFFF")
        closeButton.tintColor = textColor
//        let date = Date(timeIntervalSince1970: TimeInterval(details.publishedAt / 1000))
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMM dd, yyyy"
//        let dateString = formatter.string(from: date)
        
        if let category = details.category {
            stackView.addArrangedSubview(
                AnnouncementComponentBuilder.categoryView(with: category, date: nil)
            )
        }
//        else {
//            stackView.addArrangedSubview(
//                AnnouncementComponentBuilder.categoryView(with: nil, date: dateString)
//            )
//        }
        
        stackView.addArrangedSubview(
            AnnouncementComponentBuilder.verticalSpace(with: 5)
        )
        stackView.addArrangedSubview(
            AnnouncementComponentBuilder.titleView(with: details.title, titleColor: textColor)
        )
        stackView.addArrangedSubview(
            AnnouncementComponentBuilder.verticalSpace(with: 10)
        )
        if let content = details.content {
            guard let webView = AnnouncementComponentBuilder.richTextContentView(with: content, textColor: theme?.textColor ?? "#2f54eb") as? WKWebView else {
                return
            }
            webView.navigationDelegate = self
            stackView.addArrangedSubview(webView)
            webView.isOpaque = false
            webView.backgroundColor = .clear
            webView.scrollView.backgroundColor = .clear
            stackView.addArrangedSubview(
                AnnouncementComponentBuilder.verticalSpace(with: 20)
            )
        }

        if let action = details.action {
            let brandColor = theme?.brandColor ?? "#2D4EFF"
            stackView.addArrangedSubview(
                AnnouncementComponentBuilder.actionButtonView(with: action.name, target: self, selector: #selector(didTapActionButton(_:)), color: brandColor)
            )
        }
        stackView.addArrangedSubview(
            AnnouncementComponentBuilder.poweredBy1FlowView(with: self, selector: #selector(didTapPoweredByButton(_:)))
        )
        stackView.backgroundColor = backgroundColor
    }

    @objc func didTapPoweredByButton(_ sender: Any) {
        guard let url = URL(string: waterMarkURL) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    @objc func didTapActionButton(_ sender: Any) {
        guard
            let urlString = details?.action?.link,
            let url = URL(string: urlString)
        else {
            OneFlowLog.writeLog("No action available", .error)
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            OneFlowLog.writeLog("Can not open url: \(url)", .error)
        }
    }
}

extension AnnouncementModalViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        OneFlowLog.writeLog("Webview did finish loading", .verbose)
        guard self.webContentHeight == nil else {
            return
        }
        webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, _) in
            if complete != nil {
                webView.evaluateJavaScript("quill.root.scrollHeight", completionHandler: { (height, _) in
                    guard let finalHeight = height as? CGFloat else { return }
                    self.webContentHeight = webView.heightAnchor.constraint(equalToConstant: finalHeight + 20)
                    self.webContentHeight?.isActive = true
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

    @IBAction private func didTapCloseButton(_ sender: Any) {
        switch style {
        case "top_left", "top_right":
            UIView.animate(withDuration: 0.5) {
                self.bottomConstraint.constant = self.scrollView.bounds.height
                self.view.layoutIfNeeded()
            }completion: { _ in
                self.delegate?.announcementModalDidClosed(self)
            }
        case "bottom_left", "bottom_right":
            UIView.animate(withDuration: 0.5, animations: {
                self.topConstraint.constant = -self.scrollView.bounds.height
                self.view.layoutIfNeeded()
            }) { _ in
                self.delegate?.announcementModalDidClosed(self)
            }
        default:
            delegate?.announcementModalDidClosed(self)
        }
        
    }
}
