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


class SelectProjectInterfaceController: WKInterfaceController {
    
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
                    records.addObject(["id" : 0, "name" : "Default", "org" : Properties.org])
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
    
    var projects: NSMutableArray = []
    
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
            if let accts:NSMutableArray = defaults.objectForKey("projects") as? NSMutableArray
            {
                if accts.count>0 {
                    if let org = accts[0]["org"] as? String
                    {
                        //print("org\(org)prop\(Properties.org)")
                        if (org == Properties.org){
                            self.projects = accts
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
        self.projects = []
        defaults.setObject([], forKey: "projects")
        //print("unset\(self.tickets.count)")
        
    }
    
    func updateWidget()
    {
        if !Properties.org.isEmpty
        {
            loadTableData()
            
            do {
                let command = "projects"
                let params = ["account" : AddTimeData["account"]!]
                print(params)
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
                        self.projects = resp.records
                        //print("sting during post: \(self.tickets.count)")
                        self.loadTableData()
                        //print(resp.records)
                    }
                }
            } catch let error {
                print("got an error creating the request: \(error)")
            }
        }
    }

    func loadTableData() {
        timeTable.setNumberOfRows(projects.count, withRowType: "ProjectTableRowController")
        for (index, project) in projects.enumerate() {
            //print(blogName)
            let row = timeTable.rowControllerAtIndex(index) as! ProjectTableRowController
            let rec = Record(project)
            row.recordLabel.setText(rec.name)
        }
    }
    
    override func contextForSegueWithIdentifier(segueIdentifier: String,
        inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
            let sequeId = "ToTaskType"
            let prj  = projects as NSMutableArray
            if segueIdentifier == sequeId {
                let rec = Record(prj[rowIndex])
                AddTimeData["project"] = String(rec.id)
                return AddTimeData
            }
            
            return nil
    }
    
    override init() {
        super.init()
        getOrg()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        let dict = context as? [String : String]
        if dict != nil {
            AddTimeData = dict!
            print(AddTimeData["account"]!)
        }
        updateWidget()
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