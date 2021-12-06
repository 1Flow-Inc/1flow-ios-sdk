//
//  SubmittedSurvey.swift
//  Feedback
//
//  Created by Rohan Moradiya on 13/10/21.
//

import Foundation

struct SubmittedSurvey: Codable {
    var surveyID: String
    var submissionTime: Int
    var submittedByUserID: String?
    
    mutating func setNewUser(_ userID: String) {
        if self.submittedByUserID == nil {
            self.submittedByUserID = userID
        }
    }
}
