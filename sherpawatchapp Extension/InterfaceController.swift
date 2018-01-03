//
//  InterfaceController.swift
//  Sherpadesk WatchKit Extension
//
//  Created by Евгений on 18.08.15.
//
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    var session : WCSession?
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        NSLog("%@", "activationDidCompleteWith activationState:\(activationState) error:\(error)")
    }
    
    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any],
                 replyHandler: @escaping ([String : Any]) -> Void) {
        let message = message["message"] as? String
        defaults.set(message, forKey: "org")
        //defaults.object(forKey: "org") as? String
        print(message)
    }
    
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
        
        init(_ decoder: JSONDecoder) throws {
            id = try decoder["time_id"].get()
            name = try decoder["user_name"].get()
            let acc: String = try decoder["account_name"].get()
            name = name.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) + "\n" + acc.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            hours = try decoder["hours"].get()
            org = ""
        }
        init(_ array: NSDictionary) {
            id = (array["id"] as? Int)!
            name = (array["name"] as? String)!
            hours = (array["hours"] as? Float)!
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
                let dictionary: NSDictionary = ["id" : val.id, "name" : val.name, "hours" : val.hours, "org" : Properties.org]
                records.append(dictionary)
            }
        }
    }
    
    var defaults : UserDefaults = UserDefaults(suiteName: "group.io.sherpadesk.mobile")!
    
    struct Properties {
        static var org = ""
    }
    
    var timelogs: Array<NSDictionary> = []
    
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
        if !Properties.org.isEmpty{
            button.setEnabled(true);
            
            if let timelgs:Array<NSDictionary> = defaults.object(forKey: "timelogs") as? Array<NSDictionary>
            {
                if timelgs.count>0 {
                    let org = timelgs[0]
                    if let torg = org.object(forKey: "org") as? String
                    {
                        //print("org\(org)prop\(Properties.org)")
                        if (torg == Properties.org){
                            self.timelogs = timelgs
                            //print("set\(self.timelogs.count)")
                            return
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
    }
    
    func updateWidget()
    {
        if !Properties.org.isEmpty
        {
            loadTableData()
            
            do {
                let command = "time"
                let params = ["limit":"25"]
                let urlPath: String = "https://" + Properties.org +
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
                            self.timelogs = resp.records
                            self.defaults.set(resp.records, forKey: "timelogs")
                            self.loadTableData()
                            //print(resp.records)
                        }
                    } catch {
                        print("unable to parse the JSON")
                    }
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
            let rec = Record(timelgs)
            row.nameLabel.setText(rec.name)
            row.hoursLabel.setText(String(format: "%2.2f", rec.hours))
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
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        session = WCSession.default()
        session?.delegate = self
        session?.activate()
        getOrg()
        updateWidget()
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




