//
//  SurveyListResponse.swift
//  Feedback
//
//  Created by Rohan Moradiya on 12/07/21.
//

import Foundation

struct SurveyListResponse: Codable {
    var success: Int
    var message: String
    var result: [Survey]
    
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
            var buttons: [FBButton]
            
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
                
                struct Choice: Codable {
                    var _id: String?
                    var title: String
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
            
            struct RetakeSurvey: Codable {
                var _id: String?
                var retake_input_value: Int?
                var retake_select_value: String?
            }
        }
        
    }
    
}
