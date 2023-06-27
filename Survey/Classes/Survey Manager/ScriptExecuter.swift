//
//  ScriptExecuter.swift
//  1Flow
//
//  Created by Rohan Moradiya on 26/05/23.
//

import WebKit
import JavaScriptCore

typealias ValidatorCompletion = (_ survey: SurveyListResponse.Survey?) -> Void

class SurveyScriptValidator {
    var webview: WKWebView?
    var surveyList: [[String: Any]]?
    var validatorCompletion: ValidatorCompletion?
    static let shared = SurveyScriptValidator()
    var scriptManager: ScriptManageable?

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

    let swiftHandler: @convention(block) ([String : Any]?) -> Void = {(result) in

        guard let result = result else {
            SurveyScriptValidator.shared.validatorCompletion?(nil)
            return
        }
        do {
            let json = try JSONSerialization.data(withJSONObject: result, options: .prettyPrinted)
            let decoder = JSONDecoder()
            let survey = try decoder.decode(SurveyListResponse.Survey.self, from: json)
            SurveyScriptValidator.shared.validatorCompletion?(survey)
            
        } catch {
            OneFlowLog.writeLog(error.localizedDescription, .error)
        }
    }

    func validateSurvey(event: [String: Any], completion:  @escaping ValidatorCompletion) {
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
}
