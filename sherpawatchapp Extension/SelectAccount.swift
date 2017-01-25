//
//  AddTime.swift
//  Sherpadesk
//
//  Created by Евгений on 18.08.15.
//
//

import WatchKit
import Foundation

class SelectAccountInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var timeTable: WKInterfaceTable!
    
    struct Record : JSONJoy {
        var id: Int
        var name: String
        var org: String
        
        init(_ decoder: JSONDecoder) throws {
            id = try decoder["id"].get()
            name = try decoder["name"].get()
            name = name.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            org = ""
        }
        init(_ array: NSDictionary) {
            id = (array["id"] as? Int)!
            name = (array["name"] as? String)!
            org = (array["org"] as? String)!
        }
    }
    
    
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
    
    var AddTimeData = ["org" : "",
        "account": "-1",
        "project": "0",
        "tasktype": "0",
        "isproject": "true",
        "isaccount": "true"
    ]
    
    var accounts: Array<NSDictionary> = []
    
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
        if !Properties.org.isEmpty{
            if let accts:Array<NSDictionary> = defaults.object(forKey: "accounts") as? Array<NSDictionary>
            {
                if accts.count>0 {
                    if let org = accts[0]["org"] as? String
                    {
                        //print("org\(org)prop\(Properties.org)")
                        if (org == Properties.org){
                            self.accounts = accts
                            //print("set\(self.tickets.count)")
                            return
                        }
                    }
                }
            }
            //showMessage("No recent tickets yet ...")
        }
        else
        {//showMessage("Login to SherpaDesk app first")
             self.pushController(withName: "Main1", context: nil)
        }
        self.accounts = []
        defaults.set([], forKey: "accounts")
        //print("unset\(self.tickets.count)")
    }
    
    func updateWidget()
    {
        if !Properties.org.isEmpty
        {
            loadTableData()
            
            do {
                let command = "accounts" + "?is_with_statistics=false"
                let params = ["", ""]
                let urlPath: String = "http://" + Properties.org +
                    "@api.sherpadesk.com/" + command
                
                let opt = try HTTP.GET(urlPath, parameters: params, headers: ["Accept": "application/json"])
                opt.start { response in
                    if let err = response.error {
                        print("error: \(err.localizedDescription)")
                        return //also notify app of failure as needed
                    }
                    do {
                    let resp = try Records(JSONDecoder(response.data))
                    if resp.records.count > 0 {
                        let oldcount =  self.accounts.count
                        var oldorg = false;
                        if oldcount > 0 {
                            let org = self.accounts[0]
                            if let torg = org.object(forKey: "org") as? String
                            {
                                if (torg != Properties.org){
                                    oldorg = true
                                }
                            }
                        }
                        self.accounts = resp.records
                        //print("sting during post: \(self.tickets.count)")
                        self.defaults.set(self.accounts, forKey: "accounts")
                        if oldcount !=  self.accounts.count || oldorg
                        {
                             print("doubleupdate")
                             self.loadTableData()
                        }
                        if self.accounts.count < 2 {
                            self.AddTimeData["account"] = String(Record(resp.records[0]).id)
                            self.AddTimeData["org"] = Properties.org
                            self.pushController(withName: "ProjectList", context: self.AddTimeData)
                            }
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

    
    func loadTableData() {
        timeTable.setNumberOfRows(accounts.count, withRowType: "RecordTableRowController")
        for (index, account) in accounts.enumerated() {
            //print(blogName)
            let row = timeTable.rowController(at: index) as! RecordTableRowController
            let rec = Record(account)
            row.recordLabel.setText(rec.name)
        }
    }


    override func contextForSegue(withIdentifier segueIdentifier: String,
        in table: WKInterfaceTable, rowIndex: Int) -> Any? {
            let sequeId = "ToProject"
            let acc  = accounts as Array<NSDictionary>
            if segueIdentifier == sequeId {
                let rec = Record(acc[rowIndex])
                AddTimeData["account"] = String(rec.id)
                AddTimeData["org"] = Properties.org
                return AddTimeData
            }
            
            return nil
    }



    override init() {
        super.init()
        
        getOrg()
        updateWidget()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
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
 

