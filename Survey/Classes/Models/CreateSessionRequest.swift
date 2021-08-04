//
//  CreateSessionRequest.swift
//  Feedback
//
//  Created by Rohan Moradiya on 20/07/21.
//

import Foundation

struct CreateSessionRequest: Codable {
    var analytic_user_id: String
    var system_id: String
}
