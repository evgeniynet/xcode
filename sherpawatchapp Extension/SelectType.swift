//
//  AddTime.swift
//  Sherpadesk
//
//  Created by Евгений on 18.08.15.
//
//

import WatchKit
import Foundation

class SelectTypeInterfaceController: WKInterfaceController {
    
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
    }
    
    var AddTimeData: Dictionary<String, String> = ["org" : "",
        "account": "-1",
        "project": "0",
        "tasktype": "0",
        "isproject": "true",
        "isaccount": "true"
    ]
    
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
                let params = ["account": AddTimeData["account"]!, "project" : AddTimeData["project"]!]
                print(params)
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
                        self.loadTableData()
                        if self.tasktypes.count == 1 {
                            self.test(self.tasktypes[0])
                        }
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
    
    func test(_ rec: Record1) -> Any?
    {
        self.AddTimeData["tasktype"] = String(rec.id)
        if (tasktypes.count == 1)
        {
            self.pushController(withName: "AddTime", context: pass(AddTimeData, Record()))
                return nil
        }
        return pass(AddTimeData, self.acc)
    }
    
    func loadTableData() {
        timeTable.setNumberOfRows(tasktypes.count, withRowType: "TypeTableRowController")
        for (index, project) in tasktypes.enumerated() {
            //print(blogName)
            let row = timeTable.rowController(at: index) as! TypeTableRowController
            row.recordLabel.setText(project.name)
        }
    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String,
        in table: WKInterfaceTable, rowIndex: Int) -> Any? {
            let sequeId = "ToAddTime"
        let rec = acc.task_types.count > 0 ? acc.task_types[rowIndex] : tasktypes[rowIndex]
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
            AddTimeData = dict!.data
            self.acc = dict!.acc
            print(AddTimeData)
            //print(self.acc[0].name)
        }
        getOrg()
        if self.tasktypes.count > 0 {
            if (self.tasktypes.count < 2) {
                self.test(self.acc.task_types[0])
            }
            else{
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
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
}
