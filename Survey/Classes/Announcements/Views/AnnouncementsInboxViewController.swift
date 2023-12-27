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
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var indicatorLabel: UILabel!
    @IBOutlet var indicatorContainer: UIStackView!
    var announcements: [Announcement]?
    var announcementList: [AnnouncementsDetails]?
    var heightDic = [Int: CGFloat]()
    var reloadTimer: Timer?
    var indexPaths: [IndexPath]?
    lazy var apiController: APIProtocol = OFAPIController.shared
    var viewedIndex = [Int]()

    enum IndicatorState {
        case hidden
        case loading
        case empty
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(
            nibName: "AnnouncementsInboxCell",
            bundle: OneFlowBundle.bundleForObject(self)
        )
        tableView.register(nib, forCellReuseIdentifier: "AnnouncementsInboxCell")
        tableView.estimatedRowHeight = 500
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        setupIndicatorView(state: .loading)
        fetchAnnouncementDetails { details in
            self.announcementList = details
            DispatchQueue.main.async {
                if self.announcementList?.isEmpty ?? true {
                    self.setupIndicatorView(state: .empty)
                } else {
                    self.setupIndicatorView(state: .hidden)
                    self.tableView.reloadData()
                }
            }
        }
    }

    func setupIndicatorView(state: IndicatorState) {
        switch state {
        case .hidden:
            indicatorContainer.isHidden = true
            loadingIndicator.stopAnimating()
            tableView.isHidden = false
        case .empty:
            indicatorContainer.isHidden = false
            loadingIndicator.isHidden = true
            loadingIndicator.stopAnimating()
            indicatorLabel.text = "Your inbox is empty."
            tableView.isHidden = true
        case .loading:
            indicatorContainer.isHidden = false
            loadingIndicator.isHidden = true
            loadingIndicator.startAnimating()
            indicatorLabel.text = "Loading"
        }
    }

    func fetchAnnouncementDetails(_ completion: @escaping ([AnnouncementsDetails]?) -> Void) {
        guard let announcements = announcements, !announcements.isEmpty else {
            completion(nil)
            return
        }
        let identifiers = announcements.map({ $0.identifier })
        let string = identifiers.joined(separator: ",")
        self.apiController.getAnnouncementsDetails(string) { isSuccess, error, data in
            guard let data = data else {
                OneFlowLog.writeLog("Error: \(error?.localizedDescription ?? "NA")", .error)
                return
            }
            do {
                let response = try JSONDecoder().decode(AnnouncementsResponse.self, from: data)
                OneFlowLog.writeLog(response)
                completion(response.result)
            } catch {
                OneFlowLog.writeLog("Error: \(error.localizedDescription)", .error)
                completion(nil)
            }
        }
    }

    @IBAction private func didTapClose(_ sender: Any) {
        for index in viewedIndex {
            announcements?[index].seen = true
            OneFlow.recordEventName(
                kEventNameAnnouncementViewed,
                parameters: [
                    "announcement_id": announcements?[index].identifier ?? "",
                    "channel": "inbox"
                ]
            )
        }
        uiDelegate?.inboxDidClosed(self)
    }
}

extension AnnouncementsInboxViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return announcementList?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "AnnouncementsInboxCell",
                for: indexPath
            ) as? AnnouncementsInboxCell
        else {
            return UITableViewCell()
        }
        cell.isUnread = !(announcements?[indexPath.row].seen ?? false)
        if let details = announcementList?[indexPath.row] {
            cell.index = indexPath.row
            cell.webContentHeight = heightDic[indexPath.row]
            cell.configureUI(with: details)
        }
        cell.delegate = self
        return cell
    }
}

extension AnnouncementsInboxViewController: AnnouncementsCellDelegate {
    func cellDidFinishCalculatingHeight(index: Int, height: CGFloat) {
        self.heightDic[index] = height
        viewedIndex.append(index)
        if reloadTimer?.isValid ?? false {
            reloadTimer?.invalidate()
        }
        if indexPaths == nil {
            indexPaths = [IndexPath]()
        }
        indexPaths?.append(IndexPath(row: index, section: 0))
        reloadTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(reloadRows), userInfo: nil, repeats: false)
    }

    @objc func reloadRows() {
        guard let indexPaths = self.indexPaths else {
            return
        }
        self.tableView.reloadRows(at: indexPaths, with: .none)
        self.indexPaths = nil
    }
}
