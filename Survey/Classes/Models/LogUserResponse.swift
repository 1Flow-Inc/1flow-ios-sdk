//
//  LogUserResponse.swift
//  Feedback
//
//  Created by Rohan Moradiya on 29/10/21.
//

import Foundation

struct LogUserResponse: Codable {
    let success: Int?
    let result: LogResult?
    
    struct LogResult: Codable {
        let analytic_user_id: String?
        let system_id: String?
        let session: Session?
        
        struct Session: Codable {
            let _id: String?
        }
    }
}
