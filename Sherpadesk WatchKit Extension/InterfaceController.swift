//
//  InterfaceController.swift
//  Sherpadesk WatchKit Extension
//
//  Created by Евгений on 18.08.15.
//
//

import WatchKit
import Foundation
import SwiftHTTP
import JSONJoy


class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var timeTable: WKInterfaceTable!
    
    @IBOutlet weak var button: WKInterfaceButton!
    
    struct Record : JSONJoy {
        var id: Int
        var name: String
        var hours: Float
        var org: String
        //init() {
        //}
        
        init(_ decoder: JSONDecoder) {
            id = decoder["time_id"].integer!
            name = decoder["user_name"].string!.stringByReplacingOccurrencesOfString("\n", withString: " ").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) + "\n" + decoder["account_name"].string!.stringByReplacingOccurrencesOfString("\n", withString: " ").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            hours = decoder["hours"].float!
            org = ""
        }
        init(_ array: AnyObject) {
            id = (array["id"] as? Int)!
            name = (array["name"] as? String)!
            hours = (array["hours"] as? Float)!
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
                for rDecoder in recrds {
                    let rec = Record(rDecoder)
                    records.addObject([ "id" : rec.id, "name" : rec.name, "hours" : rec.hours, "org" : Properties.org])
                }
            }
        }
    }
    
    var defaults : NSUserDefaults = NSUserDefaults(suiteName: "group.io.sherpadesk.mobile")!
    
    struct Properties {
        static var org = ""
    }

    var timelogs: NSMutableArray = []
    
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
            button.setEnabled(true);
            if let timelgs:NSMutableArray = defaults.objectForKey("timelogs") as? NSMutableArray
            {
                if timelgs.count>0 {
                    if let org = timelgs[0]["org"] as? String
                    {
                        //print("org\(org)prop\(Properties.org)")
                        if (org == Properties.org){
                            self.timelogs = timelgs
                            print("set\(self.timelogs.count)")
                            return
                        }
                    }
                }
            }
            //showMessage("No recent tickets yet ...")
        }
        else
        {
            button.setEnabled(false);
            timeTable.setNumberOfRows(1, withRowType: "TextTableRowController")
            let row = timeTable.rowControllerAtIndex(0) as! TextTableRowController
            row.nameLabel.setText("Login to Sherpadesk")
        }
        self.timelogs = []
        defaults.setObject([], forKey: "timelogs")
        //print("unset\(self.tickets.count)")
        
    }
    
    func updateWidget()
    {
        if !Properties.org.isEmpty
        {
            loadTableData()
            
            do {
                let command = "time"
                let params = ["limit":"25"]
                let urlPath: String = "http://" + Properties.org +
                    "@api.beta.sherpadesk.com/" + command
                
                let opt = try HTTP.GET(urlPath, parameters: params, headers: ["Accept": "application/json"])
                opt.start { response in
                    if let err = response.error {
                        print("error: \(err.localizedDescription)")
                        return //also notify app of failure as needed
                    }
                    let resp = Records(JSONDecoder(response.data))
                    if resp.records.count > 0 {
                        self.timelogs = resp.records
                        //print("sting during post: \(self.tickets.count)")
                        self.defaults.setObject(self.timelogs, forKey: "timelogs")
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
        timeTable.setNumberOfRows(timelogs.count+1, withRowType: "TextTableRowController")
        for (index, timelgs) in timelogs.enumerate() {
            //print(blogName)
            let row = timeTable.rowControllerAtIndex(index) as! TextTableRowController
            let rec = Record(timelgs)
            row.nameLabel.setText(rec.name)
            row.hoursLabel.setText(String(format: "%2.2f", rec.hours))
        }
    }
    
    override init() {
        super.init()
        /*let z = [Int](1...40)
        
        var test = z.map({
            (number: Int) -> Float in
            let result =  Float(number) * Float(0.25)
            return result
        })
        
        print(test) */
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        /*if let text = context as? String {
            let indexSet = NSMutableIndexSet()
            indexSet.addIndex(0)
            
            timeTable.insertRowsAtIndexes(indexSet,
                withRowType: "TextTableRowController")
            let row = timeTable.rowControllerAtIndex(0) as! TextTableRowController
            row.nameLabel.setText("Jon Vickers\nbigWebApps")
            row.hoursLabel.setText(text)
        }
        */
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        getOrg()
        updateWidget()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
