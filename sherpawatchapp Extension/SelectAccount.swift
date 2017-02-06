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
    
    struct Record1 : JSONJoy {
        var id: Int
        var name: String
        
        init(_ decoder: JSONDecoder) throws {
            id = try decoder["id"].get()
            name = try decoder["name"].get()
            name = name.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        init(_ array: NSDictionary) {
            id = (array["id"] as? Int)!
            name = (array["name"] as? String)!
        }
    }
    
    struct Record : JSONJoy {
        var id: Int
        var name: String
        var org: String
        var projects: Array<Record1> = []
        var task_types: Array<Record1> = []
        
        init(_ decoder: JSONDecoder) throws {
            id = try decoder["id"].get()
            name = try decoder["name"].get()
            name = name.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            org = ""
            do {
                projects = try decoder["projects"].get()
            } catch {
            }
            do {
                task_types = try decoder["task_types"].get()
            } catch {
            }
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
    
    var acc : Array<Record> = []
    
    var accounts_ready: Bool = false
    
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
                            //if 1=1
                            //    self.accounts_ready=true
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
            
            let oldcount = self.accounts.count
            
            do {
                let command = "accounts" + "?is_with_statistics=false&limit=500" + (oldcount > 0 ? "&is_watch_info=true" : "" )
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
                        
                        if oldcount == 0 {
                            self.getrequest("accounts?is_watch_info=true&is_with_statistics=false&limit=500")
                        }
                        else
                        {
                            self.getrequest_logic(response.data)
                        }
                        let resp = try Records(JSONDecoder(response.data))
                        if resp.records.count > 0 {
                            
                            self.accounts = resp.records
                            //print("sting during post: \(self.tickets.count)")
                            self.defaults.set(self.accounts, forKey: "accounts")
                            if oldcount !=  self.accounts.count
                            {
                                print("doubleupdate")
                                self.loadTableData()
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
    
    func getrequest(_ command: String)
    {
        do {
            let params = ["", ""]
            let urlPath: String = "http://" + Properties.org +
                "@api.sherpadesk.com/" + command
            
            let opt = try HTTP.GET(urlPath, parameters: params, headers: ["Accept": "application/json"])
            opt.start { response in
                if let err = response.error {
                    print("error: \(err.localizedDescription)")
                    return //also notify app of failure as needed
                }
                self.getrequest_logic(response.data)
            }
        } catch let error {
            print("got an error creating the request: \(error)")
        }
    }
    
    func getrequest_logic (_ data: Any)
    {
        do {
            self.acc = try JSONDecoder(data).get()
            if self.acc.count > 0 {
                self.accounts_ready = true
                print("done: \(self.acc.count)")
                //self.defaults.set(self.accounts, forKey: "accounts")
                if self.acc.count < 2 {
                    self.test(self.acc[0])
                }
            }
        }
        catch {
            print("unable to parse the JSON")
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
    
    func test(_ rec: Record) -> Any?
    {
        AddTimeData["account"] = String(rec.id)
        AddTimeData["org"] = Properties.org
        if rec.projects.count < 2 {
            self.AddTimeData["project"] = String( rec.projects.count == 1 ? rec.projects[0].id : 0)
            if rec.task_types.count < 2 {
                self.AddTimeData["tasktype"] = String(rec.task_types.count == 1 ? rec.task_types[0].id : 0)
                self.pushController(withName: "AddTime", context: self.AddTimeData)
                return nil
            }
            self.pushController(withName: "TypesList", context: self.AddTimeData)
            return nil
        }
        return AddTimeData
    }
    
    
    override func contextForSegue(withIdentifier segueIdentifier: String,
                                  in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        let sequeId = "ToProject"
        let rec = accounts_ready ? acc[rowIndex] : Record(accounts[rowIndex])
        if segueIdentifier == sequeId {
            return test(rec)
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


