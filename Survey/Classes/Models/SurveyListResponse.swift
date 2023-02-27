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

enum WidgetPosition : String, Codable {
    case topLeft = "top-left"
    case topCenter = "top-center"
    case topRight = "top-right"
    case middleLeft = "middle-left"
    case middleCenter = "middle-center"
    case middleRight = "middle-right"
    case bottomLeft = "bottom-left"
    case bottomCenter = "bottom-center"
    case bottomRight = "bottom-right"
    case topBanner = "top-banner"
    case bottomBanner = "bottom-banner"
    case fullScreen = "fullscreen"
}

struct SurveyListResponse: Codable {
    var success: Int
    var message: String?
    var result: [Survey]
    var throttlingMobileSDKConfig: ThrottlingConfiguration?
    
    struct Survey: Codable {
        var name: String
        var description: String?
        var num_responses: String?
        var end_date: String?
        var live: Bool?
        var platforms: [String]?
        var screens: [Screen]?
        var deleted: Bool?
        var deleted_on: String?
        var schema_version: Int?
        var _id: String
        var project_id: String?
        var style: Style?
        var trigger_event_name: String?
        var start_date: Int?
        var created_on: Int?
        var updated_on: Int?
        var __v: Int?
        var color: String?
        var survey_settings: SurveySettings?
        
        struct Screen: Codable {
            var title: String?
            var input: Input?
            var message: String?
            var _id: String
            var buttons: [FBButton]?
            var rules : Rule?
            var media_embed_html: String?
            
            struct Input: Codable {
                var _id: String
                var input_type: String
                var min_val: Int?
                var max_val: Int?
                var choices: [Choice]?
                var min_chars: Int?
                var max_chars: Int?
                var emoji: Bool?
                var star_fill_color: String?
                var stars: Bool?
                var placeholder_text: String?
                var rating_max_text: String?
                var rating_min_text: String?
                var other_option_id: String?
                var rating_text: [String:String]?

                struct Choice: Codable {
                    var _id: String?
                    var title: String?
                }
            }
            struct Rule : Codable {
                var userProperty : String
                var dataLogic : [DataLogic]?
                var dismiss_behavior : DismissBehaviour?
                struct DataLogic : Codable {
                    var condition : String?
                    var values : String?
                    var type : String?
                    var action : String?
                }
                struct DismissBehaviour : Codable {
                    var fades_away : Bool?
                    var delay_in_seconds : Int?
                }
            }
           
            struct FBButton: Codable {
                var _id: String
                var button_type: String
                var action: String?
                var title: String
            }
        }
        
        struct Style: Codable {
            var display_mode: String?
            var font: String?
            var _id: String?
            var primary_color: String?
            var corner_radius: Int?
            var change_trigger: Bool?
            var color_opacity: Int?
            var previous_change_color: Bool?
        }
        
        struct SurveySettings: Codable {
            var _id: String?
            var resurvey_option: Bool?
            var retake_survey: RetakeSurvey?
            var show_watermark: Bool?
            var closed_as_finished: Bool? = false
            var sdk_theme: SDKTheme?
            var override_global_throttling: Bool?
            
            struct RetakeSurvey: Codable {
                var _id: String?
                var retake_input_value: Int?
                var retake_select_value: String?
            }

            struct SDKTheme: Codable {
                var background_color: String?
                var remove_watermark: Bool?
                var dark_overlay: Bool?
                var close_button: Bool?
                var progress_bar: Bool?
                var widget_position: WidgetPosition?
                var text_color: String?
            }
        }
    }

    struct ThrottlingConfiguration: Codable {
        var isThrottlingActivated: Bool?
        var globalTime: Int?
        var activatedBySurveyID: String?
        var throttlingActivatedTime: Int?
    }
}
