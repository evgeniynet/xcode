//
//  AddTime.swift
//  Sherpadesk
//
//  Created by Евгений on 18.08.15.
//
//

import WatchKit
import Foundation

class SelectProjectInterfaceController: WKInterfaceController {
    
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
    
    var projects: Array<Record1> = []
    
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
        self.projects = self.acc.projects
        //print("unset\(self.tickets.count)")
    }
    
    func updateWidget()
    {
        if !Properties.org.isEmpty
        {
            do {
                let command = "projects?is_with_statistics=false"
                let params = ["account" : AddTimeData["account"]!]
                let urlPath: String = "http://" + Properties.org +
                    "@api.sherpadesk.com/" + command
                
                let opt = try HTTP.GET(urlPath, parameters: params, headers: ["Accept": "application/json"])
                opt.start { response in
                    if let err = response.error {
                        print("error: \(err.localizedDescription)")
                        return //also notify app of failure as needed
                    }
                    do {
                        self.projects = try JSONDecoder(response.data).get()
                        if self.projects.count == 0 {
                            self.projects = [Record1()]
                        }
                        self.loadTableData()
                        if self.projects.count == 1 {
                            self.test(self.projects[0])
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
        self.AddTimeData["project"] = String(rec.id)
        if (projects.count == 1)
        {
            if acc.task_types.count == 1 {
                self.AddTimeData["tasktype"] = String(acc.task_types.count < 2 ? acc.task_types[0].id : 0)
                self.pushController(withName: "AddTime", context: pass(AddTimeData, Record()))
                return nil
            }
            self.pushController(withName: "TypesList", context: pass(AddTimeData, self.acc))
            return nil
        }
        return pass(AddTimeData, self.acc)
    }
    
    func loadTableData() {
        timeTable.setNumberOfRows(projects.count, withRowType: "ProjectTableRowController")
        for (index, project) in projects.enumerated() {
            //print(blogName)
            let row = timeTable.rowController(at: index) as! ProjectTableRowController
            row.recordLabel.setText(project.name)
        }
    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String,
                                  in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        let sequeId = "ToTaskType"
         let rec = acc.projects.count > 0 ? acc.projects[rowIndex] : projects[rowIndex]
        if segueIdentifier == sequeId {
            return test(rec)
        }
        
        return nil
    }
    
    override init() {
        super.init()
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
        if self.projects.count > 0 {
            if (self.projects.count < 2) {
                self.test(self.acc.projects[0])
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
