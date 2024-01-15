//
//  AnnouncementsDetails.swift
//  1Flow
//
//  Created by Rohan Moradiya on 28/10/23.
//

import Foundation

struct AnnouncementTheme: Codable {
    var brandColor: String?
    var brandOpacity: String?
    var backgroundColor: String?
    var backgroundOpacity: String?
    var textColor: String?
    var textOpacity: String?
}

struct Announcement: Codable {
    var identifier: String
    var status: String
    var inbox: Inbox?
    var inApp: InApp?
    var seen: Bool = true
    
    struct Inbox: Codable {
        var ios: Bool = false
    }

    struct InApp: Codable {
        var isActive: Bool = true
        var ios: Bool = false
        var style: String?
        var timing: Timing?
        
        enum CodingKeys: String, CodingKey {
            case isActive = "is_active"
            case ios
            case style
            case timing
        }
        
        struct Timing: Codable {
            var condition: String?
            var rule: Rule?
            
            struct Rule: Codable {
                var filters: [Filters]?

                struct Filters: Codable {
                    var type: String?
                    var field: String?
                    var timingOption: TimingOption?
                    var property_filters: PropertyFilters?
                    
                    struct TimingOption: Codable {
                        var type: String?
                        var value: Int?
                    }

                    struct PropertyFilters: Codable {
                        var operation: String?
                        var filters: [Filter]?
                        
                        enum CodingKeys: String, CodingKey {
                            case operation = "operator"
                            case filters
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
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case identifier = "_id"
        case status
        case inbox
        case inApp = "in_app"
        case seen
    }
}

struct AnnouncementsInbox: Codable {
    var success: Int?
    var message: String?
    var result: Result?

    struct Result: Codable {
        var announcements: Announcements?
        var theme: AnnouncementTheme?
        
        struct Announcements: Codable {
            var inbox: [Announcement]?
            var inApp: [Announcement]?
        }
    }
}

struct AnnouncementsResponse: Codable {
    var success: Int?
    var message: String?
    var result: [AnnouncementsDetails]?
}

struct AnnouncementsDetails: Codable {
    var title: String
    var identifier: String
    var publishedAt: Int
    var category: AnnouncementCategory?
    var content: String?
    var action: Action?
    
    enum CodingKeys: String, CodingKey {
        case title
        case identifier = "id"
        case publishedAt
        case category
        case content
        case action
    }
}

struct Action: Codable {
    var link: String?
    var name: String
}

struct AnnouncementCategory: Codable {
    var identifier: String
    var name: String
    var color: String
    
    enum CodingKeys: String, CodingKey {
        case identifier = "_id"
        case name
        case color
    }
}
