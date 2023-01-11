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

struct AddUserRequest: Codable {
    var user_id: String
    var context: Context

    struct Context: Codable {
        var app: AppDetails
        var device: DeviceDetails
        var library: LibraryDetails
        var network: NetworkDetails
        var os: OSDetails
        var screen: ScreenDetails

        struct AppDetails: Codable {
            var version: String
            var build: String
        }

        struct DeviceDetails: Codable {
            var manufacturer: String
            var model: String?
        }

        struct LibraryDetails: Codable {
            var version: String?
            var name: String
        }

        struct NetworkDetails: Codable {
            var carrier: String?
            var wifi: Bool
        }

        struct OSDetails: Codable {
            var name: String
            var version: String
        }

        struct ScreenDetails: Codable {
            var width: Int
            var height: Int
            var type: String
        }
    }
}
