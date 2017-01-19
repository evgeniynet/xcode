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
    
    struct Record : JSONJoy {
        var id: Int
        var name: String
        var org: String
        //init() {
        //}
        
        init(_ decoder: JSONDecoder) throws  {
            id = try decoder["id"].get()
            name = try decoder["name"].get()//.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            org = ""
        }
        init(_ array: AnyObject) {
            id = 1
            name = ""
            org = ""
            if let userDict = array as? NSDictionary {
                id = (userDict["id"] as? Int)!
                name = (userDict["name"] as? String)!
                org = (userDict["org"] as? String)!
            }
        }
    }
    
    struct Records : JSONJoy {
        var records: NSMutableArray = []
        init() {
        }
        init(_ decoder: JSONDecoder) {
            //we check if the array is valid then alloc our array and loop through it, creating the new address objects.
            records = []
            /*if let recrds = decoder.array {
                records = []
                if recrds.count < 1 {
                    records.add(["id" : 0, "name" : "Default", "org" : Properties.org])
                }
                for rDecoder in recrds {
                    let rec = Record(rDecoder)
                    records.add([ "id" : rec.id, "name" : rec.name, "org" : Properties.org])
                }
            }
        }*/
    }
    
    var defaults : UserDefaults = UserDefaults(suiteName: "group.io.sherpadesk.mobile")!
    
    struct Properties {
        static var org = ""
    }
    
    var AddTimeData = ["org" : "",
        "account": "-1",
        "project": "0",
        "tasktype": "0",
        "isproject": "true",
        "isaccount": "true"
    ]
    
    var tasktypes: NSMutableArray = []
    
    mutating func getOrg(){
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
        if !Properties.org.isEmpty{
            if let tasktps:NSMutableArray = defaults.object(forKey: "tasktypes") as? NSMutableArray
            {
                /*
                if tasktps.count>0 {
                    if let org = tasktps[0]["org"] as? String
                    {
                        //print("org\(org)prop\(Properties.org)")
                        if (org == Properties.org){
                            self.tasktypes = tasktps
                            //print("set\(self.tickets.count)")
                            return
                        }
                    }
                }*/
 
            }
            //showMessage("No recent tickets yet ...")
        }
        else
        {//showMessage("Login to SherpaDesk app first")
//self.pushController(withName: "Main1", context: nil)
        }
        self.tasktypes = []
        defaults.set([], forKey: "tasktypes")
        //print("unset\(self.tickets.count)")
        
    }
    
    func updateWidget()
    {
        if !Properties.org.isEmpty
        {
            loadTableData()
            
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
                    /*let resp = Records(JSONDecoder(response.data))
                        self.tasktypes = resp.records
                        self.loadTableData()
                    if resp.records.count < 2 {
                        self.AddTimeData["tasktype"] = String(Record(resp.records[0]).id)
                        self.pushController(withName: "AddTime", context: self.AddTimeData)
                    }
 */
                    
                }
            } catch let error {
                print("got an error creating the request: \(error)")
            }
        }
    }
    
    func loadTableData() {
        /*
        timeTable.setNumberOfRows(tasktypes.count, withRowType: "TypeTableRowController")
        for (index, project) in tasktypes.enumerated() {
            //print(blogName)
            let row = timeTable.rowController(at: index) as! TypeTableRowController
            let rec = Record(project)
            row.recordLabel.setText(rec.name)
        }
 */
    }
    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String,
        in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        /*
            let sequeId = "ToAddTime"
            let tasktps  = tasktypes as NSMutableArray
            if segueIdentifier == sequeId {
                let rec = Record(tasktps[rowIndex])
                AddTimeData["tasktype"] = String(rec.id)
                return AddTimeData
            }
          */
            return nil
    }
    
    override init() {
        super.init()

        //getOrg()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        /*let dict = context as? [String : String]
        if dict != nil {
            AddTimeData = dict!
            print(AddTimeData["project"]!)
        }
        updateWidget()*/
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
