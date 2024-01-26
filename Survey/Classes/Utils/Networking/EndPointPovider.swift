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

protocol EndPointProtocol {
    var url: String { get }
}

enum EndPoints: EndPointProtocol {
    case addUser
    case getSurveys
    case addEvent
    case submitSurvey
    case logUser
    case appStoreRating
    case fetchSurvey(String)
    case scriptUpdate
    case getAnnouncements
    case getAnnouncementsDetails(String)
    case pushToken

    var url: String {
        let baseURL: String = {
                if OFProjectDetailsController.shared.currentEnviromment == .dev {
                    return "https://dev-sdk.1flow.app/api/2021-06-15"
                } else {
                    return "https://api-sdk.1flow.app/api/2021-06-15"
//                    return "https://beta-sdk.1flow.app/api/2021-06-15"
                }
        }()
        switch self {
        case .addUser:
            return baseURL + "/v3/user"
        case .getSurveys:
            var surveyUrl = baseURL + "/v3/survey?platform=iOS"
            if let userID = OFProjectDetailsController.shared.analyticUserID {
                surveyUrl = surveyUrl + "&user_id=" + userID
            }

            surveyUrl = surveyUrl + "&min_version=" + OFProjectDetailsController.shared.libraryVersion

            if let langStr = Locale.current.languageCode {
                surveyUrl = surveyUrl + "&language_code=" + langStr
                OneFlowLog.writeLog("Language Code: \(langStr)")
            }
            return surveyUrl
        case .fetchSurvey(let surveyID):
            var surveyUrl = baseURL + "/v3/survey/\(surveyID)?platform=iOS"
            if let userID = OFProjectDetailsController.shared.analyticUserID {
                surveyUrl = surveyUrl + "&user_id=" + userID
            }

            surveyUrl = surveyUrl + "&min_version=" + OFProjectDetailsController.shared.libraryVersion

            if let langStr = Locale.current.languageCode {
                surveyUrl = surveyUrl + "&language_code=" + langStr
                OneFlowLog.writeLog("Language Code: \(langStr)")
            }
            return surveyUrl
        case .addEvent:
            return baseURL + "/v3/track"
        case .submitSurvey:
            return baseURL + "/v3/response"
        case .logUser:
            return baseURL + "/v3/identify"
        case .appStoreRating:
            guard let bundleID = Bundle.main.bundleIdentifier else {
                return ""
            }
            return "http://itunes.apple.com/lookup?bundleId=" + bundleID
        case .scriptUpdate:
            if OFProjectDetailsController.shared.currentEnviromment == .dev {
                return "https://cdn-development.1flow.ai/js-sdk/filter.js"
            } else {
                return "https://cdn.1flow.app/index.js"
            }
        case .getAnnouncements:
            var announcementUrl = baseURL + "/v3/announcements?platform=iOS"
            if let userID = OFProjectDetailsController.shared.analyticUserID {
                announcementUrl = announcementUrl + "&user_id=" + userID
            }
            return announcementUrl
        case .getAnnouncementsDetails(let ids):
            return baseURL + "/v3/announcements/inbox?ids=\(ids)"
        case .pushToken:
            return "https://dev-dashboard-api.1flow.app/api/v1/2021-06-15/details/device"
        }
    }
}
