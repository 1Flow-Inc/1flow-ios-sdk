// Copyright 2021 1Flow, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

struct CreateSessionRequest: Codable {

    var analyticsUserID: String
    var systemID: String
    var device: DeviceDetails?
    var connectivity: Connectivity?
    var appVersion: String?
    var appBuildNumber: String?
    var libraryVersion: String?
    var mode = OFProjectDetailsController.shared.currentEnviromment.rawValue

    private enum CodingKeys: String, CodingKey {
        case analyticsUserID = "analytic_user_id"
        case systemID = "system_id"
        case device
        case connectivity
        case appVersion = "app_version"
        case appBuildNumber = "app_build_number"
        case libraryVersion = "library_version"
        case mode
    }

    struct DeviceDetails: Codable {
        var operatingSystem: String
        var uniqueID: String
        var deviceID: String
        var carrier: String?
        var manufacturer: String = "apple"
        var model: String?
        var osVersion: String?
        var screenWidth: Int?
        var screenHeight: Int?

        private enum CodingKeys: String, CodingKey {
            case operatingSystem = "os"
            case uniqueID = "unique_id"
            case deviceID = "device_id"
            case carrier
            case manufacturer
            case model
            case osVersion = "os_ver"
            case screenWidth = "screen_width"
            case screenHeight = "screen_height"
        }
    }

    struct Connectivity: Codable {
        var carrier: String?
        var radio: String?
    }
}
