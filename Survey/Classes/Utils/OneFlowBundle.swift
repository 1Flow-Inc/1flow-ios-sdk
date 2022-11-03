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

class OneFlowBundle {
    class func bundleForObject(_ obj: AnyObject) -> Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return OneFlowBundle.resourceBundle
        #endif
    }
}

extension OneFlowBundle {
    static let resourceBundle: Bundle = {
        let myBundle = Bundle(for: OneFlowBundle.self)

        guard let resourceBundleURL = myBundle.url(
            forResource: "SurveySDK", withExtension: "bundle")
            else { fatalError("SurveySDK.bundle not found!") }

        guard let resourceBundle = Bundle(url: resourceBundleURL)
            else { fatalError("Cannot access SurveySDK.bundle!") }

        return resourceBundle
    }()
}
