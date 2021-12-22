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
import UIKit

func OneFlowLog(_ string: Any) {
    #if DEBUG
        print("[1Flow] " + "\(string)")
    #endif
}

var kPrimaryColor = UIColor(red: 0.36, green: 0.37, blue: 0.93, alpha: 1.0)
var kPrimaryHightlightColor = kPrimaryColor.withAlphaComponent(0.21)
let kBorderColor = UIColor(red: 0.76, green: 0.76, blue: 0.76, alpha: 1.0)

let kEventNameFirstAppOpen = "first_open"
let kEventNameAppUpdate = "app_updated"
let kEventNameSessionStart = "session_start"
let kEventNameInAppPurchase = "in_app_purchase"
let kEventNameSurveyImpression = "survey_impression"
