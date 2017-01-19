//
//  InterfaceController.swift
//  Sherpadesk WatchKit Extension
//
//  Created by Евгений on 18.08.15.
//
//

import WatchKit
import Foundation

class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var timeTable: WKInterfaceTable!
    
    @IBOutlet weak var button: WKInterfaceButton!
    
    @IBOutlet var Login: WKInterfaceButton!
    
    
    
    
    @IBAction func phoneBtnTapped() {
        let url = URL(string: "tel:")!
        WKExtension.shared().openSystemURL(url)
    }
    
    func displayDetailScene(_ index: Int) {
      pushController(withName: "AccountList",
            context: index)
    }
    
    struct Record : JSONJoy {
        var id: Int
        var name: String
        var hours: Float
        var org: String
        //init() {
        //}
        
        init(_ decoder: JSONDecoder) throws {
            id = try decoder["time_id"].get()
            name = try decoder["user_name"].get()
                /*.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) + "\n" + try decoder["account_name"].get().replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)*/
            hours = try decoder["hours"].get()
            org = ""
        }
        init(_ array: AnyObject) {
            id = 1
            name = ""
            hours = 0
            org = ""
            if let userDict = array as? NSDictionary {
            id = (userDict["id"] as? Int)!
            name = (userDict["name"] as? String)!
            hours = (userDict["hours"] as? Float)!
            org = (userDict["org"] as? String)!
            }
        }
    }

    
    struct Records : JSONJoy {
        var records: NSMutableArray = []
        init() {
        }
        init(_ decoder: JSONDecoder) throws {
            //we check if the array is valid then alloc our array and loop through it, creating the new address objects.
            records = []
            /*
                var recrds: NSMutableArray
                recrds = try decoder.get()
                records = []
                for rDecoder in recrds {
                    let rec = Record(rDecoder)
                    records.add([ "id" : rec.id, "name" : rec.name, "hours" : rec.hours, "org" : Properties.org])
                }
 */
        }
    }
    
    var defaults : UserDefaults = UserDefaults(suiteName: "group.io.sherpadesk.mobile")!
    
    struct Properties {
        static var org = ""
    }

    var timelogs: NSMutableArray = []
    
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
        //defaults.setObject(Properties.org, forKey: "org")
        //print(Properties.org)
        if !Properties.org.isEmpty{
            button.setEnabled(true);
            
            if let timelgs:NSMutableArray = defaults.object(forKey: "timelogs") as? NSMutableArray
            {
                if timelgs.count>0 {
                    if let org = timelgs.object(at: 0) as? NSDictionary {
                        if let torg = org.object(forKey: "org") as? String
                    {
                        //print("org\(org)prop\(Properties.org)")
                        if (torg == Properties.org){
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
            let row = timeTable.rowController(at: 0) as! TextTableRowController
            row.nameLabel.setText("Login to SherpaDesk")
        }
        self.timelogs = []
        defaults.set([], forKey: "timelogs")
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
                    "@api.sherpadesk.com/" + command
                
                let opt = try HTTP.GET(urlPath, parameters: params, headers: ["Accept": "application/json"])
                opt.start { response in
                    if let err = response.error {
                        print("error: \(err.localizedDescription)")
                        return //also notify app of failure as needed
                    }
                    /*
                    let resp = Records(JSONDecoder(response.data as AnyObject))
                    if resp.records.count > 0 {
                        self.timelogs = resp.records
                        //print("sting during post: \(self.tickets.count)")
                        self.defaults.set(self.timelogs, forKey: "timelogs")
                        loadTableData()
                        //print(resp.records)
                    }
 */
                }
            } catch let error {
                print("got an error creating the request: \(error)")
            }
        }
    }
    
    func loadTableData() {
        timeTable.setNumberOfRows(timelogs.count+1, withRowType: "TextTableRowController")
        for (index, timelgs) in timelogs.enumerated() {
            //print(blogName)
            let row = timeTable.rowController(at: index) as! TextTableRowController
            let rec = Record(timelgs as AnyObject)
            row.nameLabel.setText(rec.name)
            row.hoursLabel.setText(String(format: "%2.2f", rec.hours))
        }
    }
}
    
        override func awake(withContext context: Any?) {
            super.awake(withContext: context)
            
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
            //updateWidget()
        }
        
        override func didDeactivate() {
            // This method is called when watch view controller is no longer visible
            super.didDeactivate()
        }
    }

    
    /*init() {
        //super.init()
        /*let z = [Int](1...40)
        
        var test = z.map({
            (number: Int) -> Float in
            let result =  Float(number) * Float(0.25)
            return result
        })
        
        print(test) */
    }*/

   


