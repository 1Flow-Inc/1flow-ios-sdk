//
//  EndPointPovider.swift
//  1Flow
//
//  Created by Rohan Moradiya on 30/04/22.
//

//https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/SDK-Credentials/incoming_webhook/Oneflow-dev-sdk-v3-credentials
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
    
    var url: String {
        let BaseURL: String = {
                if OFProjectDetailsController.shared.currentEnviromment == .dev {
                    return "https://dev-sdk.1flow.app/api/2021-06-15"
                } else {
                    return "https://api-sdk.1flow.app/api/2021-06-15"
                }
        }()
        switch self {
        case .addUser:
            return BaseURL + "/v3/user"
        case .getSurveys:
            var surveyUrl = BaseURL + "/v3/survey?platform=iOS"
            if let userID : String = OFProjectDetailsController.shared.analytic_user_id {
                surveyUrl = surveyUrl + "&user_id=" + userID
            }

            surveyUrl = surveyUrl + "&min_version=" + OFProjectDetailsController.shared.libraryVersion

            if let langStr = Locale.current.languageCode {
                surveyUrl = surveyUrl + "&language_code=" + langStr
                OneFlowLog.writeLog("Language Code: \(langStr)")
            }
            return surveyUrl
        case .fetchSurvey(let surveyID):
            var surveyUrl = BaseURL + "/v3/survey/\(surveyID)?platform=iOS"
            if let userID : String = OFProjectDetailsController.shared.analytic_user_id {
                surveyUrl = surveyUrl + "&user_id=" + userID
            }

            surveyUrl = surveyUrl + "&min_version=" + OFProjectDetailsController.shared.libraryVersion

            if let langStr = Locale.current.languageCode {
                surveyUrl = surveyUrl + "&language_code=" + langStr
                OneFlowLog.writeLog("Language Code: \(langStr)")
            }
            return surveyUrl
        case .addEvent:
            return BaseURL + "/v3/track"
        case .submitSurvey:
            return BaseURL + "/v3/response"
        case .logUser:
            return BaseURL + "/v3/identify"
        case .appStoreRating:
            guard let bundleID = Bundle.main.bundleIdentifier else {
                return ""
            }
            return "http://itunes.apple.com/lookup?bundleId=" + bundleID
        case .scriptUpdate:
            if OFProjectDetailsController.shared.currentEnviromment == .dev {
                return "https://cdn.1flow.app/index-dev.js"
            } else {
                return "https://cdn.1flow.app/index.js"
            }
            // https://cdn.1flow.app/index-beta.js for beta
        }
    }
}
