//
//  ScriptsManager.swift
//  1Flow
//
//  Created by Rohan Moradiya on 06/06/23.
//

import Foundation

class ScriptManager: ScriptManageable {

    var apiController: APIProtocol = OFAPIController()
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func validationScript() -> String? {
        guard let
                commonJSPath = self.getScriptURL() else {
                print("Unable to read resource files.")
                return nil
        }
        do {
            let scriptString = try String(contentsOf: commonJSPath, encoding: .utf8)
            return scriptString
        } catch (let error) {
            print("Error while processing script file: \(error)")
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
                print("Error copying file: \(error.localizedDescription)")
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
        apiController.fetchUpdatedValidationScript { isSuccess, error, data in
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
                    print("Error while deleting file:", error)
                }
            }

            try? data.write(to: fileURL)
            UserDefaults.standard.setValue(Date().timeIntervalSince1970, forKey: "OFScriptUpdateTime")
        }
        
    }
}
