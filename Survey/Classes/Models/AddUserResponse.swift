//
//  AddUserResponse.swift
//  Feedback
//
//  Created by Rohan Moradiya on 29/10/21.
//

import Foundation

struct AddUserResponse: Codable {
    
    let success: Int?
    let result: User?
    struct User: Codable {
        var analytic_user_id: String?
        var system_id: String?
    }
}
