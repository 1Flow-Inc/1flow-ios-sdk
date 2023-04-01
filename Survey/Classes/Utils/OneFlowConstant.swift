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


var kBrandColor = UIColor(red: 0.36, green: 0.37, blue: 0.93, alpha: 1.0)
var kBrandHightlightColor = kBrandColor.withAlphaComponent(0.21)
var kPrimaryTitleColor = UIColor.black
var kSecondaryTitleColor = kPrimaryTitleColor.withAlphaComponent(0.8)
var kFooterColor = UIColor.colorFromHex("787878")
var kOptionBackgroundColor = UIColor.colorFromHex("F3F3F3")
var kOptionBackgroundColorHightlighted = UIColor.white
var kWatermarkColor = kPrimaryTitleColor.withAlphaComponent(0.6)
var kWatermarkColorHightlighted = kPrimaryTitleColor.withAlphaComponent(0.05)
var kCloseButtonColor = kPrimaryTitleColor.withAlphaComponent(0.6)
var kBackgroundColor = UIColor.white
var kSubmitButtonColorDisable = kBrandColor.withAlphaComponent(0.5)
var kPlaceholderColor = kPrimaryTitleColor.withAlphaComponent(0.3)

let kBorderColor = UIColor(red: 0.76, green: 0.76, blue: 0.76, alpha: 1.0)
let kAppGreyBGColor = UIColor.colorFromHex("F3F3F3")

let kEventNameFirstAppOpen = "first_open"
let kEventNameAppUpdate = "app_updated"
let kEventNameSessionStart = "session_start"
let kEventNameInAppPurchase = "in_app_purchase"
let kEventNameSurveyImpression = "survey_impression"
let kEventNameFlowClosed = "$flow_closed"

struct InternalEvent {
    static let flowStarted = "flow_started"
    static let flowStepSeen = "flow_step_seen"
    static let flowStepClicked = "flow_step_clicked"
    static let questionAnswered = "question_answered"
    static let flowEnded = "flow_ended"
    static let flowCompleted = "flow_completed"
}

struct InternalKey {
    static let flowId = "flow_id"
    static let stepId = "step_id"
    static let questionId = "question_id"
    static let type = "type"
    static let answer = "answer"
    static let questionTitle = "question_title"
    static let questionDescription = "question_description"
    static let surveyName = "survey"
}
