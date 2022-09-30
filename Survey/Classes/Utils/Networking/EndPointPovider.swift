//
//  EndPointPovider.swift
//  1Flow
//
//  Created by Rohan Moradiya on 30/04/22.
//

import Foundation

protocol EndPointProtocol {
    var url: String { get }
}

enum EndPoints: EndPointProtocol {
    case addUser
    case createSession
    case getSurveys
    case addEvent
    case submitSurvey
    case logUser
    case appStoreRating
    
    var url: String {
        let BaseURL: String = {
                if OFProjectDetailsController.shared.currentEnviromment == .dev {
                    return "https://ez37ppkkcs.eu-west-1.awsapprunner.com/api/2021-06-15"
                } else {
                    return "https://y33xx6sddf.eu-west-1.awsapprunner.com/api/2021-06-15"
                }
        }()
        switch self {
        case .addUser:
            return BaseURL + "/add-user"
        case .createSession:
            return BaseURL + "/add-session"
        case .getSurveys:
            var surveyUrl = BaseURL + "/surveys?&platform=iOS"

            if let sessionID : String = OFProjectDetailsController.shared.analytics_session_id {
                surveyUrl = surveyUrl + "&session_id=" + sessionID
            }
            
            if let bundle = Bundle.allFrameworks.first(where: { $0.bundleIdentifier?.contains("1Flow") ?? false } ) {
                if let libraryVersion = bundle.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String {
                    surveyUrl = surveyUrl + "&min_version=" + libraryVersion
                } else {
                    surveyUrl = surveyUrl + "&min_version=" + OFProjectDetailsController.shared.oneFlowSDKVersion
                }
            } else {
                surveyUrl = surveyUrl + "&min_version=" + OFProjectDetailsController.shared.oneFlowSDKVersion
            }
            if let langStr = Locale.current.languageCode {
                surveyUrl = surveyUrl + "&language_code=" + langStr
                OneFlowLog.writeLog("Language Code: \(langStr)")
            }
            
            if let userID : String = OFProjectDetailsController.shared.analytic_user_id {
                surveyUrl = surveyUrl + "&user_id=" + userID
            }
            return surveyUrl
        case .addEvent:
            return BaseURL + "/events"
        case .submitSurvey:
            return BaseURL + "/add-responses"
        case .logUser:
            return BaseURL + "/log-user"
        case .appStoreRating:
            guard let bundleID = Bundle.main.bundleIdentifier else {
                return ""
            }
            return "http://itunes.apple.com/lookup?bundleId=" + bundleID
        }
    }
}
