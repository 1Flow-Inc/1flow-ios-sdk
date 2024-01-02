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

import UIKit
import _1Flow

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onRecordEvent_startSurvey(_ sender: Any) {
        OneFlow.recordEventName("modal", parameters: nil)
    }

    @IBAction func onRecordEvent_withParams(_ sender: Any) {
        OneFlow.recordEventName("Banner_Top", parameters: nil)
    }

    @IBAction func onLogUser(_ sender: Any) {
        OneFlow.recordEventName("Banner_Bottom", parameters: nil)
    }

    @IBAction func onButton1(_ sender: Any) {
//        OneFlow.recordEventName("button1", parameters: nil)
        OneFlow.showInbox()
    }

    @IBAction func onButton2(_ sender: Any) {
        OneFlow.recordEventName("slideout_top", parameters: nil)
    }

    @IBAction func onButton3(_ sender: Any) {
        OneFlow.recordEventName("slideout_bottom", parameters: nil)
//        OneFlow.useFont(fontFamily: "Zapfino")
    }
}
