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
                let params = ["account" : Properties.AddTimeData["account_id"]!]
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
                        if self.projects.count == 1 {
                            self.test(self.projects[0])
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
        if self.projects.count > 1 && Properties.AddTimeData["project"] != "" && self.projects[0].id != Int(Properties.AddTimeData["project_id"]!) {
            for (index, val) in self.projects.enumerated() {
                if Int(Properties.AddTimeData["project_id"]!) == val.id  {
                    self.projects.insert(self.projects.remove(at: index), at: 0);
                }
            }
        }
    }
    
    func test(_ rec: Record1) -> Any?
    {
        Properties.AddTimeData["project_id"] = String(rec.id)
        Properties.AddTimeData["project"] = rec.name
        //remove
        //self.defaults.set(Properties.AddTimeData, forKey: "recent")
        if (projects.count == 1)
        {
            if acc.task_types.count == 1 {
             Properties.AddTimeData["tasktype"] = acc.task_types.count == 1 ? acc.task_types[0].name : ""
                Properties.AddTimeData["tasktype_id"] = String(acc.task_types.count < 2 ? acc.task_types[0].id : 0)
                self.pushController(withName: "AddTime", context: pass(Properties.AddTimeData, Record()))
                return nil
            }
            self.pushController(withName: "TypesList", context: pass(Properties.AddTimeData, self.acc))
            return nil
        }
        return pass(Properties.AddTimeData, self.acc)
    }
    
    func loadTableData() {
        timeTable.setNumberOfRows(projects.count, withRowType: "ProjectTableRowController")
        for (index, project) in projects.enumerated() {
            //print(blogName)
            let row = timeTable.rowController(at: index) as! ProjectTableRowController
            row.recordLabel.setText((Properties.AddTimeData["project"] != "" && index == 0 ? "✅ " : "") + project.name)
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
            Properties.AddTimeData = dict!.data
            self.acc = dict!.acc
            print(Properties.AddTimeData)
            //print(self.acc[0].name)
        }
        getOrg()
        if self.projects.count > 0 {
            if (self.projects.count == 1) {
                self.test(self.acc.projects[0])
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
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
}
