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

struct SurveySubmitRequest: Codable {
    var analyticUserID: String?
    var surveyID: String
    let operatingSystem: String = "iOS"
    var answers: [Answer]?
    var sessionID: String?
    var triggerEvent: String?
    var totDuration: Int
    var identifier: String?

    enum CodingKeys: String, CodingKey {
        case analyticUserID = "analytic_user_id"
        case surveyID = "survey_id"
        case operatingSystem = "os"
        case answers
        case sessionID = "session_id"
        case triggerEvent = "trigger_event"
        case totDuration = "tot_duration"
        case identifier = "_id"
    }

    struct Answer: Codable {
        var screenID: String
        var answerValue: String?
        var answerIndex: String?

        enum CodingKeys: String, CodingKey {
            case screenID = "screen_id"
            case answerValue = "answer_value"
            case answerIndex = "answer_index"
        }
    }
}
