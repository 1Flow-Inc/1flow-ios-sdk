//
//  SurveySubmitRequest.swift
//  Feedback
//
//  Created by Rohan Moradiya on 15/07/21.
//

import Foundation

struct SurveySubmitRequest: Codable {
    var analytic_user_id: String?
    var survey_id: String
    var os: String = "iOS"
    var answers: [Answer]?
    var session_id: String?
    
    struct Answer: Codable {
        var screen_id: String
        var answer_value: String?
        var answer_index: String?
    }
}
