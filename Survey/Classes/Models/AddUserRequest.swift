//
//  AddUserRequest.swift
//  Feedback
//
//  Created by Rohan Moradiya on 20/07/21.
//

import Foundation

struct AddUserRequest: Codable {
    var system_id: String
    var device: DeviceDetails
    var location: LocationDetails?
    var location_check: Bool = true
    
    struct DeviceDetails:Codable {
        var os: String
        var unique_id: String
        var device_id: String
    }
    
    struct LocationDetails: Codable {
        var city: String?
        var region: String?
        var country: String?
        var latitude: Double?
        var longitude: Double?
    }
}
