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

class SelectTypeInterfaceController: WKInterfaceController, WCSessionDelegate {
    
        var session : WCSession?
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        NSLog("%@", "activationDidCompleteWith activationState:\(activationState) error:\(error)")
    }
    
    @IBOutlet weak var timeTable: WKInterfaceTable!
    
    struct Records : JSONJoy {
        var records: Array<NSDictionary> = []
        init() {
        }
        init(_ decoder: JSONDecoder) throws {
            records = []
            let arr: Array<Record> = try decoder.get()
            records = []
            for val in arr {
                let dictionary: NSDictionary = ["id" : val.id, "name" : val.name, "org" : Properties.org]
                records.append(dictionary)
            }
        }
    }
    
    var defaults : UserDefaults = UserDefaults(suiteName: "group.io.sherpadesk.mobile")!
    
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
    
    
    var tasktypes: Array<Record1> = []
    
    var acc : Record = Record()
    
    func getOrg(){
        defaults.synchronize()
        if let org:String = defaults.object(forKey: "org") as? String
        {
            Properties.org = org
        }
        else
        {
            Properties.org = ""
        }
        //print(Properties.org)
        if Properties.org.isEmpty{
            self.pushController(withName: "Main1", context: nil)
        }
        self.tasktypes = acc.task_types
    }
    
    func updateWidget()
    {
        if !Properties.org.isEmpty
        {            
            do {
                let command = "task_types"
                let params = ["account": Properties.AddTimeData["account_id"]!]
                let urlPath: String = "http://" + Properties.org +
                    "@api.sherpadesk.com/" + command
                
                let opt = try HTTP.GET(urlPath, parameters: params, headers: ["Accept": "application/json"])
                opt.start { response in
                    if let err = response.error {
                        print("error: \(err.localizedDescription)")
                        return //also notify app of failure as needed
                    }
                    do {
                        self.tasktypes = try JSONDecoder(response.data).get()
                        if self.tasktypes.count == 0 {
                            self.tasktypes = [Record1()]
                        }
                        if self.tasktypes.count == 1 {
                            self.loadTableData()
                            self.test(self.tasktypes[0])
                            return
                        }
                        self.setRecent()
                        self.loadTableData()
                    }
                    catch {
                        print("unable to parse the JSON")
                    }
                }
            } catch let error {
                print("got an error creating the request: \(error)")
            }
        }
    }
    
    func setRecent(){
        if self.tasktypes.count > 1 && Properties.AddTimeData["tasktype"] != "" && self.tasktypes[0].id != Int(Properties.AddTimeData["tasktype_id"]!) {
            for (index, val) in self.tasktypes.enumerated() {
                if Int(Properties.AddTimeData["tasktype_id"]!) == val.id  {
                    self.tasktypes.insert(self.tasktypes.remove(at: index), at: 0);
                }
            }
        }
    }
    
    func test(_ rec: Record1) -> Any?
    {
        Properties.AddTimeData["tasktype_id"] = String(rec.id)
        Properties.AddTimeData["tasktype"] = rec.name
        if (tasktypes.count == 1)
        {
            self.pushController(withName: "AddTime", context: pass(Properties.AddTimeData, Record()))
                return nil
        }
        return pass(Properties.AddTimeData, self.acc)
    }
    
    func loadTableData() {
        timeTable.setNumberOfRows(tasktypes.count, withRowType: "TypeTableRowController")
        for (index, project) in tasktypes.enumerated() {
            //print(blogName)
            let row = timeTable.rowController(at: index) as! TypeTableRowController
            row.recordLabel.setText((Properties.AddTimeData["tasktype"] != "" && index == 0 ? "✅ " : "") + (project.name.isEmpty ? "Default" : project.name))
        }
    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String,
        in table: WKInterfaceTable, rowIndex: Int) -> Any? {
            let sequeId = "ToAddTime"
        let rec = tasktypes[rowIndex]
        if segueIdentifier == sequeId {
            return test(rec)
        }
        
        return nil
    }
    
    override init() {
        super.init()

        //getOrg()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let dict = context as? pass
        if dict != nil {
            Properties.AddTimeData = dict!.data
            self.acc = dict!.acc
            print(Properties.AddTimeData)
            //print(self.acc[0].name)
        }
        getOrg()
        if self.tasktypes.count > 0 {
            if (self.tasktypes.count == 1) {
                self.loadTableData()
                self.test(self.tasktypes[0])
            }
            else{
                setRecent()
                loadTableData()
            }
        }
        else
        {
            updateWidget()
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        session = WCSession.default()
        session?.delegate = self
        session?.activate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
}
