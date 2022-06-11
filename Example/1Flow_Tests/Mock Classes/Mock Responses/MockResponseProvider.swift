//
//  MockResponseProvider.swift
//  1Flow_Tests
//
//  Created by Rohan Moradiya on 02/06/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation

class MockResponseProvider {
    static func getDataForAddUserResponse() -> Data? {
        guard let bundle = Bundle(identifier: "-Flow.-Flow-Tests") else {
            return nil
        }
        if let fileURL = bundle.url(forResource: "AddUserResponse", withExtension: "json") {
            do {
                let data = try Data(contentsOf: fileURL)
                return data
            } catch {
                return nil
            }
        }
        return nil
    }
}
