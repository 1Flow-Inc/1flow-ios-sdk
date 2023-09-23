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

class OneFlowDataLogic {
    func getNextAction(
        currentIndex: Int,
        allSurveys: [SurveyListResponse.Survey.Screen],
        previousAnswer: String?,
        completion: (String?, Int?, String?) -> Void
    ) {
        var actionType: String!
        var nextIndex: Int!
        var urlString: String!
        if let answer: String = previousAnswer {
            if allSurveys.count > currentIndex {
                let previousScreen = allSurveys[currentIndex]
                if let surveyRule = previousScreen.rules, let dataLogics = surveyRule.dataLogic {
                    for dataLogic in dataLogics {
                        let values: [String] = dataLogic.values?.components(separatedBy: ",") ?? []
                        if values.isEmpty {
                            continue
                        }
                        var isConditionSatisfied = false
                        if let condition: String = dataLogic.condition {
                            if condition == "is-any" {
                                isConditionSatisfied = true
                            } else if condition == "is" {
                                isConditionSatisfied = self.checkForIsConditon(answer: answer, values: values)
                            } else if condition == "is-not" {
                                isConditionSatisfied = self.checkForIsNotOfConditon(answer: answer, values: values)
                            } else if condition == "is-one-of" {
                                isConditionSatisfied = self.checkForIsOneOfConditon(answer: answer, values: values)
                            } else if condition == "is-none-of" {
                                isConditionSatisfied = self.checkForIsNoneOfConditon(answer: answer, values: values)
                            }
                        }
                        if isConditionSatisfied {
                            if let type: String = dataLogic.type {
                                actionType = type
                                if type == "skipTo" {
                                    if let screenID: String = dataLogic.action {
                                        nextIndex = self.getNextQuestionIndex(
                                            screenID: screenID,
                                            allSurveys: allSurveys,
                                            currentIndex: currentIndex
                                        )
                                    }
                                } else if type == "open-url" {
                                    if let actionUrl: String = dataLogic.action {
                                        urlString = actionUrl
                                    }
                                }
                            }
                            break
                        }
                    }
                }
            }
        }
        completion(actionType, nextIndex, urlString)
    }

    private func checkForIsConditon(answer: String, values: [String]) -> Bool {
        let answerSet = Set(answer.components(separatedBy: ","))
        let valueSet = Set(values)
        let intersectionSet = valueSet.intersection(answerSet)
        if answerSet.count == valueSet.count && answerSet.count == intersectionSet.count {
            return true
        }
        return false
    }

    private func checkForIsNotOfConditon(answer: String, values: [String]) -> Bool {
        let answerSet = Set(answer.components(separatedBy: ","))
        let valueSet = Set(values)
        let intersectionSet = valueSet.intersection(answerSet)
        return intersectionSet.count == 0
    }

    private func checkForIsOneOfConditon(answer: String, values: [String]) -> Bool {
        let answerSet = Set(answer.components(separatedBy: ","))
        let valueSet = Set(values)
        let intersectionSet = valueSet.intersection(answerSet)
        return intersectionSet.count > 0
    }

    private func checkForIsNoneOfConditon(answer: String, values: [String]) -> Bool {
        let answerSet = Set(answer.components(separatedBy: ","))
        let valueSet = Set(values)
        let intersectionSet = valueSet.intersection(answerSet)
        return intersectionSet.count == 0
    }

    private func getNextQuestionIndex(
        screenID: String,
        allSurveys: [SurveyListResponse.Survey.Screen],
        currentIndex: Int
    ) -> Int {
        var nextQuestionIndex = currentIndex + 1
        if screenID == "the-end" {
            nextQuestionIndex = allSurveys.count - 1
            // if last screen is not end-screen or thank_you then return next index. so it will close the survey
            if !(allSurveys[nextQuestionIndex].input?.inputType == "end-screen" ||
                 allSurveys[nextQuestionIndex].input?.inputType == "thank_you") {
                return allSurveys.count
            }
        } else {
            if let screenIndex = allSurveys.firstIndex(where: {$0.identifier == screenID}) {
                OneFlowLog.writeLog("Data Logic : Next Index is \(screenIndex)")
                if screenIndex > currentIndex && screenIndex < allSurveys.count {
                    nextQuestionIndex = screenIndex
                } else {
                    OneFlowLog.writeLog("Data Logic : index is either out of bound or survey question already shown")
                }
            }
        }
        return nextQuestionIndex
    }
}
