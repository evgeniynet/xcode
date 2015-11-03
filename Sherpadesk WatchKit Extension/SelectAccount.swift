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
import JSONJoy


class SelectAccountInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var timeTable: WKInterfaceTable!
    
    struct Record : JSONJoy {
        var id: Int
        var name: String
        var org: String
        //init() {
        //}
        
        init(_ decoder: JSONDecoder) {
            id = decoder["id"].integer!
            name = decoder["name"].string!.stringByReplacingOccurrencesOfString("\n", withString: " ").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            org = ""
        }
        init(_ array: AnyObject) {
            id = (array["id"] as? Int)!
            name = (array["name"] as? String)!
            org = (array["org"] as? String)!
        }
    }
    
    struct Records : JSONJoy {
        var records: NSMutableArray = []
        init() {
        }
        init(_ decoder: JSONDecoder) {
            //we check if the array is valid then alloc our array and loop through it, creating the new address objects.
            if let recrds = decoder.array {
                records = []
                if recrds.count < 1 {
                    records.addObject(["id" : -1, "name" : "Default", "org" : Properties.org])
                }
                for rDecoder in recrds {
                    let rec = Record(rDecoder)
                    records.addObject([ "id" : rec.id, "name" : rec.name, "org" : Properties.org])
                }
            }
        }
    }

    
    var defaults : NSUserDefaults = NSUserDefaults(suiteName: "group.io.sherpadesk.mobile")!
    
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
    
    var accounts: NSMutableArray = []
    
    func getOrg(){
        defaults.synchronize()
        if let org:String = defaults.objectForKey("org") as? String
        {
            Properties.org = org
        }
        else
        {
            Properties.org = ""
        }
        //print(Properties.org)
        if !Properties.org.isEmpty{
            if let accts:NSMutableArray = defaults.objectForKey("accounts") as? NSMutableArray
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
             self.pushControllerWithName("Main1", context: nil)
        }
        self.accounts = []
        defaults.setObject([], forKey: "accounts")
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
                    let resp = Records(JSONDecoder(response.data))
                    if resp.records.count > 0 {
                        let oldcount =  self.accounts.count
                        var oldorg = false;
                        if oldcount > 0 {
                            if let org = self.accounts[0]["org"] as? String
                            {
                                if (org != Properties.org){
                                    oldorg = true
                                }
                            }
                        }
                        self.accounts = resp.records
                        //print("sting during post: \(self.tickets.count)")
                        self.defaults.setObject(self.accounts, forKey: "accounts")
                        if oldcount !=  self.accounts.count || oldorg
                        {
                             print("doubleupdate")
                             self.loadTableData()
                        }
                    }
                }
            } catch let error {
                print("got an error creating the request: \(error)")
            }
        }
    }

    
    func loadTableData() {
        timeTable.setNumberOfRows(accounts.count, withRowType: "RecordTableRowController")
        for (index, account) in accounts.enumerate() {
            //print(blogName)
            let row = timeTable.rowControllerAtIndex(index) as! RecordTableRowController
            let rec = Record(account)
            row.recordLabel.setText(rec.name)
        }
    }
    
    override func contextForSegueWithIdentifier(segueIdentifier: String,
        inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
            let sequeId = "ToProject"
            let acc  = accounts as NSMutableArray
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
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
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