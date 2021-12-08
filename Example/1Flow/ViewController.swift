//
//  ViewController.swift
//  1Flow
//
//  Created by rohantryskybox on 08/04/2021.
//  Copyright (c) 2021 rohantryskybox. All rights reserved.
//

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
        OneFlow.recordEventName("start_all_survey_types", parameters: nil)
    }
    
    @IBAction func onRecordEvent_withParams(_ sender: Any) {
        OneFlow.recordEventName("button_clicked", parameters: ["title": "Submit", "number": 200, "purchase": "weekly"])
    }
    
    @IBAction func onLogUser(_ sender: Any) {
        let params = ["firstName": "rohan", "lastName": "moradiya", "number": 987654] as [String : Any]
        OneFlow.logUser("iOS_user_2", userDetails: params)
    }

}

