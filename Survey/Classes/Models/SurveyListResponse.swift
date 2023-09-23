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

enum WidgetPosition: String, Codable {
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
        var numResponses: String?
        var endDate: String?
        var live: Bool?
        var platforms: [String]?
        var screens: [Screen]?
        var deleted: Bool?
        var deletedOn: String?
        var schemaVersion: Int?
        var identifier: String
        var projectID: String?
        var style: Style?
        var triggerEventName: String?
        var startDate: Int?
        var createdOn: Int?
        var updatedOn: Int?
        var version: Int?
        var color: String?
        var surveySettings: SurveySettings?
        var surveyTimeInterval: SurveySettings.TimingOption?

        enum CodingKeys: String, CodingKey {
            case name
            case description
            case numResponses = "num_responses"
            case endDate = "end_date"
            case live
            case platforms
            case screens
            case deleted
            case deletedOn = "deleted_on"
            case schemaVersion = "schema_version"
            case identifier = "_id"
            case projectID = "project_id"
            case style
            case triggerEventName = "trigger_event_name"
            case startDate = "start_date"
            case createdOn = "created_on"
            case updatedOn = "updated_on"
            case version = "__v"
            case color
            case surveySettings = "survey_settings"
            case surveyTimeInterval = "survey_time_interval"
        }

        struct Screen: Codable {
            var title: String?
            var input: Input?
            var message: String?
            var identifier: String
            var buttons: [FBButton]?
            var rules: Rule?
            var mediaEmbedHtml: String?

            enum CodingKeys: String, CodingKey {
                case title
                case input
                case message
                case identifier = "_id"
                case buttons
                case rules
                case mediaEmbedHtml = "media_embed_html"
            }

            struct Input: Codable {
                var identifier: String
                var inputType: String
                var minVal: Int?
                var maxVal: Int?
                var choices: [Choice]?
                var minChars: Int?
                var maxChars: Int?
                var emoji: Bool?
                var starFillColor: String?
                var stars: Bool?
                var placeholderText: String?
                var ratingMaxText: String?
                var ratingMinText: String?
                var otherOptionID: String?
                var ratingText: [String: String]?

                enum CodingKeys: String, CodingKey {
                    case identifier = "_id"
                    case inputType = "input_type"
                    case minVal = "min_val"
                    case maxVal = "max_val"
                    case choices
                    case minChars = "min_chars"
                    case maxChars = "max_chars"
                    case emoji
                    case starFillColor = "star_fill_color"
                    case stars
                    case placeholderText = "placeholder_text"
                    case ratingMaxText = "rating_max_text"
                    case ratingMinText = "rating_min_text"
                    case otherOptionID = "other_option_id"
                    case ratingText = "rating_text"
                }

                struct Choice: Codable {
                    var identifier: String?
                    var title: String?

                    enum CodingKeys: String, CodingKey {
                        case identifier = "_id"
                        case title
                    }
                }
            }

            struct Rule: Codable {
                var userProperty: String
                var dataLogic: [DataLogic]?
                var dismissBehavior: DismissBehaviour?

                enum CodingKeys: String, CodingKey {
                    case userProperty
                    case dataLogic
                    case dismissBehavior = "dismiss_behavior"
                }

                struct DataLogic: Codable {
                    var condition: String?
                    var values: String?
                    var type: String?
                    var action: String?
                }

                struct DismissBehaviour: Codable {
                    var fadesAway: Bool?
                    var delayInSeconds: Int?

                    enum CodingKeys: String, CodingKey {
                        case fadesAway = "fades_away"
                        case delayInSeconds = "delay_in_seconds"
                    }
                }
            }

            struct FBButton: Codable {
                var identifier: String
                var buttonType: String
                var action: String?
                var title: String

                enum CodingKeys: String, CodingKey {
                    case identifier = "_id"
                    case buttonType = "button_type"
                    case action
                    case title
                }
            }
        }

        struct Style: Codable {
            var displayMode: String?
            var font: String?
            var identifier: String?
            var primaryColor: String?
            var cornerRadius: Int?
            var changeTrigger: Bool?
            var colorOpacity: Int?
            var previousChangeColor: Bool?

            enum CodingKeys: String, CodingKey {
                case displayMode = "display_mode"
                case font
                case identifier = "_id"
                case primaryColor = "primary_color"
                case cornerRadius = "corner_radius"
                case changeTrigger = "change_trigger"
                case colorOpacity = "color_opacity"
                case previousChangeColor = "previous_change_color"
            }
        }

        struct SurveySettings: Codable {
            var identifier: String?
            var resurveyOption: Bool?
            var retakeSurvey: RetakeSurvey?
            var showWatermark: Bool?
            var closedAsFinished: Bool? = false
            var sdkTheme: SDKTheme?
            var overrideGlobalThrottling: Bool?
            var triggerFilters: [TriggerFilter]?

            enum CodingKeys: String, CodingKey {
                case identifier = "_id"
                case resurveyOption = "resurvey_option"
                case retakeSurvey = "retake_survey"
                case showWatermark = "show_watermark"
                case closedAsFinished = "closed_as_finished"
                case sdkTheme = "sdk_theme"
                case overrideGlobalThrottling = "override_global_throttling"
                case triggerFilters = "trigger_filters"
            }

            struct RetakeSurvey: Codable {
                var identifier: String?
                var retakeInputValue: Int?
                var retakeSelectValue: String?

                enum CodingKeys: String, CodingKey {
                    case identifier = "_id"
                    case retakeInputValue = "retake_input_value"
                    case retakeSelectValue = "retake_select_value"
                }
            }

            struct SDKTheme: Codable {
                var backgroundColor: String?
                var removeWatermark: Bool?
                var darkOverlay: Bool?
                var closeButton: Bool?
                var progressBar: Bool?
                var widgetPosition: WidgetPosition?
                var textColor: String?

                enum CodingKeys: String, CodingKey {
                    case backgroundColor = "background_color"
                    case removeWatermark = "remove_watermark"
                    case darkOverlay = "dark_overlay"
                    case closeButton = "close_button"
                    case progressBar = "progress_bar"
                    case widgetPosition = "widget_position"
                    case textColor = "text_color"
                }
            }

            struct TriggerFilter: Codable {
                var type: String
                var timingOption: TimingOption
                var identifier: String
                var field: String
                var propertyFilters: PropertyFilters?

                enum CodingKeys: String, CodingKey {
                    case type
                    case timingOption
                    case identifier = "_id"
                    case field
                    case propertyFilters = "property_filters"
                }
            }

            struct TimingOption: Codable {
                // show_immediately, show_after
                var type: String?
                // seconds
                var value: Int?
            }

            struct PropertyFilters: Codable {
                var operation: String
                var filters: [Filter]?

                enum CodingKeys: String, CodingKey {
                    case operation = "operator"
                    case filters
                }
            }

            struct Filter: Codable {
                var type: String?
                var field: String?
                var dataType: String?
                var condition: String?
                var values: [Any]?

                enum CodingKeys: String, CodingKey {
                    case type
                    case field
                    case dataType = "data_type"
                    case condition
                    case values
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(type, forKey: .type)
                    try container.encode(field, forKey: .field)
                    try container.encode(dataType, forKey: .dataType)
                    try container.encode(condition, forKey: .condition)
                    if let stringArray = values as? [String] {
                        try container.encode(stringArray, forKey: .values)
                    } else if let boolArray = values as? [Bool] {
                        try container.encode(boolArray, forKey: .values)
                    } else if let numberArray = values as? [Double] {
                        try container.encode(numberArray, forKey: .values)
                    } else {
                        throw EncodingError.invalidValue(
                            values as Any,
                            EncodingError.Context(codingPath: [CodingKeys.values],
                                                  debugDescription: "Invalid data type in arrayKey"
                                                 )
                        )
                    }
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    type = try? container.decodeIfPresent(String.self, forKey: .type)
                    field = try? container.decodeIfPresent(String.self, forKey: .field)
                    dataType = try? container.decodeIfPresent(String.self, forKey: .dataType)
                    condition = try? container.decodeIfPresent(String.self, forKey: .condition)
                    if let stringArray = try? container.decode([String].self, forKey: .values) {
                        values = stringArray
                    } else if let boolArray = try? container.decode([Bool].self, forKey: .values) {
                        values = boolArray
                    } else if let numberArray = try? container.decode([Double].self, forKey: .values) {
                        values = numberArray
                    } else {
                        throw DecodingError.dataCorruptedError(
                            forKey: .values,
                            in: container,
                            debugDescription: "Invalid data type in arrayKey"
                        )
                    }
                }
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

struct FetchFlow: Codable {
    var success: Int
    var message: String?
    var result: SurveyListResponse.Survey?
}
