//
//  AddTime.swift
//  Sherpadesk
//
//  Created by Евгений on 18.08.15.
//
//

import WatchKit
import Foundation
import SwiftHTTP


class AddTimeInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var label: WKInterfaceButton!
    
    @IBOutlet weak var slider: WKInterfaceSlider!
    
    var AddTimeData = ["org" : "",
        "account": "-1",
        "project": "0",
        "tasktype": "0",
        "isproject": "true",
        "isaccount": "true"
    ]
    
    struct Properties {
        static var org = ""
    }

    func updateWidget()
    {
        if !Properties.org.isEmpty
        {
            do {
                let command = "time"
                let params = [
                    "account_id": AddTimeData["account"]!,
                    "project_id" : AddTimeData["project"]!,
                    "tech_id" : "0",
                    "is_project_log": "true",
                    "ticket_key": "0",
                    "note_text": "added by iWatch",
                    "task_type_id": AddTimeData["tasktype"]!,
                    "hours": val,
                    "is_billable": "true"
                ]
                print(params)
                let urlPath: String = "http://" + Properties.org +
                    "@api.beta.sherpadesk.com/" + command
                
                let opt = try HTTP.POST(urlPath, parameters: params, headers: ["Accept": "application/json"])
                opt.start { response in
                    if let err = response.error {
                        print("error: \(err.localizedDescription)")
                        return //also notify app of failure as needed
                    }
                    print("opt finished: \(response.description)")
                }
            } catch let error {
                print("got an error creating the request: \(error)")
            }
        }
    }

    
    var val : String = ""
    
    @IBAction func sliderDidChange(value: Float)
    {
        val = String(format: "%2.2f", value)
        label.setTitle(val);
    }
    
    @IBAction func popButtonPressed() {
        //self.popToRootController()
        updateWidget()
        self.pushControllerWithName("Main1", context: nil)
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        let dict = context as? [String : String]
        if dict != nil {
            AddTimeData = dict!
            Properties.org = AddTimeData["org"]!
            
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
}