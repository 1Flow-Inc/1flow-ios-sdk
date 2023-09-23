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

extension OFRatingViewController: OFRatingViewDelegate {

    func oneToTenViewChangeSelection(_ selectedIndex: Int?) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            if let index = selectedIndex, let screen = self.allScreens?[self.currentScreenIndex] {
                OneFlow.shared.eventManager.recordInternalEvent(
                    name: InternalEvent.questionAnswered,
                    parameters: [
                        InternalKey.questionId: screen.identifier,
                        InternalKey.stepId: screen.identifier,
                        InternalKey.flowId: self.surveyID as Any,
                        InternalKey.type: screen.input?.inputType as Any,
                        InternalKey.answer: "\(index)",
                        InternalKey.questionTitle: screen.title as Any,
                        InternalKey.questionDescription: screen.message as Any,
                        InternalKey.surveyName: self.surveyName as Any
                    ]
                )
                let answer = SurveySubmitRequest.Answer(
                    screenID: screen.identifier,
                    answerValue: "\(index)",
                    answerIndex: nil
                )
                self.surveyResult.append(answer)
                self.presentNextScreen(answer.answerValue)
            }
        }
    }

    func mcqViewChangeSelection(_ selectedOptionID: String, otherTextAnswer: String?) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            if  let screen = self.allScreens?[self.currentScreenIndex] {
                if let choices = screen.input?.choices {
                    let rawAnswer: String
                    if let otherTextAnswer = otherTextAnswer {
                        rawAnswer = otherTextAnswer
                    } else if let title = choices.first(where: { $0.identifier == selectedOptionID })?.title {
                        rawAnswer = title
                    } else {
                        rawAnswer = ""
                    }
                    OneFlow.shared.eventManager.recordInternalEvent(
                        name: InternalEvent.questionAnswered,
                        parameters: [
                            InternalKey.questionId: screen.identifier,
                            InternalKey.stepId: screen.identifier,
                            InternalKey.flowId: self.surveyID as Any,
                            InternalKey.type: screen.input?.inputType as Any,
                            InternalKey.answer: rawAnswer,
                            InternalKey.questionTitle: screen.title as Any,
                            InternalKey.questionDescription: screen.message as Any,
                            InternalKey.surveyName: self.surveyName as Any
                        ]
                    )
                }
                let answer = SurveySubmitRequest.Answer(
                    screenID: screen.identifier,
                    answerValue: otherTextAnswer,
                    answerIndex: selectedOptionID
                )
                self.surveyResult.append(answer)
                self.presentNextScreen(answer.answerIndex)
            }
        }
    }

    func checkBoxViewDidFinishPicking(_ selectedOptions: [String], otherTextAnswer: String?) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            if let screen = self.allScreens?[self.currentScreenIndex] {
                let finalString = selectedOptions.joined(separator: ",")
                if let choices = screen.input?.choices {
                    var rawAnswers = choices.filter { choice in
                        if screen.input?.otherOptionID == choice.identifier {
                            return false
                        } else {
                            return selectedOptions.contains(choice.identifier ?? "")
                        }
                    }.compactMap({$0.title}).joined(separator: ",")
                    if let otherTextAnswer = otherTextAnswer {
                        rawAnswers += "," + otherTextAnswer
                    }
                    OneFlow.shared.eventManager.recordInternalEvent(
                        name: InternalEvent.questionAnswered,
                        parameters: [
                            InternalKey.questionId: screen.identifier,
                            InternalKey.stepId: screen.identifier,
                            InternalKey.flowId: self.surveyID as Any,
                            InternalKey.type: screen.input?.inputType as Any,
                            InternalKey.answer: rawAnswers,
                            InternalKey.questionTitle: screen.title as Any,
                            InternalKey.questionDescription: screen.message as Any,
                            InternalKey.surveyName: self.surveyName as Any
                        ]
                    )
                }
                let answer = SurveySubmitRequest.Answer(
                    screenID: screen.identifier,
                    answerValue: otherTextAnswer,
                    answerIndex: finalString
                )
                self.surveyResult.append(answer)
                self.presentNextScreen(answer.answerIndex)
            }
        }
    }

    func followupViewEnterTextWith(_ text: String?) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            if let inputString = text, let screen = self.allScreens?[self.currentScreenIndex] {
                let finalString = inputString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                OneFlow.shared.eventManager.recordInternalEvent(
                    name: InternalEvent.questionAnswered,
                    parameters: [
                        InternalKey.questionId: screen.identifier,
                        InternalKey.stepId: screen.identifier,
                        InternalKey.flowId: self.surveyID as Any,
                        InternalKey.type: screen.input?.inputType as Any,
                        InternalKey.answer: inputString,
                        InternalKey.questionTitle: screen.title as Any,
                        InternalKey.questionDescription: screen.message as Any,
                        InternalKey.surveyName: self.surveyName as Any
                    ]
                )
                if finalString.count > 0 {
                    let answer = SurveySubmitRequest.Answer(
                        screenID: screen.identifier,
                        answerValue: inputString,
                        answerIndex: nil
                    )
                    self.surveyResult.append(answer)
                } else {
                    if let screens = self.allScreens, screens.count == 1 {
                        if let completionEmptyText = self.recordEmptyTextCompletionBlock {
                            completionEmptyText()
                        }
                    } else if
                        let screens = self.allScreens,
                        screens.count <= 2,
                        let lastScreen = screens.last,
                        lastScreen.input?.inputType == "thank_you" {
                        if let completionEmptyText = self.recordEmptyTextCompletionBlock {
                            completionEmptyText()
                        }
                    }
                }
                self.view.endEditing(true)
                self.presentNextScreen(inputString)
            }
        }
    }

    func shortAnswerViewEnterTextWith(_ text: String?) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            if let inputString = text, let screen = self.allScreens?[self.currentScreenIndex] {
                let finalString = inputString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                OneFlow.shared.eventManager.recordInternalEvent(
                    name: InternalEvent.questionAnswered,
                    parameters: [
                        InternalKey.questionId: screen.identifier,
                        InternalKey.stepId: screen.identifier,
                        InternalKey.flowId: self.surveyID as Any,
                        InternalKey.type: screen.input?.inputType as Any,
                        InternalKey.answer: inputString,
                        InternalKey.questionTitle: screen.title as Any,
                        InternalKey.questionDescription: screen.message as Any,
                        InternalKey.surveyName: self.surveyName as Any
                    ]
                )
                if finalString.count > 0 {
                    let answer = SurveySubmitRequest.Answer(
                        screenID: screen.identifier,
                        answerValue: inputString,
                        answerIndex: nil
                    )
                    self.surveyResult.append(answer)
                } else {
                    if let screens = self.allScreens, screens.count == 1 {
                        if let completionEmptyText = self.recordEmptyTextCompletionBlock {
                            completionEmptyText()
                        }
                    } else if
                        let screens = self.allScreens,
                        screens.count <= 2,
                        let lastScreen = screens.last,
                        lastScreen.input?.inputType == "thank_you" {
                        if let completionEmptyText = self.recordEmptyTextCompletionBlock {
                            completionEmptyText()
                        }
                    }
                }
                self.view.endEditing(true)
                self.presentNextScreen(inputString)
            }
        }
    }

    func starsViewChangeSelection(_ selectedIndex: Int?) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            if let index = selectedIndex, let screen = self.allScreens?[self.currentScreenIndex] {
                OneFlow.shared.eventManager.recordInternalEvent(
                    name: InternalEvent.questionAnswered,
                    parameters: [
                        InternalKey.questionId: screen.identifier,
                        InternalKey.stepId: screen.identifier,
                        InternalKey.flowId: self.surveyID as Any,
                        InternalKey.type: screen.input?.inputType as Any,
                        InternalKey.answer: "\(index)",
                        InternalKey.questionTitle: screen.title as Any,
                        InternalKey.questionDescription: screen.message as Any,
                        InternalKey.surveyName: self.surveyName as Any
                    ]
                )
                let answer = SurveySubmitRequest.Answer(
                    screenID: screen.identifier,
                    answerValue: "\(index)",
                    answerIndex: nil
                )
                self.surveyResult.append(answer)
                self.presentNextScreen(answer.answerValue)
            }
        }
    }

    func onThankyouAnimationComplete() {
        let shouldFadeAway = (self.allScreens?[self.currentScreenIndex].rules?.dismissBehavior?.fadesAway) ?? true
        if !shouldFadeAway {
            OneFlowLog.writeLog("End Screen logic : should not fade away as per survey logic")
            return
        }
        let delay = (self.allScreens?[self.currentScreenIndex].rules?.dismissBehavior?.delayInSeconds) ?? 0
        OneFlowLog.writeLog("End Screen logic : delay added for \(delay) seconds")

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1 + CGFloat(delay)) {
            if self.isClosingAnimationRunning == true {
                OneFlowLog.writeLog("End Screen logic: already closed")
                return
            }
            self.checkandPerformEndScreenAction()
        }
    }

    func followupTextViewHeightDidChange() {
        self.setupTopBottomIfNeeded()
        self.scrollView.scrollRectToVisible(
            CGRect(x: scrollView.contentSize.width - 1, y: scrollView.contentSize.height - 1, width: 1, height: 1),
            animated: false
        )
    }

    func onWelcomeNextTapped() {
        if let screen = self.allScreens?[self.currentScreenIndex] {
            OneFlow.shared.eventManager.recordInternalEvent(
                name: InternalEvent.flowStepClicked,
                parameters: [InternalKey.stepId: screen.identifier, InternalKey.flowId: surveyID as Any]
            )
        }

        if allScreens?.count == 1 {
            isSurveyFullyAnswered = true
            OneFlowLog.writeLog("only welcome screen. turning completed true", .verbose)
        }
        self.presentNextScreen("")
    }
}
