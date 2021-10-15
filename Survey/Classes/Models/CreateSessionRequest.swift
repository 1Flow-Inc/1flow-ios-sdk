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
    var device: DeviceDetails?
    var location: LocationDetails?
    var connectivity: Connectivity?
    var location_check: Bool = true
    var app_version: String?
    var app_build_number: String?
    var library_version: String?
    
    struct DeviceDetails:Codable {
        var os: String
        var unique_id: String
        var device_id: String
        var carrier: String?
        var manufacturer: String = "apple"
        var model: String?
        var os_ver: String?
        var screen_width: Int?
        var screen_height: Int?
    }
    
    struct LocationDetails: Codable {
        var city: String?
        var region: String?
        var country: String?
        var latitude: Double?
        var longitude: Double?
    }
    struct Connectivity: Codable {
        var carrier: String?
        var radio: String?
    }
}
