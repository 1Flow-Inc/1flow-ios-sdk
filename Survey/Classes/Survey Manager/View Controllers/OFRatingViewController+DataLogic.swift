//
//  OFRatingViewController+DataLogic.swift
//  1Flow
//
//  Created by Rohan Moradiya on 30/09/23.
//

import Foundation
import StoreKit

extension OFRatingViewController {
    func getNextQuestionIndex(_ previousAnswer: String?) -> Int? {
        var nextSurveyIndex: Int!
        if currentScreenIndex == -1 {
            nextSurveyIndex = currentScreenIndex + 1
            return nextSurveyIndex
        }
        guard let allScreens = allScreens else {
            // never executed
            return 0
        }
        OneFlowDataLogic().getNextAction(
            currentIndex: currentScreenIndex,
            allSurveys: allScreens,
            previousAnswer: previousAnswer,
            completion: { (action, nextIndex, urlToOpen) -> Void in
            if let actionToPerform = action {
                if actionToPerform == "open-url" {
                    if let actionUrl = urlToOpen {
                        self.performOpenUrlAction(actionUrl)
                        return
                    }
                } else if actionToPerform == "rating" {
                    self.performRatingAction()
                    return
                } else if actionToPerform == "skipTo" {
                    if let nextQuestionIndex = nextIndex {
                        nextSurveyIndex = nextQuestionIndex
                    }
                }
            } else {
                OneFlowLog.writeLog("Data Logic : No Action detected for this question")
                nextSurveyIndex = currentScreenIndex + 1

            }
        })
        return nextSurveyIndex
    }

    func checkandPerformEndScreenAction() {
        OneFlowLog.writeLog("End Screen logic : Check for end screen data logic")
        guard let allScreens = allScreens else {
            return
        }
        OneFlowDataLogic().getNextAction(
            currentIndex: currentScreenIndex,
            allSurveys: allScreens,
            previousAnswer: "",
            completion: { (action, _, urlToOpen) -> Void in
            if let actionToPerform = action {
                if actionToPerform == "open-url" {
                    if let actionUrl = urlToOpen {
                        OneFlowLog.writeLog("End Screen logic : URL action detected with url \(actionUrl)")
                        self.performOpenUrlAction(actionUrl)
                        return
                    }
                } else if actionToPerform == "rating" {
                    OneFlowLog.writeLog("End Screen logic : Rating detected")
                    self.performRatingAction()
                    return
                } else {
                    guard let completion = self.completionBlock else { return }
                    self.runCloseAnimation {
                        completion(self.surveyResult, self.isSurveyFullyAnswered)
                    }
                }
            } else {
                OneFlowLog.writeLog("End Screen logic : No Action detected")
                guard let completion = self.completionBlock else { return }
                self.runCloseAnimation {
                    completion(self.surveyResult, self.isSurveyFullyAnswered)
                }
            }
        })
    }

    private func performRatingAction() {
        currentScreenIndex = -2
        guard let completion = self.completionBlock else { return }
        self.runCloseAnimation {
            self.openRatemePopup()
            completion(self.surveyResult, self.isSurveyFullyAnswered)
        }
    }

    private func openRatemePopup() {
        if #available(iOS 14.0, *) {
            if let currentWindowScene = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .compactMap({$0 as? UIWindowScene})
                .first {
                SKStoreReviewController.requestReview(in: currentWindowScene)
            } else {
                OneFlowLog.writeLog("Could not fetch currentWindowScene while showing rating")
            }
        } else {
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
            } else {
                self.openAppStoreRateMeUrl()
            }
        }
    }

    private func openAppStoreRateMeUrl() {
        OFAPIController.shared.getAppStoreDetails { [weak self] isSuccess, error, data in
            guard self != nil else {
                return
            }
            if isSuccess == true, let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let results: NSArray =  json!["results"] as? NSArray {
                        if results.count > 0 {
                            guard let result = results.firstObject as? NSDictionary else {
                                return
                            }
                            if let trackId = result["trackId"] {
                                let ratingUrl = "https://itunes.apple.com/app/id\(trackId)?action=write-review"
                                OneFlowLog.writeLog("Data Logic : App store rating Url : \(ratingUrl)")
                                guard let url = URL(string: ratingUrl) else {
                                    return
                                }
                                DispatchQueue.main.async {
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                }
                            }
                        } else {
                            OneFlowLog.writeLog("Data Logic : App Store track ID not found")
                        }
                    }
                } catch {
                    OneFlowLog.writeLog("Data Logic : App Store Url not found")
                }
            } else {
                OneFlowLog.writeLog(error?.localizedDescription ?? "NA")
            }
        }
    }

    private func performOpenUrlAction(_ urlString: String) {
        currentScreenIndex = -2
        guard let completion = self.completionBlock else { return }
        self.runCloseAnimation {
            guard let url = URL(string: urlString) else {
                OneFlowLog.writeLog("Data Logic : Invalid Url received from server")
                completion(self.surveyResult, self.isSurveyFullyAnswered)
                return
            }
            DispatchQueue.main.async {
                if UIApplication.shared.canOpenURL(url) {
                    OneFlowLog.writeLog("Data Logic : Opening Url  : \(url.absoluteURL)")
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    OneFlowLog.writeLog("Data Logic : Can not open url : \(url.absoluteURL)")
                }
            }
            completion(self.surveyResult, self.isSurveyFullyAnswered)
        }
    }
}
