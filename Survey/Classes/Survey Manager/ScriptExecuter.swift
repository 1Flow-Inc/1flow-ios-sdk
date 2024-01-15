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

import WebKit
import JavaScriptCore

typealias ValidatorCompletion = (_ survey: SurveyListResponse.Survey?) -> Void
typealias AnnouncementValidatorCompletion = (_ announcement: [String: Any]?) -> Void

class SurveyScriptValidator {
    var surveyList: [[String: Any]]?
    var announcementList: [[String: Any]]?

    var validatorCompletion: ValidatorCompletion?
    var announcementValidatorCompletion: AnnouncementValidatorCompletion?

    static let shared = SurveyScriptValidator()
    var scriptManager: ScriptManageable?
    var managedValue: JSManagedValue?

    func setup(with surveys: [SurveyListResponse.Survey]) {
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(surveys)
            let jsonObj = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]]
            self.surveyList = jsonObj
        } catch {
        }
        if scriptManager == nil {
            scriptManager = ScriptManager()
        }
    }

    func setupForAnnouncement(with announcements: [Announcement]) {
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(announcements)
            let jsonObj = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]]
            self.announcementList = jsonObj
        } catch {
        }
        if scriptManager == nil {
            scriptManager = ScriptManager()
        }
    }

    lazy var context: JSContext? = {
        let context = JSContext()
        guard let script = scriptManager?.validationScript() else {
            return nil
        }
        _ = context?.evaluateScript(script)
        return context
    }()

    func refreshContext() {
        self.context = nil
        let context = JSContext()
        guard let script = scriptManager?.validationScript() else {
            return
        }
        _ = context?.evaluateScript(script)
        self.context = context
    }

    let swiftHandler: @convention(block) (JSValue?) -> Void = {(result) in

        guard let dictionary = result?.toDictionary() else {
            SurveyScriptValidator.shared.validatorCompletion?(nil)
            return
        }
        do {
            let json = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
            let decoder = JSONDecoder()
            let survey = try decoder.decode(SurveyListResponse.Survey.self, from: json)
            SurveyScriptValidator.shared.validatorCompletion?(survey)
        } catch {
            OneFlowLog.writeLog(error.localizedDescription, .error)
        }
    }

    let announcementSwiftHandler: @convention(block) (JSValue?) -> Void = {(result) in

        guard let dictionary = result?.toDictionary() as? [String: Any] else {
            SurveyScriptValidator.shared.announcementValidatorCompletion?(nil)
            return
        }
        SurveyScriptValidator.shared.announcementValidatorCompletion?(dictionary)
    }

    func validateSurvey(event: [String: Any], completion: @escaping ValidatorCompletion) {
        self.validatorCompletion = completion
        let swiftBlock = unsafeBitCast(swiftHandler, to: AnyObject.self)
        guard let context = context else {
            completion(nil)
            return
        }
        context.setObject(swiftBlock, forKeyedSubscript: "oneFlowCallBack" as (NSCopying & NSObjectProtocol)?)
        guard let surveyList = surveyList else {
            completion(nil)
            return
        }
        _ = context.objectForKeyedSubscript("oneFlowFilterSurvey").call(withArguments: [surveyList, event])
    }

    func validateAnnouncement(event: [String: Any], completion: @escaping AnnouncementValidatorCompletion) {
        self.announcementValidatorCompletion = completion
        let swiftBlock = unsafeBitCast(announcementSwiftHandler, to: AnyObject.self)
        guard let context = context else {
            completion(nil)
            return
        }
        context.setObject(swiftBlock, forKeyedSubscript: "oneFlowAnnouncementCallBack" as (NSCopying & NSObjectProtocol)?)
        guard let announcementList = announcementList else {
            completion(nil)
            return
        }
        let params = [announcementList, event, nil, false] as [Any?]
        _ = context.objectForKeyedSubscript("oneflowAnnouncementFilter").call(withArguments: params as [Any])
    }
}
