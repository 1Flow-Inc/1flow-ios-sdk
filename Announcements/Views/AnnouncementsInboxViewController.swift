//
//  AnnouncementsInboxViewController.swift
//  1Flow
//
//  Created by Rohan Moradiya on 21/10/23.
//

import UIKit

protocol AnnoucementsInboxUIDelegate: AnyObject {
    func inboxDidClosed(_ sender: AnnouncementsInboxViewController)
}
class AnnouncementsInboxViewController: UIViewController {

    weak var uiDelegate: AnnoucementsInboxUIDelegate?
    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction private func didTapClose(_ sender: Any) {
        uiDelegate?.inboxDidClosed(self)
    }
}
