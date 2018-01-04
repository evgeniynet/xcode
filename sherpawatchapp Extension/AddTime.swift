//
//  AddTime.swift
//  Sherpadesk
//
//  Created by Евгений on 18.08.15.
//
//

import WatchKit
import Foundation
import WatchConnectivity

class AddTimeInterfaceController: WKInterfaceController, WCSessionDelegate {
    
    var session : WCSession?
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        NSLog("%@", "activationDidCompleteWith activationState:\(activationState) error:\(error)")
    }
    
    @IBOutlet weak var label: WKInterfaceButton!
    
    @IBOutlet weak var slider: WKInterfaceSlider!
    
    @IBOutlet var picker: WKInterfacePicker!
    
    var defaults : UserDefaults = UserDefaults(suiteName: "group.io.sherpadesk.mobile")!
    
    
    var  sliderValue:Float = 0.25
    var  pickerIndex:Int = 0
    
    struct Properties {
        static var org = ""
        static var AddTimeData: Dictionary<String, String> = ["org" : "",
                                                       "account": "",
                                                       "account_id": "-1",
                                                       "project": "",
                                                       "project_id": "0",
                                                       "tasktype": "",
                                                       "tasktype_id": "0",
                                                       "isproject": "true",
                                                       "isaccount": "true"
        ]
    }

    func updateWidget()
    {
        if !Properties.org.isEmpty
        {
            do {
                let command = "time"
                let params = [
                    "account_id": Properties.AddTimeData["account_id"]!,
                    "project_id" : Properties.AddTimeData["project_id"]!,
                    "tech_id" : "0",
                    "is_project_log": "true",
                    "ticket_key": "0",
                    "note_text": "added by iWatch",
                    "task_type_id": Properties.AddTimeData["tasktype_id"]!,
                    "hours": String(format: "%2.2f", sliderValue)
                ]
                print(params)
                let urlPath: String = "https://" + Properties.org +
                    "@api.sherpadesk.com/" + command
                
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

    
    @IBAction func sliderDidChange(_ value: Float)
    {
        if value > sliderValue
        {
            pickerIndex = pickerIndex + 1
        }
        else
        {
            pickerIndex = pickerIndex - 1
        }
        if (pickerIndex < 0){
            pickerIndex = 0}
        if (pickerIndex > 40){
            pickerIndex = 40}
        sliderValue = value
        label.setTitle(String(format: "%2.2f", sliderValue))
        picker.setSelectedItemIndex(pickerIndex)
        picker.focus()
    }
    
    @IBAction func popButtonPressed() {
        //self.popToRootController()
        updateWidget()
        self.pushController(withName: "Main1", context: nil)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let dict = context as? pass
        if dict != nil {
            Properties.AddTimeData = dict!.data
            Properties.org = Properties.AddTimeData["org"]!
            //print(Properties.AddTimeData)
            self.defaults.set(Properties.AddTimeData, forKey: "recent")
        }
    }
    
    override init() {
        super.init()
        /*
        let z = [Int](1...40)
        
        var test = z.map({
            (number: Int) -> Float in
            let result =  Float(number) * Float(0.25)
            return result
        })
        
        print(test)
*/
    }
    
    @IBAction func pickerSelectedItemChanged(_ value: Int) {
        pickerIndex = value
        sliderValue = Float(value+1) * Float(0.25)
        slider.setValue(sliderValue)
        label.setTitle(String(format: "%2.2f", sliderValue))
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        session = WCSession.default()
        session?.delegate = self
        session?.activate()
        
        slider.setValue(0.25)
        let z = [Int](1...40)
        
        let pickerItems: [WKPickerItem] = z.map {
            let pickerItem = WKPickerItem()
            pickerItem.title = String($0)
            pickerItem.caption = String($0)
            return pickerItem
        }
        self.pickerIndex = 0
        picker.setItems(pickerItems)
        picker.focus()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
}
