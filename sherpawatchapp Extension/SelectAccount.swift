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

class Global {
    
    // Now Global.sharedGlobal is your singleton, no need to use nested or other classes
    static let sharedGlobal = Global()
    
    var testString: String="Test" //for debugging
    
    var acc: Array<Record> = []
    
}

// Use the singleton like this
let singleton = Global.sharedGlobal

public struct pass {
    var data: Dictionary<String, String>
    var acc: Record

    public init(_ data1: Dictionary<String, String>, _ acc1: Record) {
        data = data1
        acc = acc1
    }
}

public struct Record : JSONJoy {
    var id: Int
    var name: String
    var org: String
    var projects: Array<Record1> = []
    var task_types: Array<Record1> = []
    
    public init()
    {
       id = 0
       name = ""
       org = ""
    }
    
    public init(_ decoder: JSONLoader) throws {
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
    public init(_ array: NSDictionary) {
        id = (array["id"] as? Int)!
        name = (array["name"] as? String)!
        org = (array["org"] as? String) ?? ""
    }
}

public struct Record1 : JSONJoy {
    var id: Int
    var name: String
    
    public init()
    {
        id = 0
        name = ""
    }
    
    public init(_ decoder: JSONLoader) throws {
        id = try decoder["id"].get()
        name = try decoder["name"].get()
        name = name.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    public init(_ array: NSDictionary) {
        id = (array["id"] as? Int)!
        name = (array["name"] as? String)!
    }
}

class SelectAccountInterfaceController: WKInterfaceController, WCSessionDelegate {
    
        var session : WCSession?
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        NSLog("%@", "activationDidCompleteWith activationState:\(activationState) error:\(error)")
    }
    
    @IBOutlet weak var timeTable: WKInterfaceTable!
    
    public struct Records : JSONJoy {
        var records: Array<NSDictionary> = []
        public init() {
        }
        public init(_ decoder: JSONLoader) throws {
            records = []
            let arr: Array<Record> = try decoder.get()
            records = []
            let add_recent: Bool = Properties.AddTimeData["account"] != "" && arr.count>1 && arr[0].id != Int(Properties.AddTimeData["account_id"]!)
            for val in arr {
                let dictionary: NSDictionary = ["id" : val.id, "name" : val.name, "org" : Properties.org]
                
                if add_recent && Int(Properties.AddTimeData["account_id"]!) == val.id  {
                    records.insert(dictionary, at: 0);
                }
                else {
                    records.append(dictionary)
                }
            }
        }
    }
    
    func setRecent(){
        if accounts.count > 1 && Properties.AddTimeData["account"] != "" && accounts[0]["id"]  as! Int != Int(Properties.AddTimeData["account_id"]!) {
            for (index, val) in accounts.enumerated() {
                if Int(Properties.AddTimeData["account_id"]!) == val["id"] as! Int
                {
                    accounts.insert(accounts.remove(at: index), at: 0)
                }
            }
        }
    }
    
    func setRecentG(){
        if singleton.acc.count > 1 && Properties.AddTimeData["account"] != "" && singleton.acc[0].id != Int(Properties.AddTimeData["account_id"]!) {
            for (index, val) in singleton.acc.enumerated() {
                if Int(Properties.AddTimeData["account_id"]!) == val.id  {
                    singleton.acc.insert(singleton.acc.remove(at: index), at: 0);
                }
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
                                                              "isaccount": "true"]
    }
    
    var accounts: Array<NSDictionary> = []
    
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
        if let recent:NSDictionary = defaults.object(forKey: "recent") as? NSDictionary
        {
            Properties.AddTimeData = recent as! Dictionary<String, String>
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
                            setRecent()
                            return
                            //if 1=1
                            //    self.accounts_ready=true
                            //print("set\(self.tickets.count)")
                        }
                    }
                }
            }
        }
        else
        {//showMessage("Login to SherpaDesk app first")
            self.popToRootController()
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
                let urlPath: String = "https://" + Properties.org +
                    "@api.sherpadesk.com/" + command
                
                let opt = try HTTP.GET(urlPath, parameters: params, headers: ["Accept": "application/json"])
                opt.start { response in
                    if let err = response.error {
                        print("error: \(err.localizedDescription)")
                        return //also notify app of failure as needed
                    }
                    do {
                        
                        if oldcount == 0 {
                            print("done request")
                            self.getrequest("accounts?is_watch_info=true&is_with_statistics=false&limit=500")
                        }
                        else
                        {
                            self.getrequest_logic(response.data)
                        }
                        let resp = try Records(JSONLoader(response.data))
                        if resp.records.count > 0 {
                            
                            self.accounts = resp.records
                            //print("sting during post: \(self.tickets.count)")
                            self.defaults.set(self.accounts, forKey: "accounts")
                            //self.setRecent()
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
            let urlPath: String = "https://" + Properties.org +
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
            singleton.acc = try JSONLoader(data).get()
            
            if singleton.acc.count > 0 {
                self.accounts_ready = true
                print("done1: \(singleton.acc.count)")
                //self.defaults.set(self.acc, forKey: "accounts")
                if singleton.acc.count < 2 {
                    self.test(singleton.acc[0])
                }
                setRecentG()
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
            row.recordLabel.setText((Properties.AddTimeData["account"] != "" && index == 0 ? "✅ " : "") + (rec.name.isEmpty ? "Default" : rec.name))
        }
    }
    
    func test(_ rec: Record) -> Any?
    {
        Properties.AddTimeData["account"] = rec.name
        Properties.AddTimeData["account_id"] = String(rec.id)
        self.defaults.set(Properties.AddTimeData , forKey: "recent")
        Properties.AddTimeData["org"] = Properties.org
        if (accounts_ready){
            if rec.projects.count < 2 {
                Properties.AddTimeData["project"] = rec.projects.count == 1 ? rec.projects[0].name : ""
                Properties.AddTimeData["project_id"] = String( rec.projects.count == 1 ? rec.projects[0].id : 0)
                if rec.task_types.count < 2 {
                    Properties.AddTimeData["tasktype"] = rec.task_types.count == 1 ? rec.task_types[0].name : ""
                    Properties.AddTimeData["tasktype_id"] = String(rec.task_types.count == 1 ? rec.task_types[0].id : 0)
                    self.pushController(withName: "AddTime", context: pass(Properties.AddTimeData, rec))
                    return nil
                }
                self.pushController(withName: "TypesList", context: pass(Properties.AddTimeData, rec))
                return nil
            }
        }
        return pass(Properties.AddTimeData, rec)
    }
    
    
    override func contextForSegue(withIdentifier segueIdentifier: String,
                                  in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        let sequeId = "ToProject"
        let rec = accounts_ready ? singleton.acc[rowIndex] : Record(accounts[rowIndex])
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
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        if let iPhoneContext = session?.receivedApplicationContext as? [String : Any] {
            let message = iPhoneContext["message"] as? String
            //let old = defaults.object(forKey: "org") as? String
            defaults.set(message, forKey: "org")
            defaults.synchronize()
        }
        if singleton.acc.count > 0 {
            self.accounts_ready = true
            setRecentG()
            //print(singleton.acc.count)
        }
        getOrg()
        updateWidget()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}


