//
//  OFWebContainerView.swift
//  Pods
//
//  Created by Rohan Moradiya on 09/02/23.
//

import UIKit
import WebKit
var currentIndex: Int = 0

protocol WebContainerDelegate: AnyObject {
    func webContainerDidLoadWith(_ contentHeight: CGFloat)
}

@objc(OBJCOFWebContainerView)
class OFWebContainerView: UIView, WKNavigationDelegate {

    weak var delegate: WebContainerDelegate?
    var webview: WKWebView?

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func loadHTMLContent(_ string: String) {
        if self.webview != nil {
            self.webview?.removeFromSuperview()
            self.webview = nil
        }
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        let wkWebview = WKWebView(frame: .zero, configuration: configuration)
        wkWebview.navigationDelegate = self
        self.addSubview(wkWebview)
        wkWebview.isOpaque = false
        wkWebview.backgroundColor = UIColor.clear
        wkWebview.scrollView.backgroundColor = UIColor.clear
        wkWebview.translatesAutoresizingMaskIntoConstraints = false
        var constraints = [NSLayoutConstraint]()
        constraints.append(wkWebview.leadingAnchor.constraint(equalTo: self.leadingAnchor))
        constraints.append(wkWebview.trailingAnchor.constraint(equalTo: self.trailingAnchor))
        constraints.append(wkWebview.topAnchor.constraint(equalTo: self.topAnchor))
        constraints.append(wkWebview.bottomAnchor.constraint(equalTo: self.bottomAnchor))
        constraints.forEach({ $0.isActive = true })
        self.webview = wkWebview
        self.webview?.scrollView.isScrollEnabled = false
        self.webview?.scrollView.showsVerticalScrollIndicator = false
        self.webview?.scrollView.showsHorizontalScrollIndicator = false
        let finalString: String
        if string.hasPrefix("<img") {
            finalString = string.replacingOccurrences(of: "max-width", with: "width")
        } else {
            finalString = string
        }
        self.webview?.loadHTMLString(finalString, baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        OneFlowLog.writeLog("Webview did finish loading", .verbose)
        webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, error) in
            if complete != nil {
                webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { (height, error) in
                    guard let finalHeight = height as? CGFloat else { return }
                    self.delegate?.webContainerDidLoadWith(finalHeight)
                })
            }
            
        })
    }

    func stopLoadingContent() {
        self.webview?.loadHTMLString("", baseURL: nil)
    }
}


