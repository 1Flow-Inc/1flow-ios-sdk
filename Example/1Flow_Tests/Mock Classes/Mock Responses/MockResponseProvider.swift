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

    static func getDataForSurveyResponse() -> Data? {
        guard let bundle = Bundle(identifier: "-Flow.-Flow-Tests") else {
            return nil
        }
        if let fileURL = bundle.url(forResource: "GetSurveyResponses", withExtension: "json") {
            do {
                let data = try Data(contentsOf: fileURL)
                return data
            } catch {
                return nil
            }
        }
        return nil
    }

    static func getDataForSavedSurvey() -> Data? {
        guard let bundle = Bundle(identifier: "-Flow.-Flow-Tests") else {
            return nil
        }
        if let fileURL = bundle.url(forResource: "SavedSurveyResponses", withExtension: "json") {
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
