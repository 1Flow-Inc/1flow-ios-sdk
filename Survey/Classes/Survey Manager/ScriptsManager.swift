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
import UIKit

class ScriptManager: ScriptManageable {

    var apiController: APIProtocol = OFAPIController.shared

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationMovedToBackground),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func validationScript() -> String? {
        guard let
                commonJSPath = self.getScriptURL() else {
            OneFlowLog.writeLog("Unable to read resource files.", .warnings)
            return nil
        }
        do {
            let scriptString = try String(contentsOf: commonJSPath, encoding: .utf8)
            return scriptString
        } catch let error {
            OneFlowLog.writeLog("Error while processing script file: \(error)", .error)
            return nil
        }
    }

    var validatorScriptName: String {
        "validator-dev.js"
    }

    func getScriptURL() -> URL? {
        let fileManager = FileManager.default
        let fileName = self.validatorScriptName

        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let fileURL = documentDirectory.appendingPathComponent(fileName)

        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL
        } else {
            guard let bundlePath = OneFlowBundle.bundleForObject(self).path(forResource: fileName, ofType: nil) else {
                return nil
            }
            do {
                try fileManager.copyItem(atPath: bundlePath, toPath: fileURL.path)
                return fileURL
            } catch {
                OneFlowLog.writeLog("Error copying file: \(error.localizedDescription)", .error)
                return nil
            }
        }
    }

    @objc func applicationMovedToBackground() {
        if let lastUpdateTime = UserDefaults.standard.value(forKey: "OFScriptUpdateTime") as? Int {
            if (Int(Date().timeIntervalSince1970) - lastUpdateTime) > 86400 {
                updateScriptFromRemote()
            }
        } else {
            updateScriptFromRemote()
        }
    }

    func updateScriptFromRemote() {
        apiController.fetchUpdatedValidationScript { _, error, data in
            guard let data = data else {
                return
            }
            let fileManager = FileManager.default
            let fileName = self.validatorScriptName

            guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }

            let fileURL = documentDirectory.appendingPathComponent(fileName)

            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                } catch {
                    OneFlowLog.writeLog("Error while deleting file: \(error.localizedDescription)", .error)
                }
            }

            try? data.write(to: fileURL)
            UserDefaults.standard.setValue(Date().timeIntervalSince1970, forKey: "OFScriptUpdateTime")
            SurveyScriptValidator.shared.refreshContext()
        }
    }
}
