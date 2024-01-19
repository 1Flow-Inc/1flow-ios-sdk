//
//  BannerView.swift
//  1Flow
//
//  Created by Rohan Moradiya on 11/12/23.
//

import UIKit

protocol BannerDelegate: AnyObject {
    func bannerViewDidTapppedClosed(_ sender: BannerView)
}
enum BannerType {
    case top
    case bottom
}

@objc(OBJCBannerView)
class BannerView: UIView {
    @IBOutlet var textView: UITextView!
    @IBOutlet var closeButton: UIButton!

    weak var delegate: BannerDelegate?
    var type: BannerType = .top
    var details: AnnouncementsDetails?

    func setupUI(with details: AnnouncementsDetails, theme: AnnouncementTheme?) {
        self.details = details
        let backColor = details.category?.color ?? "808080"
        let backgroundColor = UIColor.colorFromHex(backColor)
        let textColor = UIColor.getTextColorForBackground(backColor)
        closeButton.tintColor = textColor
        let attributedString = NSMutableAttributedString(
            string: details.title + "  ",
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: textColor
            ]
        )
        if let actionTitle = details.action?.name, let link = details.action?.link {
            let actionString = NSMutableAttributedString(
                string: actionTitle,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                    .foregroundColor: textColor,
                    .link: link
                    ]
            )
            attributedString.append(actionString)
        }
        textView.backgroundColor = .clear
        textView.attributedText = attributedString
        textView.dataDetectorTypes = .link
        textView.delegate = self
        textView.linkTextAttributes = [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: textColor,
            .underlineStyle: 1
        ]
        
        textView.isEditable = false
        self.backgroundColor = backgroundColor
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        var frame = self.frame
        frame.size.height = newSize.height + 20
        self.frame = frame
    }

    @IBAction private func didTappedClose(_ sender: Any) {
        delegate?.bannerViewDidTapppedClosed(self)
    }
}

extension BannerView: UITextViewDelegate {
    // Handle link taps
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
        OneFlowLog.writeLog("Link tapped: \(url.absoluteString)")
        // Open URL or perform any desired action
        UIApplication.shared.open(url)
        OneFlow.recordEventName(
            kEventNameAnnouncementClicked,
            parameters: [
                "announcement_id": self.details?.identifier ?? "",
                "channel": "in-app",
                "link_text": details?.action?.name ?? "",
                "link_url": details?.action?.link ?? ""
            ]
        )
        return false
    }
}
