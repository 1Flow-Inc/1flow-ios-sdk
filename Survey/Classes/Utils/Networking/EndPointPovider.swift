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
    
    var url: String {
        switch self {
        case .addUser:
            return "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/project-analytics-user/incoming_webhook/add-user"
        case .createSession:
            return "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/sessions/incoming_webhook/add_sessions"
        case .getSurveys:
            var surveyUrl = "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/survey/incoming_webhook/get-surveys?mode=\(OFProjectDetailsController.shared.currentEnviromment.rawValue)&platform=iOS"

            if let sessionID : String = OFProjectDetailsController.shared.analytics_session_id {
                surveyUrl = surveyUrl + "&session_id=" + sessionID
            }

            if let userID : String = OFProjectDetailsController.shared.analytic_user_id {
                surveyUrl = surveyUrl + "&user_id=" + userID
            }
            return surveyUrl
        case .addEvent:
            return "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/events-bulk/incoming_webhook/insert-events"
        case .submitSurvey:
            return "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/survey/incoming_webhook/add_survey_response"
        case .logUser:
            return "https://us-west-2.aws.webhooks.mongodb-realm.com/api/client/v2.0/app/1flow-wslxs/service/Log-user/incoming_webhook/anonymous-user-api"
        }
    }
}
