//
//  SurveyValidationOperation.swift
//  1Flow
//
//  Created by Rohan Moradiya on 18/07/24.
//

import Foundation

class SurveyValidationOperation: Operation {
    private let event: EventStore
    private let timeout: TimeInterval
    private var taskCompleted = false
    private var taskStarted = false
    private var timer: Timer?
    private weak var manager: OFSurveyManager?
    
    init(event: EventStore, timeout: TimeInterval, manager: OFSurveyManager) {
        self.event = event
        self.timeout = timeout
        self.manager = manager
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(cancelOperation), name: .surveyStarted, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func cancelOperation() {
        if !self.taskCompleted {
            self.cancel()
        }
    }
    
    override func main() {
        guard !isCancelled else { return }
        
        var previousEvent = ["name": event.eventName] as [String: Any]
        if let param = event.parameters {
            previousEvent["parameters"] = param
        }
        
        self.timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if !self.taskCompleted {
                OneFlowLog.writeLog("Timeout: Task did not complete within the specified time.", .error)
                self.completeTask()
            }
        }
        
        SurveyScriptValidator.shared.validateSurvey(event: previousEvent) { [weak self] survey in
            guard let self = self, !self.isCancelled else {
                self?.completeTask()
                return
            }
            
            OneFlowLog.writeLog("Survey validator returns: \(String(describing: survey))", .info)
            
            if let survey = survey, self.manager?.validateTheSurvey(survey) == true {
                NotificationCenter.default.post(name: .surveyStarted, object: nil)  // Notify that a survey has started
                if let intervalType = survey.surveyTimeInterval?.type,
                   intervalType == "show_after",
                   let delay = survey.surveyTimeInterval?.value {
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay)) { [self] in
                        self.manager?.startSurvey(survey, eventName: self.event.eventName)
                        self.completeTask()
                    }
                } else {
                    manager?.startSurvey(survey, eventName: self.event.eventName)
                    self.completeTask()
                }
            } else {
                OneFlowLog.writeLog("Survey validation not passed. Looking for next survey", .info)
                self.completeTask()
            }
        }
    }
    
    private func completeTask() {
        self.taskCompleted = true
        self.timer?.invalidate()
        self.timer = nil
    }
    
    override var isFinished: Bool {
        return taskCompleted
    }
    
    override var isExecuting: Bool {
        return taskStarted && !taskCompleted
    }
    
    override func start() {
        if isCancelled {
            taskCompleted = true
            return
        }
        
        taskStarted = true
        main()
    }
}
